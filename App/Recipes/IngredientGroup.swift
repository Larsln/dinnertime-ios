import MealplannerKit

/// Consecutive ingredient lines that share a section heading.
struct IngredientGroup: Identifiable {
    /// Position of the group within the recipe.
    let id: Int
    /// Heading of the component, such as "Dough".
    let title: String?
    let ingredients: [Ingredient]
}

extension Recipe {
    /// The ingredients in recipe order, split wherever the section heading changes.
    var ingredientGroups: [IngredientGroup] {
        var groups: [IngredientGroup] = []
        for ingredient in ingredients {
            if let last = groups.last, last.title == ingredient.section {
                groups[groups.count - 1] = IngredientGroup(id: last.id, title: last.title, ingredients: last.ingredients + [ingredient])
            } else {
                groups.append(IngredientGroup(id: groups.count, title: ingredient.section, ingredients: [ingredient]))
            }
        }
        return groups
    }
}
