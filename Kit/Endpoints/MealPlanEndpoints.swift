import Foundation

/// The meal plan.
public enum MealPlanEndpoints {
    private struct CreateBody: Encodable {
        let date: DayDate
        let meal: MealType
        let recipeId: Int
        let servings: Int
    }

    private struct EatersBody: Encodable {
        let date: DayDate
        let meal: MealType
        let recipeId: Int
        let eaterIds: [Int]
        let guests: Int
    }

    private struct VerdictBody: Encodable {
        let verdict: PortionVerdict?
        let userId: Int

        private enum CodingKeys: String, CodingKey {
            case verdict, userId
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(verdict, forKey: .verdict)
            try container.encode(userId, forKey: .userId)
        }
    }

    private struct SideBody: Encodable {
        let recipeId: Int
    }

    private struct CookedBody: Encodable {
        let cooked: Bool
    }

    private struct ShiftBody: Encodable {
        let from: DayDate
        let days: Int
    }

    private struct BatchBody: Encodable {
        let entries: [MealPlanBatchEntry]
    }

    /// `GET /meal-plan`: the entries between two days, both included.
    public static func entries(from: DayDate, to: DayDate) -> Endpoint<[MealPlanEntry]> {
        let query = [
            URLQueryItem(name: "from", value: from.description),
            URLQueryItem(name: "to", value: to.description),
        ]
        return .resource(.get, "meal-plan", query: query)
    }

    /// `POST /meal-plan`: plans a recipe.
    public static func create(date: DayDate, meal: MealType, recipeID: Int, servings: Int) -> Endpoint<MealPlanEntry> {
        .resource(.post, "meal-plan", body: CreateBody(date: date, meal: meal, recipeId: recipeID, servings: servings))
    }

    /// `POST /meal-plan`: plans a recipe for the members with `eaterIDs` and a number of guests.
    public static func create(date: DayDate, meal: MealType, recipeID: Int, eaterIDs: [Int], guests: Int) -> Endpoint<MealPlanEntry> {
        .resource(.post, "meal-plan", body: EatersBody(date: date, meal: meal, recipeId: recipeID, eaterIds: eaterIDs, guests: guests))
    }

    /// `PATCH /meal-plan/{id}`: moves an entry, swaps its recipe or changes who eats.
    public static func update(id: Int, date: DayDate, meal: MealType, recipeID: Int, eaterIDs: [Int], guests: Int) -> Endpoint<MealPlanEntry> {
        .resource(.patch, "meal-plan/\(id)", body: EatersBody(date: date, meal: meal, recipeId: recipeID, eaterIds: eaterIDs, guests: guests))
    }

    /// `POST /meal-plan/{id}/sides`: serves a side with a planned meal and answers with the side as an entry.
    public static func addSide(recipeID: Int, to entryID: Int) -> Endpoint<MealPlanEntry> {
        .resource(.post, "meal-plan/\(entryID)/sides", body: SideBody(recipeId: recipeID))
    }

    /// `PUT /meal-plan/{id}/portion-feedback`: says how the portion was for the signed-in user; `nil` withdraws it.
    ///
    /// The server knows who is signed in. `userID` is sent along for the local copy, which does not.
    public static func setPortionVerdict(_ verdict: PortionVerdict?, id: Int, userID: Int) -> Endpoint<MealPlanEntry> {
        .resource(.put, "meal-plan/\(id)/portion-feedback", body: VerdictBody(verdict: verdict, userId: userID))
    }

    /// `PATCH /meal-plan/{id}`: moves an entry to another day or meal, swaps its recipe or changes its servings.
    public static func update(id: Int, date: DayDate, meal: MealType, recipeID: Int, servings: Int) -> Endpoint<MealPlanEntry> {
        .resource(.patch, "meal-plan/\(id)", body: CreateBody(date: date, meal: meal, recipeId: recipeID, servings: servings))
    }

    /// `POST /meal-plan/shift`: moves every meal not cooked yet from `from` on by `days`, which may be negative,
    /// and answers with the entries that moved.
    public static func shift(from: DayDate, days: Int) -> Endpoint<[MealPlanEntry]> {
        .resource(.post, "meal-plan/shift", body: ShiftBody(from: from, days: days))
    }

    /// `GET /meal-plan/reasons`: why each entry between two days goes with the others.
    public static func reasons(from: DayDate, to: DayDate) -> Endpoint<[MealPlanEntryReasons]> {
        let query = [
            URLQueryItem(name: "from", value: from.description),
            URLQueryItem(name: "to", value: to.description),
        ]
        return .resource(.get, "meal-plan/reasons", query: query)
    }

    /// `PATCH /meal-plan/{id}`: marks an entry as cooked or not cooked.
    public static func setCooked(_ cooked: Bool, id: Int) -> Endpoint<MealPlanEntry> {
        .resource(.patch, "meal-plan/\(id)", body: CookedBody(cooked: cooked))
    }

    /// `DELETE /meal-plan/{id}`: removes an entry.
    public static func delete(id: Int) -> Endpoint<Void> {
        .empty(.delete, "meal-plan/\(id)")
    }

    /// `POST /meal-plan/suggest`: proposes recipes for slots without saving anything.
    public static func suggest(_ request: MealPlanSuggestionRequest) -> Endpoint<MealSuggestions> {
        .plain(.post, "meal-plan/suggest", body: request)
    }

    /// `POST /meal-plan/batch`: saves accepted proposals and answers with the added entries.
    public static func save(_ entries: [MealPlanBatchEntry]) -> Endpoint<[MealPlanEntry]> {
        .resource(.post, "meal-plan/batch", body: BatchBody(entries: entries))
    }
}
