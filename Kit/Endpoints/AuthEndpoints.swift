import Foundation

/// Server description and sign-in.
public enum AuthEndpoints {
    private struct PasswordBody: Encodable {
        let username: String
        let password: String
        let deviceName: String
    }

    private struct TokenBody: Encodable {
        let idToken: String
        let deviceName: String
    }

    /// `GET /server`: describes the server and validates its address.
    public static var server: Endpoint<ServerInfo> {
        .plain(.get, "server", requiresAuthentication: false)
    }

    /// `POST /auth/login`: signs in with a local account.
    public static func signIn(username: String, password: String, deviceName: String) -> Endpoint<SignInResult> {
        let body = PasswordBody(username: username, password: password, deviceName: deviceName)
        return .plain(.post, "auth/login", body: body, requiresAuthentication: false)
    }

    /// `POST /auth/oidc`: exchanges an ID token of the provider for an API token.
    public static func signIn(idToken: String, deviceName: String) -> Endpoint<SignInResult> {
        let body = TokenBody(idToken: idToken, deviceName: deviceName)
        return .plain(.post, "auth/oidc", body: body, requiresAuthentication: false)
    }

    /// `POST /auth/logout`: revokes the token in use.
    public static var signOut: Endpoint<Void> {
        .empty(.post, "auth/logout")
    }

    /// `GET /auth/user`: the signed-in user.
    public static var user: Endpoint<User> {
        .resource(.get, "auth/user")
    }
}
