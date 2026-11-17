import Foundation

/// Public description of a server, answered by `GET /server`.
public struct ServerInfo: Decodable, Hashable, Sendable {
    /// Name the household gave its server.
    public let name: String
    /// Language the household writes recipes in.
    public let contentLocale: String
    /// Languages the server can answer in.
    public let supportedLocales: [String]
    /// Offered sign-in methods: `password` and optionally `oidc`.
    public let authMethods: [String]
    /// Provider for single sign-on, if one is configured.
    public let oidc: OIDCConfiguration?

    /// Provider to offer for single sign-on, if the server supports it.
    public var oidcProvider: OIDCConfiguration? {
        authMethods.contains("oidc") ? oidc : nil
    }
}

/// OpenID Connect provider of a server.
public struct OIDCConfiguration: Decodable, Hashable, Sendable {
    /// Issuer URL, below which the discovery document lives.
    public let issuer: URL
    /// Client identifier registered at the provider.
    public let clientID: String

    private enum CodingKeys: String, CodingKey {
        case issuer
        case clientID = "clientId"
    }
}
