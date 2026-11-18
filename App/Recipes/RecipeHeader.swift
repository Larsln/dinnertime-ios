import MealplannerKit
import SwiftUI

/// Cover image, description, times, course, tags and household rating at the top of a recipe.
struct RecipeHeader: View {
    private static let imageHeight: CGFloat = 220

    let recipe: RecipeSummary

    var body: some View {
        if recipe.coverURL != nil {
            CoverImage(url: recipe.coverURL)
                .frame(maxWidth: .infinity)
                .frame(height: Self.imageHeight)
                .listRowInsets(EdgeInsets())
        }
        if let description = recipe.description {
            Text(verbatim: description)
        }
        if let yieldText = recipe.yieldText {
            LabeledContent("Yield", value: yieldText)
        }
        if let minutes = recipe.prepMinutes {
            LabeledContent("Preparation", value: Duration.text(minutes: minutes))
        }
        if let minutes = recipe.cookMinutes {
            LabeledContent("Cooking", value: Duration.text(minutes: minutes))
        }
        if let average = recipe.averageRatingText() {
            LabeledContent("Household rating") {
                HStack(spacing: 6) {
                    AverageRatingLabel(text: average)
                    Text("(\(recipe.ratingCount) ratings)")
                }
            }
        }
        if !recipe.labelLine.isEmpty {
            Text(verbatim: recipe.labelLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
