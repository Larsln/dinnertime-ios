import Foundation

/// Links the user wanted to import while there was no connection; they are submitted once there is one.
///
/// The list lives in the container of the App Group, so that the share extension can add to it and the app sends it.
public struct PendingLinks: Sendable {
    private let file: URL

    /// Uses the file in `directory`; by default the container of the App Group, or the documents of the process without one.
    public init(directory: URL? = nil) {
        let group = AppConfiguration.appGroup.flatMap { FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: $0) }
        let base = directory ?? group ?? URL.applicationSupportDirectory
        file = base.appending(path: "pending-links.json")
    }

    /// The waiting links, oldest first.
    public var links: [PendingLink] {
        (try? Data(contentsOf: file)).flatMap { try? JSONDecoder().decode([PendingLink].self, from: $0) } ?? []
    }

    /// Adds a link with the number of dishes it shows; a link that waits already moves to the end with the new number.
    public func add(_ link: URL, dishCount: Int? = nil) {
        save(links.filter { $0.url != link } + [PendingLink(url: link, dishCount: dishCount)])
    }

    /// Takes a link off the list once it was submitted.
    public func remove(_ link: URL) {
        save(links.filter { $0.url != link })
    }

    /// Forgets all links.
    public func removeAll() {
        try? FileManager.default.removeItem(at: file)
    }

    private func save(_ links: [PendingLink]) {
        try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? JSONEncoder().encode(links).write(to: file, options: .atomic)
    }
}
