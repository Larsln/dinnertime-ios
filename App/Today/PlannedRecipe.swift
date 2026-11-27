import DinnertimeKit

/// A recipe to open with the portions it is planned for.
struct PlannedRecipe: Hashable {
    let recipe: RecipeSummary
    let servings: Double

    init(_ entry: MealPlanEntry) {
        recipe = entry.recipe
        servings = entry.portions
    }
}
