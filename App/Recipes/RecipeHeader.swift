import MealplannerKit
import SwiftUI

/// Cover image, description, times and tags at the top of a recipe.
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
            LabeledContent("Preparation", value: Self.durationText(minutes: minutes))
        }
        if let minutes = recipe.cookMinutes {
            LabeledContent("Cooking", value: Self.durationText(minutes: minutes))
        }
        if !recipe.tags.isEmpty {
            Text(verbatim: recipe.tags.map(\.name).joined(separator: " · "))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private static func durationText(minutes: Int) -> String {
        Duration.seconds(minutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }
}
