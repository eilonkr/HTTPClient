A simple Swift HTTP client using URLSession and Swift Concurrency, with logging.

## Server-sent events

On iOS 15+ and macOS 12+, use `postEvents` for JSON POST requests that return SSE:

```swift
let configuration = URLSessionConfiguration.default
configuration.timeoutIntervalForResource = 660
let session = URLSession(configuration: configuration)

try await session.postEvents(
    "https://example.com/messages/stream",
    body: request,
    headers: ["Authorization": "Bearer \(token)"],
    timeoutInterval: 90
) { event in
    if event.name == "done" { return .stop }
    await handle(event)
    return .continueStreaming
}
```

For GET or custom requests, use `session.serverSentEvents(for: request, onEvent: ...)`.
Both methods use the receiving session, preserving its configuration, delegate, cookies,
and URLProtocol support. Set the session's resource timeout to bound the entire connection;
`postEvents(timeoutInterval:)` sets the request inactivity timeout.

Each `ServerSentEvent` exposes `name`, UTF-8 `data`, `id`, and `retryMilliseconds`.
The parser handles LF, CRLF, CR, an initial UTF-8 BOM, multiline data, comments,
empty data, and IDs. It enforces a configurable 512 KiB event limit and throws on
malformed UTF-8. Unterminated events at EOF are discarded.

Callbacks are awaited in order, without an unbounded intermediate event queue.
Return `.stop` to end observation, or throw to propagate a consumer failure. Both
close the connection. Task cancellation also closes it. The methods do not log
request bodies, authorization headers, or event payloads.

HTTP failures use the existing `NSError(domain: "", code: statusCode)` convention.
Successful responses must have `Content-Type: text/event-stream`. EOF returns normally;
applications that require a terminal event should track it and treat missing termination
as an interrupted operation. Event names and JSON payloads are application-owned.

There is no automatic reconnection, retry, or POST replay. IDs and retry metadata are
exposed for callers that implement a server-supported recovery protocol.

Run `swift test` for parser and URLSession transport coverage.
