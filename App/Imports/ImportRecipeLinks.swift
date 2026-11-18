import MealplannerKit
import SwiftUI

/// The recipes of an import that produced several, one row each that opens its recipe.
struct ImportRecipeLinks: View {
    let recipes: [RecipeSummary]

    var body: some View {
        ForEach(recipes) { recipe in
            NavigationLink(value: recipe) {
                Label {
                    Text(verbatim: recipe.title)
                } icon: {
                    Image(systemName: "fork.knife")
                }
            }
        }
    }
}
