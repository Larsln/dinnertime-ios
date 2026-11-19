import DinnertimeKit
import SwiftUI

/// One planned meal as a card: cover of the recipe, meal, title, servings and whether it was cooked.
struct PlanEntryRow: View {
    private static let imageSize: CGFloat = 56

    let entry: MealPlanEntry

    var body: some View {
        HStack(spacing: 12) {
            CoverImage(url: entry.recipe.coverThumbURL ?? entry.recipe.coverURL)
                .frame(width: Self.imageSize, height: Self.imageSize)
                .clipShape(.rect(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: entry.meal.label)
                    .font(.caption2.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(entry.meal.tint)
                Text(verbatim: entry.recipe.title)
                    .font(.headline)
                    .lineLimit(2)
                Label {
                    Text("\(entry.servings) servings")
                } icon: {
                    Image(systemName: "person.2.fill")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.quaternary, in: .capsule)
            }
            Spacer(minLength: 0)
            if entry.isCooked {
                Label("Cooked", systemImage: "checkmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .font(.title3)
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 2)
    }
}

extension MealType {
    /// Color of the meal label on plan cards.
    var tint: Color {
        switch self {
        case .breakfast: .orange
        case .lunch: .teal
        case .dinner: .indigo
        case .dessert: .pink
        case .snack: .brown
        }
    }
}
