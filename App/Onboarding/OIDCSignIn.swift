import AuthenticationServices
import MealplannerKit
import SwiftUI

/// Runs the authorization code flow with PKCE against the provider of a server.
@MainActor
struct OIDCSignIn {
    let provider: OIDCConfiguration

    /// Lets the user sign in at the provider in `browser` and returns the resulting ID token.
    ///
    /// Throws `CancellationError` when the user closes the browser.
    func idToken(using browser: WebAuthenticationSession) async throws -> String {
        let client = OIDCClient(issuer: provider.issuer)
        let metadata = try await client.metadata()
        let request = OIDCAuthorizationRequest(clientID: provider.clientID)
        let callbackURL = try await authorize(at: request.authorizationURL(metadata: metadata), using: browser)
        let code = try request.authorizationCode(from: callbackURL)
        return try await client.idToken(code: code, request: request, metadata: metadata)
    }

    private func authorize(at url: URL, using browser: WebAuthenticationSession) async throws -> URL {
        do {
            return try await browser.authenticate(
                using: url,
                callback: .customScheme(AppConfiguration.oidcCallbackScheme),
                additionalHeaderFields: [:]
            )
        } catch let error as ASWebAuthenticationSessionError where error.code == .canceledLogin {
            throw CancellationError()
        } catch {
            throw OIDCError.authorizationFailed(description: nil)
        }
    }
}
