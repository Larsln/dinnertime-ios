import DinnertimeKit

/// The recipe shown next to the list on wide screens, with the servings it was opened for.
struct RecipeSelection: Equatable {
    let recipe: RecipeSummary
    /// Servings of the plan entry the recipe was opened from; `nil` when it was chosen from the list.
    let servings: Double?

    init(recipe: RecipeSummary, servings: Double? = nil) {
        self.recipe = recipe
        self.servings = servings
    }

    init(_ planned: PlannedRecipe) {
        recipe = planned.recipe
        servings = planned.servings
    }

    /// Tells one opening of a recipe from another, so that the recipe is loaded anew.
    var id: [Double?] {
        [Double(recipe.id), servings]
    }
}
