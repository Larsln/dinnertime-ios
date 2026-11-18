import MealplannerKit
import SwiftUI

/// Favorite state and household average of a recipe, as shown at the edge of a list row.
struct RecipeMarks: View {
    let recipe: RecipeSummary

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if recipe.isFavorite {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                    .accessibilityLabel("Favorite")
            }
            if let average = recipe.averageRatingText() {
                AverageRatingLabel(text: average)
            }
        }
        .font(.caption)
    }
}

/// The household average next to a star.
struct AverageRatingLabel: View {
    let text: String

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
            Text(verbatim: text)
                .monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Average rating: \(text)")
    }
}
