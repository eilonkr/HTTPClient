import Foundation

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public extension URLSession {
    func serverSentEvents(
        for request: URLRequest,
        maximumEventBytes: Int = 524_288,
        isolation: isolated (any Actor)? = #isolation,
        onEvent: (ServerSentEvent) async throws -> ServerSentEvent.Action
    ) async throws {
        try Task.checkCancellation()
        var request = request
        if request.value(forHTTPHeaderField: "Accept") == nil {
            request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        }
        let (bytes, response) = try await bytes(for: request)
        defer { bytes.task.cancel() }
        guard let response = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(response.statusCode) else {
            throw NSError(domain: "", code: response.statusCode, userInfo: [
                NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
            ])
        }
        guard response.mimeType?.lowercased() == "text/event-stream" else {
            throw URLError(.cannotParseResponse)
        }
        var parser = ServerSentEvent.Parser(maximumBytes: maximumEventBytes)
        for try await byte in bytes {
            try Task.checkCancellation()
            guard let event = try parser.append(byte) else { continue }
            if try await onEvent(event) == .stop { return }
        }
        try Task.checkCancellation()
    }

    func postEvents<Body: Encodable>(
        _ urlString: String,
        body: Body,
        headers: Headers = [:],
        queryParams: QueryParams? = nil,
        keyEncodingStrategy: KeyEncodingStrategy = .useDefaultKeys,
        timeoutInterval: TimeInterval = 60,
        maximumEventBytes: Int = 524_288,
        isolation: isolated (any Actor)? = #isolation,
        onEvent: (ServerSentEvent) async throws -> ServerSentEvent.Action
    ) async throws {
        let url = try urlString.buildURL(queryParams: queryParams)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = keyEncodingStrategy
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try encoder.encode(body)
        request.set(headers: headers)
        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        request.timeoutInterval = timeoutInterval
        try await serverSentEvents(
            for: request,
            maximumEventBytes: maximumEventBytes,
            isolation: isolation,
            onEvent: onEvent
        )
    }
}
