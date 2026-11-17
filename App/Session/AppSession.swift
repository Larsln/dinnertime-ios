import Foundation
import MealplannerKit
import Observation
import UIKit

/// The connection to the server of the household and the user signed in to it.
///
/// All API calls of the app run through ``send(_:)``, which ends the session when the
/// server no longer accepts the token.
@MainActor
@Observable
final class AppSession {
    /// The steps between the first launch and a signed-in app.
    enum Phase: Equatable {
        /// The stored state is being restored.
        case launching
        /// The address of the server is needed.
        case serverSetup
        /// The server is known and waits for a sign-in.
        case signIn(ServerConnection)
        /// A user is signed in to the server at `serverURL`.
        case signedIn(serverURL: URL)
    }

    private static let serverURLKey = "serverURL"

    private(set) var phase: Phase = .launching
    /// The signed-in user, once known.
    private(set) var user: User?

    private var client: APIClient?
    private let credentialStore: CredentialStore
    private let defaults: UserDefaults

    init(credentialStore: CredentialStore = CredentialStore(), defaults: UserDefaults = .standard) {
        self.credentialStore = credentialStore
        self.defaults = defaults
    }

    /// Address of the server that was used last, to prefill the setup.
    var lastServerURL: URL? {
        defaults.url(forKey: Self.serverURLKey)
    }

    /// Restores the session of the previous launch.
    func start() async {
        guard phase == .launching else {
            return
        }
        if let credentials = try? credentialStore.load() {
            activate(credentials)
            user = try? await send(AuthEndpoints.user)
        } else if let url = lastServerURL {
            await reconnect(to: url)
        } else {
            phase = .serverSetup
        }
    }

    /// Validates the address of a server and moves on to the sign-in.
    func connect(to url: URL) async throws {
        let info = try await APIClient(serverURL: url).send(AuthEndpoints.server)
        defaults.set(url, forKey: Self.serverURLKey)
        phase = .signIn(ServerConnection(url: url, info: info))
    }

    /// Returns from the sign-in to the server setup.
    func changeServer() {
        phase = .serverSetup
    }

    /// Signs in with a local account.
    func signIn(username: String, password: String) async throws {
        try await signIn(with: AuthEndpoints.signIn(username: username, password: password, deviceName: deviceName))
    }

    /// Signs in with an ID token of the provider of the server.
    func signIn(idToken: String) async throws {
        try await signIn(with: AuthEndpoints.signIn(idToken: idToken, deviceName: deviceName))
    }

    /// Revokes the token and returns to the sign-in.
    func signOut() async {
        _ = try? await client?.send(AuthEndpoints.signOut)
        await endSession()
    }

    /// Performs an API call as the signed-in user.
    func send<Response>(_ endpoint: Endpoint<Response>) async throws -> Response {
        guard let client else {
            throw APIError.unauthorized
        }
        do {
            return try await client.send(endpoint)
        } catch APIError.unauthorized {
            await endSession()
            throw APIError.unauthorized
        }
    }

    /// Turns the address of an image into an absolute one; the server may answer with relative paths.
    func absoluteURL(for url: URL) -> URL {
        guard url.scheme == nil, case let .signedIn(serverURL) = phase else {
            return url
        }
        return URL(string: url.relativeString, relativeTo: serverURL)?.absoluteURL ?? url
    }

    private var deviceName: String {
        UIDevice.current.name
    }

    private func signIn(with endpoint: Endpoint<SignInResult>) async throws {
        guard case let .signIn(connection) = phase else {
            return
        }
        let result = try await APIClient(serverURL: connection.url).send(endpoint)
        let credentials = Credentials(serverURL: connection.url, token: result.token)
        try credentialStore.save(credentials)
        user = result.user
        activate(credentials)
    }

    private func activate(_ credentials: Credentials) {
        client = APIClient(serverURL: credentials.serverURL, token: credentials.token)
        phase = .signedIn(serverURL: credentials.serverURL)
    }

    private func endSession() async {
        guard case let .signedIn(serverURL) = phase else {
            return
        }
        try? credentialStore.delete()
        client = nil
        user = nil
        phase = .launching
        await reconnect(to: serverURL)
    }

    private func reconnect(to url: URL) async {
        do {
            try await connect(to: url)
        } catch {
            phase = .serverSetup
        }
    }
}
