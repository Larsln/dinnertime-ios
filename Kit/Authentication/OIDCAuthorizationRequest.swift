import Foundation

/// The endpoints of a provider, read from its discovery document.
public struct OIDCProviderMetadata: Decodable, Equatable, Sendable {
    public let authorizationEndpoint: URL
    public let tokenEndpoint: URL
}

/// One attempt to sign in with the authorization code flow and PKCE.
public struct OIDCAuthorizationRequest: Sendable {
    private static let scope = "openid profile email"
    private static let randomByteCount = 16

    let clientID: String
    let redirectURI: String
    let state: String
    let nonce: String
    let pkce: PKCE

    /// Creates a request with fresh random state, nonce and proof key.
    public init(clientID: String, redirectURI: String = AppConfiguration.oidcRedirectURI) {
        self.init(
            clientID: clientID,
            redirectURI: redirectURI,
            state: RandomToken.make(byteCount: Self.randomByteCount),
            nonce: RandomToken.make(byteCount: Self.randomByteCount),
            pkce: PKCE()
        )
    }

    init(clientID: String, redirectURI: String, state: String, nonce: String, pkce: PKCE) {
        self.clientID = clientID
        self.redirectURI = redirectURI
        self.state = state
        self.nonce = nonce
        self.pkce = pkce
    }

    /// Address of the sign-in page to open in the browser.
    public func authorizationURL(metadata: OIDCProviderMetadata) -> URL {
        metadata.authorizationEndpoint.appending(queryItems: [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: Self.scope),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "nonce", value: nonce),
            URLQueryItem(name: "code_challenge", value: pkce.challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
        ])
    }

    /// Reads the authorization code from the redirect and checks that it answers this request.
    public func authorizationCode(from callbackURL: URL) throws -> String {
        let items = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let values = Dictionary(items.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { first, _ in first })
        if let error = values["error"] {
            throw OIDCError.authorizationFailed(description: values["error_description"] ?? error)
        }
        guard values["state"] == state, let code = values["code"], !code.isEmpty else {
            throw OIDCError.authorizationFailed(description: nil)
        }
        return code
    }

    /// Request that exchanges the authorization code for tokens.
    func tokenRequest(code: String, metadata: OIDCProviderMetadata) -> URLRequest {
        let form = [
            ("grant_type", "authorization_code"),
            ("code", code),
            ("redirect_uri", redirectURI),
            ("client_id", clientID),
            ("code_verifier", pkce.verifier),
        ]
        var request = URLRequest(url: metadata.tokenEndpoint)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = Data(form.map { "\($0)=\(Self.formEncoded($1))" }.joined(separator: "&").utf8)
        return request
    }

    private static func formEncoded(_ value: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }
}
