import AuthenticationServices
import DinnertimeKit
import Observation
import SwiftUI

/// Signs in to a server with a local account or its provider.
@MainActor
@Observable
final class SignInModel: ErrorReporting {
    var username = ""
    var password = ""
    var errorMessage: String?
    private(set) var isSigningIn = false

    let connection: ServerConnection
    private let session: AppSession

    init(session: AppSession, connection: ServerConnection) {
        self.session = session
        self.connection = connection
    }

    /// Whether the form is complete.
    var canSignIn: Bool {
        !username.isEmpty && !password.isEmpty && !isSigningIn
    }

    /// Signs in with the entered username and password.
    func signIn() async {
        await perform {
            try await session.signIn(username: username, password: password)
        }
    }

    /// Signs in at `provider` in `browser` and exchanges the ID token at the server.
    func signIn(at provider: OIDCConfiguration, using browser: WebAuthenticationSession) async {
        await perform {
            let idToken = try await OIDCSignIn(provider: provider).idToken(using: browser)
            try await session.signIn(idToken: idToken)
        }
    }

    /// Returns to the server setup.
    func changeServer() {
        session.changeServer()
    }

    private func perform(_ operation: () async throws -> Void) async {
        isSigningIn = true
        defer { isSigningIn = false }
        await attempt(operation)
    }
}
