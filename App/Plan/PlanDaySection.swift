import DinnertimeKit
import SwiftUI

/// One day of the plan: its marker at the left and its meals as cards, or a dashed row that plans one when nothing is planned.
///
/// Pressing a meal offers to change, move or remove it.
struct PlanDaySection: View {
    private static let columnSpacing: CGFloat = 12

    let day: DayDate
    let model: PlanModel
    let onAdd: () -> Void
    let onEdit: (MealPlanEntry) -> Void

    var body: some View {
        let entries = model.entries(on: day)
        Section {
            if entries.isEmpty {
                HStack(alignment: .top, spacing: Self.columnSpacing) {
                    PlanDayMarker(day: day, onAdd: nil)
                    emptyRow
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: CardRowMetrics.gap, leading: CardRowMetrics.margin, bottom: CardRowMetrics.gap, trailing: CardRowMetrics.margin))
                .listRowBackground(Color.clear)
                .id(day)
            }
            ForEach(entries) { entry in
                NavigationLink(value: entry.recipe) {
                    HStack(alignment: .center, spacing: Self.columnSpacing) {
                        if entry.id == entries.first?.id {
                            PlanDayMarker(day: day, onAdd: onAdd)
                        } else {
                            Color.clear
                                .frame(width: PlanDayMarker.width, height: 1)
                        }
                        PlanEntryRow(entry: entry, reasons: model.reasons[entry.id] ?? [])
                            .padding(.leading, CardRowMetrics.padding)
                    }
                }
                .cardRow(entry.isCooked ? .sunken : .surface, shape: .tile, leading: PlanDayMarker.width + Self.columnSpacing)
                .modifier(DayAnchor(day: entry.id == entries.first?.id ? day : nil))
                .contextMenu {
                    PlanEntryMenu(entry: entry, model: model) {
                        onEdit(entry)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        Task {
                            await model.delete(entry)
                        }
                    }
                }
                .swipeActions(edge: .leading) {
                    Button(entry.isCooked ? "Not cooked" : "Cooked", systemImage: entry.isCooked ? "arrow.uturn.backward" : "checkmark") {
                        Task {
                            await model.toggleCooked(entry)
                        }
                    }
                    .tint(.herb)
                }
            }
        }
    }

    /// The row of a day without meals: a dashed outline that plans one.
    private var emptyRow: some View {
        Button(action: onAdd) {
            Label("Plan a meal", systemImage: "plus")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.inkMuted)
                .frame(maxWidth: .infinity, minHeight: 52)
                .overlay {
                    RoundedRectangle.tile
                        .strokeBorder(.inkMuted.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                }
                .contentShape(.tile)
        }
        .buttonStyle(.borderless)
    }
}

/// Marks the first row of a day, so that the list can scroll to the day.
private struct DayAnchor: ViewModifier {
    let day: DayDate?

    func body(content: Content) -> some View {
        if let day {
            content.id(day)
        } else {
            content
        }
    }
}
