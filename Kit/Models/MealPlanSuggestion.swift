/// What the planner weighs when it proposes recipes; the defaults are those of the server.
public struct MealPlanPreferences: Encodable, Equatable, Sendable {
    /// Opened packages and the pantry are used up first.
    public var useLeftovers = true
    /// Monday to Friday only recipes that take at most 30 minutes.
    public var quickOnWeekdays = false
    /// Recipes that were not planned for a long time come first.
    public var preferNotRecent = true
    /// Favorites and well rated recipes are planned more often.
    public var preferFavorites = false
    /// No dish twice and not the same cuisine twice in a row.
    public var variety = true

    public init() {}
}

/// A recipe assigned to a slot, as the planner is told what to keep and what to avoid.
public struct MealAssignment: Encodable, Hashable, Sendable {
    public let date: DayDate
    public let meal: MealType
    public let recipeID: Int

    public init(date: DayDate, meal: MealType, recipeID: Int) {
        self.date = date
        self.meal = meal
        self.recipeID = recipeID
    }

    private enum CodingKeys: String, CodingKey {
        case date, meal
        case recipeID = "recipeId"
    }
}

/// A recipe the planner proposes for a slot; nothing is saved yet.
public struct MealProposal: Decodable, Hashable, Sendable {
    public let date: DayDate
    public let meal: MealType
    public let recipe: RecipeSummary
    /// Whether the proposal was passed in as one to keep.
    public let kept: Bool

    /// The day and meal the proposal is for.
    public var slot: MealSlot {
        MealSlot(date: date, meal: meal)
    }

    /// The proposal as slot and recipe.
    public var assignment: MealAssignment {
        MealAssignment(date: date, meal: meal, recipeID: recipe.id)
    }
}

/// The answer of `POST /meal-plan/suggest`.
public struct MealSuggestions: Decodable, Sendable {
    /// Proposals by date and meal; slots without a matching recipe are missing.
    public let proposals: [MealProposal]
    /// Number of recipes that match the filters.
    public let candidateCount: Int

    private enum CodingKeys: String, CodingKey {
        case data, meta
    }

    private enum MetaKeys: String, CodingKey {
        case candidateCount
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let meta = try container.nestedContainer(keyedBy: MetaKeys.self, forKey: .meta)
        proposals = try container.decode([MealProposal].self, forKey: .data)
        candidateCount = try meta.decode(Int.self, forKey: .candidateCount)
    }
}
