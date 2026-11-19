import DinnertimeKit
import SwiftUI

/// Title, description, labels, times and rating of a recipe on wide screens, with the controls that change it at the right.
struct RecipeWideHeader<Actions: View>: View {
    private static var ratingWidth: CGFloat { 420 }

    let model: RecipeDetailModel
    @ViewBuilder let actions: Actions

    var body: some View {
        let recipe = model.summary
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text(verbatim: recipe.title)
                    .contentTitleStyle()
                    .accessibilityAddTraits(.isHeader)
                if !recipe.labelLine.isEmpty {
                    Text(verbatim: recipe.labelLine)
                        .font(.subheadline)
                        .foregroundStyle(.inkMuted)
                }
                if let description = recipe.description {
                    Text(verbatim: description)
                }
                HStack(alignment: .top, spacing: 24) {
                    if let yieldText = recipe.yieldText {
                        fact("Yield", value: yieldText)
                    }
                    if let minutes = recipe.prepMinutes {
                        fact("Preparation", value: Duration.text(minutes: minutes))
                    }
                    if let minutes = recipe.cookMinutes {
                        fact("Cooking", value: Duration.text(minutes: minutes))
                    }
                }
                RecipeRatingBlock(model: model)
                    .frame(maxWidth: Self.ratingWidth)
            }
            Spacer(minLength: 0)
            actions
        }
    }

    private func fact(_ title: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .overlineStyle()
            Text(verbatim: value)
                .font(.subheadline)
        }
        .accessibilityElement(children: .combine)
    }
}
