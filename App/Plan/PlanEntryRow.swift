import MealplannerKit
import SwiftUI

/// One planned meal with its recipe and servings.
struct PlanEntryRow: View {
    let entry: MealPlanEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: entry.meal.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(verbatim: entry.recipe.title)
                Text("Servings: \(entry.servings)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if entry.isCooked {
                Label("Cooked", systemImage: "checkmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.green)
            }
        }
    }
}
