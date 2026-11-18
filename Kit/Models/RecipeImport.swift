import Foundation

/// A request to turn a link into a recipe.
public struct RecipeImport: Decodable, Hashable, Identifiable, Sendable {
    /// Progress of an import.
    public enum Status: String, Decodable, Sendable {
        case pending, processing, completed, failed
    }

    /// What the server is doing while an import is processing, in this order.
    public enum Stage: String, Decodable, CaseIterable, Sendable {
        case downloading, analyzing, saving
    }

    public let id: Int
    public let url: String
    public let status: Status
    /// Current step of a processing import.
    public let stage: Stage?
    /// `download_failed`, `no_recipe_found`, `ai_failed` or `unknown`.
    public let error: String?
    /// Explanation of `error` in the requested language.
    public let errorMessage: String?
    public let createdAt: Date
    /// The first of ``recipes``.
    public let recipe: RecipeSummary?
    /// All recipes the import produced, in the order of the video.
    public let recipes: [RecipeSummary]
    /// Number of dishes the user said the video shows; `nil` when the server finds out itself.
    public let dishCount: Int?

    private enum CodingKeys: String, CodingKey {
        case id, url, status, stage, error, errorMessage, createdAt, recipe, recipes, dishCount
    }

    /// Reads an import; answers of servers that produce one recipe per import lack `recipes` and `dish_count`.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        url = try container.decode(String.self, forKey: .url)
        status = try container.decode(Status.self, forKey: .status)
        stage = try container.decodeIfPresent(Stage.self, forKey: .stage)
        error = try container.decodeIfPresent(String.self, forKey: .error)
        errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        let first = try container.decodeIfPresent(RecipeSummary.self, forKey: .recipe)
        recipes = try container.decodeIfPresent([RecipeSummary].self, forKey: .recipes) ?? [first].compactMap { $0 }
        recipe = first ?? recipes.first
        dishCount = try container.decodeIfPresent(Int.self, forKey: .dishCount)
    }

    /// Whether the server is still working on the import.
    public var isActive: Bool {
        status == .pending || status == .processing
    }
}
