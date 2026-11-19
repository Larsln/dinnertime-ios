import Foundation

/// Build settings that the app and the share extension read from their own `Info.plist`.
///
/// The values originate from `Config/Shared.xcconfig`, so each of them is defined once.
public enum AppConfiguration {
    /// Product name shown to the user.
    public static var displayName: String {
        value(for: "CFBundleDisplayName") ?? ""
    }

    /// Keychain service under which the credentials are stored.
    public static var keychainService: String {
        value(for: "KeychainService") ?? ""
    }

    /// Keychain access group shared by the app and the share extension.
    ///
    /// Builds without a development team have no application identifier prefix and
    /// therefore no shared group; they fall back to the private keychain of the process.
    public static var keychainAccessGroup: String? {
        guard let prefix = value(for: "KeychainGroupPrefix"), let group = value(for: "KeychainGroup") else {
            return nil
        }
        return prefix + group
    }

    /// App Group through which the app receives the transfers the share extension starts.
    public static var appGroup: String? {
        value(for: "AppGroup")
    }

    /// Bundle identifier of the app, also within the share extension.
    public static var appBundleIdentifier: String {
        value(for: "KeychainService") ?? ""
    }

    /// Redirect URI registered at the OpenID Connect provider.
    public static let oidcRedirectURI = "dinnertime://oidc"

    /// URL scheme of ``oidcRedirectURI``.
    public static let oidcCallbackScheme = "dinnertime"

    private static func value(for key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String, !value.isEmpty else {
            return nil
        }
        return value
    }
}
