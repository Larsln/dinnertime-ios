import Foundation

/// A request to turn a link into a recipe.
public struct RecipeImport: Decodable, Hashable, Identifiable, Sendable {
    /// Progress of an import.
    public enum Status: String, Decodable, Sendable {
        case pending, processing, completed, failed
    }

    public let id: Int
    public let url: String
    public let status: Status
    /// `download_failed`, `no_recipe_found`, `ai_failed` or `unknown`.
    public let error: String?
    /// Explanation of `error` in the requested language.
    public let errorMessage: String?
    public let createdAt: Date
    public let recipe: RecipeSummary?

    /// Whether the server is still working on the import.
    public var isActive: Bool {
        status == .pending || status == .processing
    }
}
