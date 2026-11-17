import Foundation

/// The meals a day is planned in.
public enum MealType: String, Codable, CaseIterable, Sendable {
    case breakfast, lunch, dinner, dessert, snack
}

/// A recipe planned for one meal of one day.
public struct MealPlanEntry: Decodable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let date: DayDate
    public let meal: MealType
    public let servings: Int
    public let cookedAt: Date?
    public let recipe: RecipeSummary

    /// Whether the entry was marked as cooked.
    public var isCooked: Bool {
        cookedAt != nil
    }
}
