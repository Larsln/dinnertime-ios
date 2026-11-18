import Foundation

/// What a request to `GET /imports/{id}/wait` said about an import.
public enum ImportOutcome: Equatable, Sendable {
    /// The recipe with this title was imported.
    case imported(importID: Int, title: String)
    /// The import failed for the reason the server explains in `message`.
    case failed(importID: Int, message: String?)
    /// The server gave up waiting; the import is still running.
    case unfinished(importID: Int)

    /// Reads the body of the answer; `nil` if it is not an import.
    public init?(waitAnswer data: Data) {
        guard let item = try? ImportEndpoints.wait(id: 0).decode(data) else {
            return nil
        }
        self.init(item)
    }

    /// The outcome an import stands for.
    public init(_ item: RecipeImport) {
        switch item.status {
        case .completed:
            self = .imported(importID: item.id, title: item.recipe?.title ?? "")
        case .failed:
            self = .failed(importID: item.id, message: item.errorMessage)
        case .pending, .processing:
            self = .unfinished(importID: item.id)
        }
    }

    /// The import the outcome belongs to.
    public var importID: Int {
        switch self {
        case let .imported(importID, _), let .failed(importID, _), let .unfinished(importID):
            importID
        }
    }

    /// The notification that tells the user about the outcome; `nil` while the import is still running.
    public var notice: ImportNotice? {
        switch self {
        case let .imported(importID, title):
            ImportNotice(importID: importID, title: String(localized: "Recipe imported", bundle: .kit), body: title, opensRecipe: true)
        case let .failed(importID, message):
            ImportNotice(
                importID: importID,
                title: String(localized: "Import failed", bundle: .kit),
                body: message ?? String(localized: "The link could not be imported.", bundle: .kit),
                opensRecipe: false
            )
        case .unfinished:
            nil
        }
    }
}

/// A local notification about a finished import.
public struct ImportNotice: Equatable, Sendable {
    private static let importKey = "importID"
    private static let recipeKey = "opensRecipe"

    public let importID: Int
    public let title: String
    public let body: String
    /// Whether tapping the notification opens the imported recipe instead of the list of imports.
    public let opensRecipe: Bool

    /// What the notification carries to find its way back when it is tapped.
    public var userInfo: [String: Any] {
        [Self.importKey: importID, Self.recipeKey: opensRecipe]
    }

    /// Where a tapped notification with this `userInfo` leads; `nil` for notifications of another kind.
    public static func destination(for userInfo: [AnyHashable: Any]) -> ImportDestination? {
        guard let importID = userInfo[importKey] as? Int else {
            return nil
        }
        return userInfo[recipeKey] as? Bool == true ? .recipe(importID: importID) : .imports
    }
}

/// The screen a notification about an import opens.
public enum ImportDestination: Hashable, Sendable {
    /// The recipe the import produced.
    case recipe(importID: Int)
    /// The list of imports.
    case imports
}
