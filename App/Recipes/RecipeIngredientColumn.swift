import DinnertimeKit
import SwiftUI

/// The servings stepper and the ingredients of a recipe as a column, grouped by component.
struct RecipeIngredientColumn: View {
    let recipe: Recipe
    @Bindable var model: RecipeDetailModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .sectionHeadingStyle()
                .accessibilityAddTraits(.isHeader)
            if model.canScale {
                Stepper("Servings: \(model.servings)", value: $model.servings, in: RecipeDetailModel.servingsRange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.sunken, in: .tile)
            }
            ForEach(recipe.ingredientGroups) { group in
                if let title = group.title {
                    Text(verbatim: title)
                        .font(.headline)
                        .padding(.top, 6)
                        .accessibilityAddTraits(.isHeader)
                }
                ForEach(group.ingredients) { ingredient in
                    IngredientRow(ingredient: ingredient, scale: model.scale)
                    if ingredient.id != group.ingredients.last?.id {
                        Divider()
                            .overlay(.line)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
