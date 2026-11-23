import DinnertimeKit
import SwiftUI

/// One planned meal as a card: cover of the recipe, meal, title, servings, why it goes with the rest of the plan
/// and whether it was cooked.
struct PlanEntryRow: View {
    private static let imageSize: CGFloat = 56

    let entry: MealPlanEntry
    let reasons: [PlanReason]

    var body: some View {
        HStack(spacing: 12) {
            CoverImage(url: entry.recipe.coverThumbURL ?? entry.recipe.coverURL)
                .frame(width: Self.imageSize, height: Self.imageSize)
                .clipShape(.field)
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: entry.meal.label)
                    .overlineStyle(entry.isCooked ? .inkMuted : .accentDeep)
                Text(verbatim: entry.recipe.title)
                    .font(.headline)
                    .foregroundStyle(entry.isCooked ? Color.inkMuted : Color.ink)
                    .lineLimit(2)
                Label {
                    Text("\(entry.servings) servings")
                } icon: {
                    Image(systemName: "person.2.fill")
                }
                .font(.footnote)
                .foregroundStyle(.inkMuted)
                if !entry.isCooked, !reasons.isEmpty {
                    PlanReasonList(reasons: reasons)
                        .padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
            if entry.isCooked {
                Label("Cooked", systemImage: "checkmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .font(.title3)
                    .foregroundStyle(.doneMark)
            }
        }
    }
}
