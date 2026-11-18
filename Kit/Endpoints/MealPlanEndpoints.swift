import Foundation

/// The meal plan.
public enum MealPlanEndpoints {
    private struct CreateBody: Encodable {
        let date: DayDate
        let meal: MealType
        let recipeId: Int
        let servings: Int
    }

    private struct CookedBody: Encodable {
        let cooked: Bool
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
