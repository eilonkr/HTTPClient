import Foundation

public struct ServerSentEvent: Sendable, Equatable {
    public let name: String
    public let data: Data

    public let id: String?
    public let retryMilliseconds: Int?

    public enum Action: Sendable {
        case continueStreaming
        case stop
    }

    public init(name: String = "message", data: Data, id: String? = nil, retryMilliseconds: Int? = nil) {
        self.name = name
        self.data = data
        self.id = id
        self.retryMilliseconds = retryMilliseconds
    }

    public struct Parser: Sendable {
        private var line = [UInt8]()
        private var name = "message"
        private var dataLines = [String]()
        private var eventBytes = 0
        private var previousWasCarriageReturn = false
        private var isFirstLine = true
        private let maximumBytes: Int
        private var lastEventId: String?
        private var retryMilliseconds: Int?

        public init(maximumBytes: Int = 524_288) {
            self.maximumBytes = max(1, maximumBytes)
        }

        public mutating func append(_ byte: UInt8) throws -> ServerSentEvent? {
            if byte == 10, previousWasCarriageReturn {
                previousWasCarriageReturn = false
                return nil
            }
            previousWasCarriageReturn = byte == 13
            guard byte == 10 || byte == 13 else {
                guard line.count + eventBytes < maximumBytes else {
                    throw URLError(.dataLengthExceedsMaximum)
                }
                line.append(byte)
                return nil
            }
            guard var value = String(bytes: line, encoding: .utf8) else {
                throw URLError(.cannotDecodeContentData)
            }
            line.removeAll(keepingCapacity: true)
            if isFirstLine {
                isFirstLine = false
                if value.first == "\u{FEFF}" { value.removeFirst() }
            }
            if value.isEmpty {
                defer {
                    name = "message"
                    dataLines.removeAll(keepingCapacity: true)
                    eventBytes = 0
                }
                guard !dataLines.isEmpty else { return nil }
                return ServerSentEvent(name: name.isEmpty ? "message" : name, data: Data(dataLines.joined(separator: "\n").utf8), id: lastEventId, retryMilliseconds: retryMilliseconds)
            }
            if value.hasPrefix(":") { return nil }
            let parts = value.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            var fieldValue = parts.count > 1 ? String(parts[1]) : ""
            if fieldValue.first == " " { fieldValue.removeFirst() }
            eventBytes += value.utf8.count + 1
            guard eventBytes <= maximumBytes else { throw URLError(.dataLengthExceedsMaximum) }
            switch parts[0] {
            case "event": name = fieldValue
            case "data":
                dataLines.append(fieldValue)
            case "id":
                if !fieldValue.contains("\0") { lastEventId = fieldValue }
            case "retry":
                if !fieldValue.isEmpty, fieldValue.utf8.allSatisfy({ (48...57).contains($0) }) {
                    if let retry = Int(fieldValue) { retryMilliseconds = retry }
                }
            default: break
            }
            return nil
        }
    }
}
