import DinnertimeKit
import SwiftUI

/// One planned meal as a card in the column of its day: the cover on top, then meal, title, servings and why
/// it goes with the rest of the plan.
///
/// A cooked meal stands back: sunken, muted and without its cover or reasons.
struct PlanBoardCard: View {
    private static let coverHeight: CGFloat = 64
    private static let coverCorner: CGFloat = 10

    let entry: MealPlanEntry
    let reasons: [PlanReason]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !entry.isCooked {
                Color.accentSoft
                    .frame(height: Self.coverHeight)
                    .overlay {
                        CoverImage(url: entry.recipe.coverThumbURL ?? entry.recipe.coverURL)
                    }
                    .clipShape(.rect(cornerRadius: Self.coverCorner, style: .continuous))
            }
            Text(verbatim: overline)
                .overlineStyle(entry.isCooked ? .inkMuted : .accentDeep)
            Text(verbatim: entry.recipe.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(entry.isCooked ? Color.inkMuted : Color.ink)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            Text("\(entry.servings) servings")
                .font(.caption)
                .foregroundStyle(.inkMuted)
            if !entry.isCooked, !reasons.isEmpty {
                PlanReasonList(reasons: reasons, lineLimit: 4)
                    .padding(.top, 2)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surface(entry.isCooked ? .sunken : .surface, in: .tile)
        .contentShape(.tile)
        .accessibilityElement(children: .combine)
    }

    /// The meal, followed by the mark of a cooked one.
    private var overline: String {
        entry.isCooked ? "\(entry.meal.label) · \(String(localized: "Cooked"))" : entry.meal.label
    }
}
