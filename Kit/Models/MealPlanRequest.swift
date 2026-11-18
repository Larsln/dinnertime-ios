/// What the user chose in the first two steps of planning a week.
public struct MealPlanCriteria: Equatable, Sendable {
    public var from: DayDate
    public var to: DayDate
    public var servings: Int
    public var slots: [MealSlot]
    public var preferences: MealPlanPreferences
    /// Only recipes with at least one of these tags; empty for no restriction.
    public var tagIDs: [Int]
    /// Only recipes of these courses; empty for no restriction.
    public var courses: [String]

    public init(from: DayDate, to: DayDate, servings: Int, slots: [MealSlot], preferences: MealPlanPreferences = MealPlanPreferences(), tagIDs: [Int] = [], courses: [String] = []) {
        self.from = from
        self.to = to
        self.servings = servings
        self.slots = slots
        self.preferences = preferences
        self.tagIDs = tagIDs
        self.courses = courses
    }
}

/// The body of `POST /meal-plan/suggest`; restrictions and lists that are empty are left out.
public struct MealPlanSuggestionRequest: Encodable, Equatable, Sendable {
    public let from: DayDate
    public let to: DayDate
    public let servings: Int
    public let slots: [MealSlot]
    public let preferences: MealPlanPreferences
    public let tagIDs: [Int]?
    public let courses: [String]?
    /// Proposals that are returned unchanged.
    public let keep: [MealAssignment]?
    /// Recipes that are not proposed for their slot again.
    public let avoid: [MealAssignment]?

    /// Asks for proposals that match `criteria`, keeping and avoiding the given assignments.
    public init(_ criteria: MealPlanCriteria, keep: [MealAssignment] = [], avoid: [MealAssignment] = []) {
        from = criteria.from
        to = criteria.to
        servings = criteria.servings
        slots = criteria.slots
        preferences = criteria.preferences
        tagIDs = criteria.tagIDs.isEmpty ? nil : criteria.tagIDs
        courses = criteria.courses.isEmpty ? nil : criteria.courses
        self.keep = keep.isEmpty ? nil : keep
        self.avoid = avoid.isEmpty ? nil : avoid
    }

    private enum CodingKeys: String, CodingKey {
        case from, to, servings, slots, preferences, courses, keep, avoid
        case tagIDs = "tagIds"
    }
}

/// One accepted proposal as `POST /meal-plan/batch` saves it.
public struct MealPlanBatchEntry: Encodable, Equatable, Sendable {
    public let date: DayDate
    public let meal: MealType
    public let recipeID: Int
    public let servings: Int

    private enum CodingKeys: String, CodingKey {
        case date, meal, servings
        case recipeID = "recipeId"
    }
}
