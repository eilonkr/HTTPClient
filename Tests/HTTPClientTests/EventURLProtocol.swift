import Foundation

final class EventURLProtocol: URLProtocol, @unchecked Sendable {
    final class Fixture: @unchecked Sendable {
        let status: Int
        let contentType: String
        let wire: String
        let finishes: Bool
        private let lock = NSLock()
        private var requests = [URLRequest]()
        private var stops = 0

        init(status: Int = 200, contentType: String = "text/event-stream; charset=utf-8", wire: String, finishes: Bool = true) {
            self.status = status
            self.contentType = contentType
            self.wire = wire
            self.finishes = finishes
        }

        func record(_ request: URLRequest) { lock.withLock { requests.append(request) } }
        func stop() { lock.withLock { stops += 1 } }
        var recordedRequests: [URLRequest] { lock.withLock { requests } }
        var stopCount: Int { lock.withLock { stops } }
    }

    nonisolated(unsafe) static var fixture: Fixture!
    private var activeFixture: Fixture?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let fixture = Self.fixture!
        activeFixture = fixture
        fixture.record(request)
        let response = HTTPURLResponse(url: request.url!, statusCode: fixture.status, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": fixture.contentType])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        for byte in fixture.wire.utf8 {
            client?.urlProtocol(self, didLoad: Data([byte]))
        }
        if fixture.finishes { client?.urlProtocolDidFinishLoading(self) }
    }

    override func stopLoading() { activeFixture?.stop() }
}
