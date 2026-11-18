/// A utensil from the catalog of the household that recipes can require.
public struct Tool: Decodable, Hashable, Identifiable, Sendable {
    public let id: Int
    public var name: String
    /// Whether the household has the tool.
    public var isOwned: Bool
    /// Number of recipes that require the tool; only present in the catalog.
    public let recipeCount: Int?

    private enum CodingKeys: String, CodingKey {
        case id, name, isOwned, recipeCount
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        isOwned = try container.decodeIfPresent(Bool.self, forKey: .isOwned) ?? true
        recipeCount = try container.decodeIfPresent(Int.self, forKey: .recipeCount)
    }
}
