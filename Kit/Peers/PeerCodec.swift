import CryptoKit
import Foundation

/// Seals and opens what devices of a household send each other, with the secret they share.
///
/// The secret itself never leaves the device. Messages are encrypted and authenticated with
/// a key made from it, so that only devices of the household can read or write them, and a
/// device that wants to connect proves that it knows the secret by signing a random number.
public struct PeerCodec: Sendable {
    private static let nonceLength = 16

    private let key: SymmetricKey

    /// Creates a codec for the household with `peerKey`.
    public init(peerKey: String) {
        key = SymmetricKey(data: SHA256.hash(data: Data(peerKey.utf8)))
    }

    /// The proof a device sends along when it invites another: a random number and its code.
    public func invitation() -> Data {
        let nonce = Data((0..<Self.nonceLength).map { _ in UInt8.random(in: .min ... .max) })
        return nonce + Data(HMAC<SHA256>.authenticationCode(for: nonce, using: key))
    }

    /// Whether an invitation was made by a device that knows the secret of this household.
    public func accepts(invitation: Data?) -> Bool {
        guard let invitation, invitation.count > Self.nonceLength else {
            return false
        }
        let nonce = invitation.prefix(Self.nonceLength)
        return HMAC<SHA256>.isValidAuthenticationCode(invitation.dropFirst(Self.nonceLength), authenticating: nonce, using: key)
    }

    /// Encodes changes as one encrypted message.
    public func seal(_ changes: [PeerChange]) throws -> Data {
        try ChaChaPoly.seal(try JSONEncoder().encode(changes), using: key).combined
    }

    /// Decodes a message; `nil` when it does not come from a device of this household or cannot be read.
    ///
    /// Changes of a kind this version does not know are left out, so that the others still arrive.
    public func open(_ message: Data) -> [PeerChange]? {
        guard let box = try? ChaChaPoly.SealedBox(combined: message), let payload = try? ChaChaPoly.open(box, using: key) else {
            return nil
        }
        return (try? JSONDecoder().decode([Readable].self, from: payload))?.compactMap(\.change)
    }

    /// A change of a message, or nothing where it could not be read.
    private struct Readable: Decodable {
        let change: PeerChange?

        init(from decoder: Decoder) throws {
            change = try? PeerChange(from: decoder)
        }
    }
}
