import Foundation

/// Where the stream of change events is served and the token that opens it.
public struct RealtimeConnection: Decodable, Equatable, Sendable {
    private static let timeout: TimeInterval = 120

    /// Address of the stream as the server sees itself.
    public let url: URL
    /// Bearer token for the stream, valid for twelve hours.
    public let token: String

    /// The request that opens the stream.
    ///
    /// The stream is served by the web server itself, which may know its own address under
    /// another name than the device does; the request therefore goes to the origin of
    /// `serverURL` and only takes path and query from ``url``.
    public func request(serverURL: URL) -> URLRequest {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true) ?? URLComponents()
        let server = URLComponents(url: serverURL, resolvingAgainstBaseURL: true)
        components.scheme = server?.scheme
        components.host = server?.host
        components.port = server?.port
        var request = URLRequest(url: components.url ?? url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.timeoutInterval = Self.timeout
        return request
    }
}

/// How long to wait before the stream is opened again after a failure.
public enum ReconnectBackoff {
    private static let maximum = 30.0

    /// Seconds to wait before attempt number `attempt`, counted from one: 1, 2, 4 and so on up to half a minute.
    public static func delay(beforeAttempt attempt: Int) -> Double {
        min(pow(2, Double(max(attempt, 1) - 1)), maximum)
    }
}
