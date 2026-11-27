import DinnertimeKit
import SwiftUI

/// The sides of a planned meal as small rows below it in the list of a day.
///
/// A row opens the recipe with the portions of the side. Pressing it offers to rate the portion or to remove the side.
struct PlanSideRows: View {
    private static let columnSpacing: CGFloat = 12

    let entry: MealPlanEntry
    let model: PlanModel

    var body: some View {
        ForEach(model.sides(of: entry)) { side in
            NavigationLink(value: PlannedRecipe(side)) {
                HStack(spacing: Self.columnSpacing) {
                    Color.clear
                        .frame(width: PlanDayMarker.width, height: 1)
                    PlanSideLabel(side: side, verdict: model.ownVerdict(on: side))
                        .padding(.leading, CardRowMetrics.padding)
                }
            }
            .cardRow(side.isCooked ? .sunken : .surface, shape: .tile, leading: PlanDayMarker.width + Self.columnSpacing)
            .contextMenu {
                PlanSideMenu(side: side, model: model)
            }
            .swipeActions(edge: .trailing) {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    Task {
                        await model.delete(side)
                    }
                }
            }
        }
    }
}

/// The sides of a planned meal as small cards below it in the column of a day.
struct PlanSideCards: View {
    let entry: MealPlanEntry
    let model: PlanModel

    var body: some View {
        ForEach(model.sides(of: entry)) { side in
            NavigationLink(value: PlannedRecipe(side)) {
                PlanSideLabel(side: side, verdict: model.ownVerdict(on: side))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .surface(side.isCooked ? .sunken : .surface, in: .tile)
                    .contentShape(.tile)
                    .accessibilityElement(children: .combine)
            }
            .buttonStyle(.plain)
            .contextMenu {
                PlanSideMenu(side: side, model: model)
            }
        }
    }
}

/// What a side shows: that it goes with the meal above, its title, its portions and what the user said about them.
struct PlanSideLabel: View {
    let side: MealPlanEntry
    var verdict: PortionVerdict?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("With it: \(side.recipe.title)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(side.isCooked ? Color.inkMuted : Color.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            PortionsText(entry: side)
                .font(.caption)
                .foregroundStyle(.inkMuted)
            PortionVerdictNote(verdict: verdict)
        }
    }
}

/// What can be done with a side: say how its portion was or remove it. Shown as the context menu of a side.
struct PlanSideMenu: View {
    let side: MealPlanEntry
    let model: PlanModel

    var body: some View {
        PortionVerdictMenu(entry: side, model: model)
        Button("Delete", systemImage: "trash", role: .destructive) {
            Task {
                await model.delete(side)
            }
        }
    }
}
