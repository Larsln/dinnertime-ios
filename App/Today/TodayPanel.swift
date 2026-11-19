import DinnertimeKit
import SwiftUI

/// The rows at the top of the recipes: the way to decide tonight's dinner while nothing is planned for today,
/// and the next meal to cook, with a small way to decide together even when today is planned.
struct TodayPanel: View {
    let model: TodayModel
    /// Opens the recipe of the next meal with the planned servings.
    let onOpen: (PlannedRecipe) -> Void
    /// Opens the dinner round, or the start of one.
    let onDecide: () -> Void

    @Environment(OfflineCoordinator.self) private var offline

    var body: some View {
        if showsPrompt {
            DinnerPrompt(round: model.dinner.round, phase: model.dinner.phase, isOnline: offline.isOnline, onOpen: onDecide)
                .todayRow()
        }
        if let entry = model.upNext {
            Button {
                onOpen(PlannedRecipe(entry))
            } label: {
                UpNextBanner(entry: entry, today: model.today)
            }
            .buttonStyle(.plain)
            .todayRow()
        }
        if showsShortcut {
            Button("Rather something else? Decide together", systemImage: "rectangle.stack", action: onDecide)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.accentDeep)
                .disabled(!offline.isOnline)
                .todayRow()
        }
    }

    /// Whether today has no entry at all, or a round is running, and it is known whether one is, or the server is away.
    private var showsPrompt: Bool {
        (model.isTodayOpen || model.dinner.round != nil) && (model.dinner.hasLoaded || !offline.isOnline)
    }

    /// Whether today is planned and no round runs, so deciding together is only offered as a small way out.
    private var showsShortcut: Bool {
        !showsPrompt && model.dinner.hasLoaded && offline.isOnline
    }
}

private extension View {
    /// Draws a row without the background and the separator of the list, at the margins of the cards.
    func todayRow() -> some View {
        listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: CardRowMetrics.gap, leading: CardRowMetrics.margin, bottom: CardRowMetrics.gap, trailing: CardRowMetrics.margin))
    }
}
