import DinnertimeKit
import SwiftUI

/// Cover image, description, rating, times, course and tags at the top of a recipe.
struct RecipeHeader: View {
    private static let imageHeight: CGFloat = 220

    let model: RecipeDetailModel

    var body: some View {
        let recipe = model.summary
        if recipe.coverURL != nil {
            CoverImage(url: recipe.coverURL)
                .frame(maxWidth: .infinity)
                .frame(height: Self.imageHeight)
                .listRowInsets(EdgeInsets())
        }
        if let description = recipe.description {
            Text(verbatim: description)
        }
        RecipeRatingBlock(model: model)
        if let yieldText = recipe.yieldText {
            LabeledContent("Yield", value: yieldText)
        }
        if let minutes = recipe.prepMinutes {
            LabeledContent("Preparation", value: Duration.text(minutes: minutes))
        }
        if let minutes = recipe.cookMinutes {
            LabeledContent("Cooking", value: Duration.text(minutes: minutes))
        }
        if !recipe.labelLine.isEmpty {
            Text(verbatim: recipe.labelLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
