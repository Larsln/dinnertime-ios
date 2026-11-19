import DinnertimeKit
import SwiftUI

/// Household average and favorite state of a recipe, as shown below its title in a list row.
struct RecipeMarks: View {
    let recipe: RecipeSummary

    var body: some View {
        HStack(spacing: 8) {
            if let average = recipe.averageRatingText() {
                AverageRatingLabel(text: average)
            }
            if recipe.isFavorite {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Color.accent)
                    .accessibilityLabel("Favorite")
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
                .foregroundStyle(Color.accent)
            Text(verbatim: text)
                .monospacedDigit()
                .foregroundStyle(.inkMuted)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Average rating: \(text)")
    }
}
