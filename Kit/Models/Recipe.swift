import Foundation

/// A complete recipe.
public struct Recipe: Decodable, Hashable, Identifiable, Sendable {
    public var summary: RecipeSummary
    public let sourceURL: URL?
    public let sourcePlatform: String?
    public let mealTagsLocked: Bool
    public let ingredients: [Ingredient]
    public let steps: [RecipeStep]
    public let tools: [Tool]

    public var id: Int {
        summary.id
    }

    private enum CodingKeys: String, CodingKey {
        case sourcePlatform, mealTagsLocked, ingredients, steps, tools
        case sourceURL = "sourceUrl"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        summary = try RecipeSummary(from: decoder)
        sourceURL = try container.decodeIfPresent(URL.self, forKey: .sourceURL)
        sourcePlatform = try container.decodeIfPresent(String.self, forKey: .sourcePlatform)
        mealTagsLocked = try container.decode(Bool.self, forKey: .mealTagsLocked)
        ingredients = try container.decode([Ingredient].self, forKey: .ingredients)
        steps = try container.decode([RecipeStep].self, forKey: .steps)
        tools = try container.decode([Tool].self, forKey: .tools)
    }
}

/// One line of the ingredient list.
///
/// A missing unit means the quantity counts pieces. Lines without a product only carry `rawText`.
public struct Ingredient: Decodable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let position: Int
    /// Heading of the component the line belongs to, such as "Dough".
    public let section: String?
    public let quantity: Double?
    public let unit: MeasureUnit?
    public let product: Product?
    public let note: String?
    /// Whether the quantity was estimated because the source did not state it.
    public let isEstimated: Bool
    public let rawText: String?
}

/// One step of the instructions.
public struct RecipeStep: Decodable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let position: Int
    /// Heading of the component the step belongs to, such as "Filling".
    public let section: String?
    public let text: String
}
