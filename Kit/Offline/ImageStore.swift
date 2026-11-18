import CryptoKit
import Foundation

/// Keeps downloaded images on disk, each under the address it came from.
///
/// The address of a cover never shows another image, so a stored file is valid for good.
public struct ImageStore: Sendable {
    private let directory: URL

    /// Opens the store in `directory`.
    public init(directory: URL) {
        self.directory = directory
    }

    /// The stored image of `address`, if it was downloaded before.
    public func data(for address: String) -> Data? {
        try? Data(contentsOf: file(for: address))
    }

    /// Whether the image of `address` is stored.
    public func contains(_ address: String) -> Bool {
        FileManager.default.fileExists(atPath: file(for: address).path())
    }

    /// Stores the image of `address`.
    public func store(_ data: Data, for address: String) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: file(for: address), options: .atomic)
    }

    /// Removes the images of all addresses that are not in `addresses`.
    public func prune(keeping addresses: some Sequence<String>) {
        let kept = Set(addresses.map(Self.fileName(for:)))
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        for file in files where !kept.contains(file.lastPathComponent) {
            try? FileManager.default.removeItem(at: file)
        }
    }

    /// Deletes all images.
    public func wipe() {
        try? FileManager.default.removeItem(at: directory)
    }

    /// Name of the file for an address: the hash of the address.
    static func fileName(for address: String) -> String {
        SHA256.hash(data: Data(address.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private func file(for address: String) -> URL {
        directory.appending(path: Self.fileName(for: address))
    }
}
