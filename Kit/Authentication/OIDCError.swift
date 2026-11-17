import Foundation

/// Failures of the sign-in at the OpenID Connect provider.
public enum OIDCError: Error, Equatable, Sendable {
    /// The provider or its discovery document could not be loaded.
    case providerUnreachable
    /// The provider redirected back with an error or an answer that does not belong to the request.
    case authorizationFailed(description: String?)
    /// The provider did not hand out an ID token for the authorization code.
    case tokenExchangeFailed
}

extension OIDCError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .providerUnreachable:
            String(localized: "The sign-in provider could not be reached.", bundle: .kit)
        case let .authorizationFailed(description):
            description ?? String(localized: "The sign-in at the provider failed.", bundle: .kit)
        case .tokenExchangeFailed:
            String(localized: "The sign-in provider did not confirm the sign-in.", bundle: .kit)
        }
    }
}
