import Foundation
import Testing
@testable import HTTPClient

@Suite(.serialized)
@MainActor
struct StreamingTransportTests {
    private struct Body: Encodable { let messageText: String }
    private enum CallbackFailure: Error { case rejected }

    private func session(_ fixture: EventURLProtocol.Fixture) -> URLSession {
        EventURLProtocol.fixture = fixture
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [EventURLProtocol.self]
        configuration.timeoutIntervalForResource = 3
        return URLSession(configuration: configuration)
    }

    @Test func postsJSONUsingCallerSessionAndHeaders() async throws {
        let fixture = EventURLProtocol.Fixture(wire: "event: reply\ndata: hello 🌍\n\nevent: done\ndata: {}\n\n")
        let session = session(fixture)
        defer { session.invalidateAndCancel() }
        var events = [ServerSentEvent]()
        try await session.postEvents("https://test.invalid/messages", body: Body(messageText: "hi"), headers: ["Authorization": "Bearer test"], queryParams: ["page": "1"], keyEncodingStrategy: .convertToSnakeCase, timeoutInterval: 12) { event in
            events.append(event)
            return .continueStreaming
        }
        #expect(events.map(\.name) == ["reply", "done"])
        let request = try #require(fixture.recordedRequests.first)
        #expect(fixture.recordedRequests.count == 1)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.query == "page=1")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test")
        #expect(request.value(forHTTPHeaderField: "Accept") == "text/event-stream")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.timeoutInterval == 12)
        var bodyData = request.httpBody ?? Data()
        if let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var buffer = [UInt8](repeating: 0, count: 1024)
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                if count <= 0 { break }
                bodyData.append(contentsOf: buffer.prefix(count))
            }
        }
        #expect(try JSONSerialization.jsonObject(with: bodyData) as? [String: String] == ["message_text": "hi"])
    }

    @Test func stopsWithoutWaitingForEOFOrReplaying() async throws {
        let fixture = EventURLProtocol.Fixture(wire: "data: first\n\ndata: second\n\n", finishes: false)
        let session = session(fixture)
        defer { session.invalidateAndCancel() }
        var count = 0
        try await session.serverSentEvents(for: URLRequest(url: URL(string: "https://test.invalid/events")!)) { _ in
            count += 1
            return .stop
        }
        try await Task.sleep(for: .milliseconds(50))
        #expect(count == 1)
        #expect(fixture.recordedRequests.count == 1)
        #expect(fixture.stopCount == 1)
    }

    @Test func preservesHTTPErrorConvention() async throws {
        let fixture = EventURLProtocol.Fixture(status: 401, contentType: "application/json", wire: "{}")
        let session = session(fixture)
        defer { session.invalidateAndCancel() }
        do {
            try await session.postEvents("https://test.invalid/events", body: Body(messageText: "hi")) { _ in
                Issue.record("HTTP error must not dispatch events")
                return .stop
            }
            Issue.record("Expected HTTP error")
        } catch {
            #expect((error as NSError).domain == "")
            #expect((error as NSError).code == 401)
        }
        #expect(fixture.recordedRequests.count == 1)
    }

    @Test func rejectsUnexpectedContentType() async throws {
        let fixture = EventURLProtocol.Fixture(contentType: "application/json", wire: "{}")
        let session = session(fixture)
        defer { session.invalidateAndCancel() }
        await #expect(throws: URLError.self) {
            try await session.serverSentEvents(for: URLRequest(url: URL(string: "https://test.invalid/events")!)) { _ in .continueStreaming }
        }
    }

    @Test func callbackFailurePropagatesAndClosesConnection() async throws {
        let fixture = EventURLProtocol.Fixture(wire: "data: first\n\n", finishes: false)
        let session = session(fixture)
        defer { session.invalidateAndCancel() }
        await #expect(throws: CallbackFailure.self) {
            try await session.serverSentEvents(for: URLRequest(url: URL(string: "https://test.invalid/events")!)) { _ in throw CallbackFailure.rejected }
        }
        try await Task.sleep(for: .milliseconds(50))
        #expect(fixture.stopCount == 1)
    }

    @Test func cancellationClosesConnectionWithoutReplay() async throws {
        let fixture = EventURLProtocol.Fixture(wire: "data: first\n\n", finishes: false)
        let session = session(fixture)
        defer { session.invalidateAndCancel() }
        var receivedEvent = false
        let task = Task {
            try await session.serverSentEvents(for: URLRequest(url: URL(string: "https://test.invalid/events")!)) { _ in
                receivedEvent = true
                return .continueStreaming
            }
        }
        for _ in 0..<100 where !receivedEvent { try await Task.sleep(for: .milliseconds(10)) }
        #expect(receivedEvent)
        task.cancel()
        do {
            try await task.value
            Issue.record("Expected cancellation")
        } catch {
            #expect(error is CancellationError || (error as? URLError)?.code == .cancelled)
        }
        #expect(fixture.recordedRequests.count == 1)
    }
}
