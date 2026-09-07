import Foundation
import Testing
@testable import HTTPClient

struct ServerSentEventTests {
    private func parse(_ wire: String, limit: Int = 524_288) throws -> [ServerSentEvent] {
        var parser = ServerSentEvent.Parser(maximumBytes: limit)
        return try wire.utf8.compactMap { try parser.append($0) }
    }

    @Test func fragmentedUnicodeAndMultilineData() throws {
        let frames = try parse("\u{FEFF}: heartbeat\r\nid: 7\r\nevent: reply\r\ndata: Hi 👩🏽‍💻\r\ndata: שלום\r\n\r\n")
        #expect(frames == [ServerSentEvent(name: "reply", data: Data("Hi 👩🏽‍💻\nשלום".utf8), id: "7")])
    }

    @Test func lineEndingsAndEmptyEvents() throws {
        let frames = try parse("data: first\r\revent:\ndata:\n\ndata: third\r\n\r\n")
        #expect(frames.map(\.name) == ["message", "message", "message"])
        #expect(frames.map { String(decoding: $0.data, as: UTF8.self) } == ["first", "", "third"])
    }

    @Test func incompleteEventIsNotDispatched() throws {
        #expect(try parse("event: done\ndata: unfinished\n").isEmpty)
        #expect(try parse(": heartbeat\n\nunknown: value\n\n").isEmpty)
    }

    @Test func identifiersAndRetry() throws {
        let frames = try parse("id: 12\nretry: 1000\ndata: a\n\nid: ignored\0id\nretry: -1\ndata: b\n\nid:\ndata: c\n\n")
        #expect(frames.map(\.id) == ["12", "12", ""])
        #expect(frames.map(\.retryMilliseconds) == [1000, 1000, 1000])
    }

    @Test func boundsLinesAndCumulativeFields() throws {
        #expect(throws: URLError.self) { try parse("data: " + String(repeating: "x", count: 40), limit: 20) }
        #expect(throws: URLError.self) { try parse("data: 123456\ndata: 123456\n\n", limit: 20) }
        #expect(throws: URLError.self) { try parse("event: long-name\ndata: abcdef\n\n", limit: 20) }
    }

    @Test func invalidUTF8Fails() throws {
        var parser = ServerSentEvent.Parser()
        _ = try parser.append(255)
        #expect(throws: URLError.self) { try parser.append(10) }
    }
}
