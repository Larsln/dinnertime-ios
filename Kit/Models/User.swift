/// A member of the household.
public struct User: Decodable, Hashable, Sendable {
    public let id: Int
    public let username: String
    public let name: String
    public let email: String?
}

/// Answer to a successful sign-in.
public struct SignInResult: Decodable, Sendable {
    /// API token for the device.
    public let token: String
    /// The user who signed in.
    public let user: User
}
