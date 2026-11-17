import CryptoKit
import Foundation

/// Proof key for the authorization code flow (RFC 7636).
public struct PKCE: Equatable, Sendable {
    private static let verifierByteCount = 32

    /// Secret that is sent when the authorization code is exchanged.
    public let verifier: String

    /// SHA-256 hash of the verifier that is sent with the authorization request.
    public var challenge: String {
        Data(SHA256.hash(data: Data(verifier.utf8))).base64URLEncoded
    }

    /// Creates a proof key with a random verifier.
    public init() {
        verifier = RandomToken.make(byteCount: Self.verifierByteCount)
    }

    init(verifier: String) {
        self.verifier = verifier
    }
}

/// Random values for verifiers, states and nonces.
enum RandomToken {
    /// A URL-safe string made from `byteCount` random bytes.
    static func make(byteCount: Int) -> String {
        var generator = SystemRandomNumberGenerator()
        let bytes = (0..<byteCount).map { _ in UInt8.random(in: .min ... .max, using: &generator) }
        return Data(bytes).base64URLEncoded
    }
}

extension Data {
    /// Base64 with the URL-safe alphabet and without padding.
    var base64URLEncoded: String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
