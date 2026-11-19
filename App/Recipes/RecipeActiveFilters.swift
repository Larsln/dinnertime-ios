import DinnertimeKit
import SwiftUI

/// The filters that are switched on, as a row of chips that scrolls sideways; a chip takes its filter away,
/// and with several of them a button takes all away.
struct RecipeActiveFilters: View {
    let model: RecipeListModel

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(model.activeFilters) { filter in
                    RemovableChip(name: filter.name.map(Text.init(verbatim:)) ?? Text("Favorites only")) {
                        model.remove(filter)
                    }
                }
                if model.activeFilters.count > 1 {
                    Button("Remove all") {
                        model.query.resetFilters()
                    }
                    .font(.subheadline)
                    .buttonStyle(.borderless)
                    .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, CardRowMetrics.margin)
        }
        .scrollIndicators(.hidden)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: CardRowMetrics.gap, leading: 0, bottom: CardRowMetrics.gap, trailing: 0))
    }
}

/// The toolbar button that opens the filters; it is filled and counts them while some are switched on.
struct RecipeFilterButton: View {
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Filter", systemImage: count > 0 ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
        .badge(count)
        .accessibilityValue(count > 0 ? Text(verbatim: String(count)) : Text(verbatim: ""))
    }
}

/// What the list shows in place of recipes when there are none: a way back out of the filters, or the hint to import.
struct RecipeEmptyRow: View {
    let isNarrowed: Bool
    /// Switches the filters off and empties the search.
    let onReset: () -> Void

    var body: some View {
        Group {
            if isNarrowed {
                ContentUnavailableView {
                    Label("No recipes with these filters", systemImage: "line.3.horizontal.decrease.circle")
                } actions: {
                    Button("Reset filters", action: onReset)
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 8)
                }
            } else {
                ContentUnavailableView("No recipes", systemImage: "book", description: Text("Import a recipe from a link or change the search."))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}
