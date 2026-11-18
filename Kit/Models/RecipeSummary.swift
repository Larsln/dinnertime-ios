import Foundation

/// The part of a recipe that lists and plan entries carry.
///
/// Rating and favorite state are only sent by the recipe endpoints; where a recipe is
/// embedded in another resource they read as unrated and not a favorite.
public struct RecipeSummary: Decodable, Hashable, Identifiable, Sendable {
    /// Bounds of a rating, from bad to good.
    public static let ratingRange = 0...10

    public let id: Int
    public let title: String
    public let slug: String
    public let description: String?
    /// Key of the course, the main category of the dish.
    public let course: String?
    /// Name of the course in the requested language.
    public let courseName: String?
    public let servings: Int?
    public let yieldText: String?
    public let prepMinutes: Int?
    public let cookMinutes: Int?
    /// Address of the cover image; may be relative to the server.
    public let coverURL: URL?
    public let tags: [Tag]
    /// Rating of the signed-in user within ``ratingRange``.
    public var rating: Int?
    /// Whether the signed-in user marked the recipe as a favorite.
    public var isFavorite: Bool
    /// Mean rating of all household members with one decimal.
    public let averageRating: Double?
    /// Number of household members who rated the recipe.
    public let ratingCount: Int

    private enum CodingKeys: String, CodingKey {
        case id, title, slug, description, course, courseName, servings, yieldText, prepMinutes, cookMinutes, tags
        case rating, isFavorite, averageRating, ratingCount
        case coverURL = "coverUrl"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        slug = try container.decode(String.self, forKey: .slug)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        course = try container.decodeIfPresent(String.self, forKey: .course)
        courseName = try container.decodeIfPresent(String.self, forKey: .courseName)
        servings = try container.decodeIfPresent(Int.self, forKey: .servings)
        yieldText = try container.decodeIfPresent(String.self, forKey: .yieldText)
        prepMinutes = try container.decodeIfPresent(Int.self, forKey: .prepMinutes)
        cookMinutes = try container.decodeIfPresent(Int.self, forKey: .cookMinutes)
        coverURL = try container.decodeIfPresent(URL.self, forKey: .coverURL)
        tags = try container.decode([Tag].self, forKey: .tags)
        rating = try container.decodeIfPresent(Int.self, forKey: .rating)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        averageRating = try container.decodeIfPresent(Double.self, forKey: .averageRating)
        ratingCount = try container.decodeIfPresent(Int.self, forKey: .ratingCount) ?? 0
    }
}
