import Foundation

/// The meals a day is planned in.
public enum MealType: String, Codable, CaseIterable, Sendable {
    case breakfast, lunch, dinner, dessert, snack
}

/// A recipe planned for one meal of one day.
///
/// `servings` counts the people who eat. `eaters` names the members of the household among them and `guests`
/// counts the others, who get a standard portion each. `portions` is what is cooked and shopped for.
/// An entry with a `parentID` is a side served with that meal.
public struct MealPlanEntry: Decodable, Hashable, Identifiable, Sendable {
    public let id: Int
    /// The meal a side is served with; `nil` for a meal of its own.
    public let parentID: Int?
    public let date: DayDate
    public let meal: MealType
    public let servings: Int
    /// Standard portions to cook; the servings for entries that name nobody.
    public let portions: Double
    public let guests: Int
    /// Members who eat, each with the share of a standard portion that suits them; `nil` when nobody is named.
    public let eaters: [MealEater]?
    /// What members said about their portion.
    public let portionFeedback: [PortionFeedback]
    public let cookedAt: Date?
    public let recipe: RecipeSummary

    private enum CodingKeys: String, CodingKey {
        case id, date, meal, parentID = "parentId", servings, portions, guests, eaters, portionFeedback, cookedAt, recipe
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        parentID = try container.decodeIfPresent(Int.self, forKey: .parentID)
        date = try container.decode(DayDate.self, forKey: .date)
        meal = try container.decode(MealType.self, forKey: .meal)
        servings = try container.decode(Int.self, forKey: .servings)
        portions = try container.decodeIfPresent(Double.self, forKey: .portions) ?? Double(servings)
        guests = try container.decodeIfPresent(Int.self, forKey: .guests) ?? 0
        eaters = try container.decodeIfPresent([MealEater].self, forKey: .eaters)
        portionFeedback = try container.decodeIfPresent([PortionFeedback].self, forKey: .portionFeedback) ?? []
        cookedAt = try container.decodeIfPresent(Date.self, forKey: .cookedAt)
        recipe = try container.decode(RecipeSummary.self, forKey: .recipe)
    }

    /// Whether the entry was marked as cooked.
    public var isCooked: Bool {
        cookedAt != nil
    }

    /// What the member with `userID` said about the portion; `nil` when nothing.
    public func verdict(of userID: Int?) -> PortionVerdict? {
        portionFeedback.first { $0.userID == userID }?.verdict
    }

    /// The portions as a number: whole ones without decimals, others with up to two.
    public func portionsText(locale: Locale = .current) -> String {
        portions.formatted(.number.precision(.fractionLength(0...2)).locale(locale))
    }

    /// The portions as a whole number, when they are one.
    public var wholePortions: Int? {
        portions == portions.rounded() ? Int(portions) : nil
    }
}
