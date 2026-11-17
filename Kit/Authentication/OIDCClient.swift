import Foundation

/// Talks to the OpenID Connect provider of a server.
public struct OIDCClient: Sendable {
    private struct TokenResponse: Decodable {
        let idToken: String
    }

    private static let discoveryPath = ".well-known/openid-configuration"

    private let issuer: URL
    private let session: URLSession

    public init(issuer: URL, session: URLSession = .shared) {
        self.issuer = issuer
        self.session = session
    }

    /// Loads the discovery document of the provider.
    public func metadata() async throws -> OIDCProviderMetadata {
        let request = URLRequest(url: issuer.appending(path: Self.discoveryPath))
        return try await load(request, failure: .providerUnreachable)
    }

    /// Exchanges the authorization code of `request` for an ID token.
    public func idToken(code: String, request: OIDCAuthorizationRequest, metadata: OIDCProviderMetadata) async throws -> String {
        let tokenRequest = request.tokenRequest(code: code, metadata: metadata)
        let response: TokenResponse = try await load(tokenRequest, failure: .tokenExchangeFailed)
        return response.idToken
    }

    private func load<Value: Decodable>(_ request: URLRequest, failure: OIDCError) async throws -> Value {
        do {
            let (data, response) = try await session.data(for: request)
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                throw failure
            }
            return try JSONCoding.makeDecoder().decode(Value.self, from: data)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw failure
        }
    }
}
