import DinnertimeKit
import SwiftUI

/// The servings stepper and the ingredients of a recipe, grouped by component.
struct RecipeIngredientList: View {
    let recipe: Recipe
    @Bindable var model: RecipeDetailModel

    var body: some View {
        if model.canScale {
            Section {
                Stepper("Servings: \(model.servingsText)", value: $model.servings, in: RecipeDetailModel.servingsRange)
            }
        }
        ForEach(recipe.ingredientGroups) { group in
            Section {
                ForEach(group.ingredients) { ingredient in
                    IngredientRow(ingredient: ingredient, scale: model.scale)
                }
            } header: {
                if let title = group.title {
                    Text(verbatim: title)
                        .sectionHeadingStyle()
                }
            }
        }
    }
}
