import Foundation

/// What is needed to act as the signed-in user: the server and its API token.
public struct Credentials: Codable, Equatable, Sendable {
    public let serverURL: URL
    public let token: String

    public init(serverURL: URL, token: String) {
        self.serverURL = serverURL
        self.token = token
    }
}
