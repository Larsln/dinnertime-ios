import Foundation
import Testing
@testable import DinnertimeKit

/// Authorization code flow with PKCE.
struct OIDCTests {
    private let metadata = OIDCProviderMetadata(
        authorizationEndpoint: URL(string: "https://id.example.org/authorize")!,
        tokenEndpoint: URL(string: "https://id.example.org/token")!
    )

    private let request = OIDCAuthorizationRequest(
        clientID: "dinnertime",
        redirectURI: "dinnertime://oidc",
        state: "state-1",
        nonce: "nonce-1",
        pkce: PKCE(verifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
    )

    @Test func challengeMatchesTheRFCExample() {
        #expect(request.pkce.challenge == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
    }

    @Test func verifiersAreRandomAndURLSafe() {
        let first = PKCE()
        let second = PKCE()

        #expect(first != second)
        #expect(first.verifier.count == 43)
        #expect(first.verifier.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_") })
    }

    @Test func authorizationURLCarriesTheFlowParameters() throws {
        let url = request.authorizationURL(metadata: metadata)
        let items = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        let values = Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value) })

        #expect(url.host() == "id.example.org")
        #expect(values["response_type"] == "code")
        #expect(values["client_id"] == "dinnertime")
        #expect(values["redirect_uri"] == "dinnertime://oidc")
        #expect(values["scope"] == "openid profile email")
        #expect(values["state"] == "state-1")
        #expect(values["nonce"] == "nonce-1")
        #expect(values["code_challenge"] == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
        #expect(values["code_challenge_method"] == "S256")
    }

    @Test func readsTheCodeFromTheRedirect() throws {
        let callback = try #require(URL(string: "dinnertime://oidc?code=abc&state=state-1"))

        #expect(try request.authorizationCode(from: callback) == "abc")
    }

    @Test func rejectsRedirectsOfOtherRequests() throws {
        let callback = try #require(URL(string: "dinnertime://oidc?code=abc&state=other"))

        #expect(throws: OIDCError.authorizationFailed(description: nil)) {
            try request.authorizationCode(from: callback)
        }
    }

    @Test func reportsProviderErrors() throws {
        let callback = try #require(URL(string: "dinnertime://oidc?error=access_denied&error_description=Denied&state=state-1"))

        #expect(throws: OIDCError.authorizationFailed(description: "Denied")) {
            try request.authorizationCode(from: callback)
        }
    }

    @Test func tokenRequestSendsTheVerifier() throws {
        let tokenRequest = request.tokenRequest(code: "a+b/c", metadata: metadata)
        let body = try #require(tokenRequest.httpBody.flatMap { String(data: $0, encoding: .utf8) })

        #expect(tokenRequest.httpMethod == "POST")
        #expect(tokenRequest.url == metadata.tokenEndpoint)
        #expect(tokenRequest.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
        #expect(body.contains("grant_type=authorization_code"))
        #expect(body.contains("code=a%2Bb%2Fc"))
        #expect(body.contains("redirect_uri=dinnertime%3A%2F%2Foidc"))
        #expect(body.contains("client_id=dinnertime"))
        #expect(body.contains("code_verifier=dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"))
    }

    @Test func decodesTheDiscoveryDocument() throws {
        let json = #"{"issuer":"https://id.example.org","authorization_endpoint":"https://id.example.org/authorize","token_endpoint":"https://id.example.org/token","jwks_uri":"https://id.example.org/jwks"}"#

        #expect(try JSONCoding.makeDecoder().decode(OIDCProviderMetadata.self, from: Data(json.utf8)) == metadata)
    }
}
