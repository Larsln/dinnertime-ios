import DinnertimeKit
import SwiftUI

/// The recipe the round agreed on, to put on today's plan or to drop.
struct DinnerMatchView: View {
    let recipe: RecipeSummary
    let isDisabled: Bool
    let onPlan: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Match")
                    .overlineStyle(.accentDeep)
                Text("Tonight’s dinner")
                    .contentTitleStyle()
                    .accessibilityAddTraits(.isHeader)
            }
            DinnerRecipeCard(recipe: recipe)
            Button(action: onPlan) {
                Label("Plan for today", systemImage: "calendar.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Button("Discard", action: onDiscard)
        }
        .disabled(isDisabled)
    }
}
