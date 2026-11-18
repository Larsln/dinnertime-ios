import Foundation
import Security

/// Failure of a Keychain operation.
public struct KeychainError: Error, Equatable, Sendable {
    /// Status code reported by the Security framework.
    public let status: OSStatus
}

extension KeychainError: LocalizedError {
    public var errorDescription: String? {
        String(localized: "The credentials could not be accessed (\(Int(status))).", bundle: .kit)
    }
}

/// Keeps the credentials in the Keychain, where the app and the share extension both reach them.
public struct CredentialStore: Sendable {
    private static let account = "credentials"

    private let service: String
    private let accessGroup: String?

    /// Creates a store; by default it uses the service and access group of ``AppConfiguration``.
    public init(
        service: String = AppConfiguration.keychainService,
        accessGroup: String? = AppConfiguration.keychainAccessGroup
    ) {
        self.service = service
        self.accessGroup = accessGroup
    }

    /// The stored credentials, or `nil` if nobody is signed in.
    public func load() throws -> Credentials? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError(status: status)
        }
        return try? JSONDecoder().decode(Credentials.self, from: data)
    }

    /// Stores the credentials, replacing earlier ones.
    public func save(_ credentials: Credentials) throws {
        try delete()
        var attributes = baseQuery
        attributes[kSecValueData as String] = try JSONEncoder().encode(credentials)
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError(status: status)
        }
    }

    /// Removes the credentials.
    public func delete() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError(status: status)
        }
    }

    private var baseQuery: [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: Self.account,
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }
}

/// Keeps the secret by which the devices of a household recognise each other in the Keychain of the app.
public struct PeerKeyStore: Sendable {
    private static let account = "peer-key"

    private let service: String

    /// Creates a store; by default under the Keychain service of ``AppConfiguration``.
    public init(service: String = AppConfiguration.keychainService) {
        self.service = service
    }

    /// The stored secret, if the app synced with the server before.
    public func load() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    /// Stores the secret, replacing an earlier one.
    public func save(_ key: String) {
        delete()
        var attributes = baseQuery
        attributes[kSecValueData as String] = Data(key.utf8)
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attributes as CFDictionary, nil)
    }

    /// Removes the secret.
    public func delete() {
        SecItemDelete(baseQuery as CFDictionary)
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: Self.account,
        ]
    }
}
