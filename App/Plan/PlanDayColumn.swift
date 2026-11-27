import DinnertimeKit
import SwiftUI

/// One day of the plan as a column: weekday and date at the top, its meals as cards below, or a dashed cell that plans one.
///
/// Pressing a meal offers to change, move or remove it; the menu of the day moves the plan from that day on.
struct PlanDayColumn: View {
    private static let cellHeight: CGFloat = 64

    let day: DayDate
    let model: PlanModel
    let onAdd: () -> Void
    let onEdit: (MealPlanEntry) -> Void
    /// Opens the side picker for a meal.
    let onAddSide: (MealPlanEntry) -> Void

    var body: some View {
        let entries = model.entries(on: day)
        VStack(alignment: .leading, spacing: 8) {
            header(showsPlus: !entries.isEmpty)
            ForEach(entries) { entry in
                NavigationLink(value: entry.recipe) {
                    PlanBoardCard(entry: entry, reasons: model.reasons[entry.id] ?? [], verdict: model.ownVerdict(on: entry))
                }
                .buttonStyle(.plain)
                .contextMenu {
                    PlanEntryMenu(entry: entry, model: model) {
                        onEdit(entry)
                    } onAddSide: {
                        onAddSide(entry)
                    }
                }
                PlanSideCards(entry: entry, model: model)
            }
            if entries.isEmpty {
                addCell
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    /// Weekday and day of the month, today on the accent; on a day with meals a plus plans another one.
    private func header(showsPlus: Bool) -> some View {
        let isToday = day == DayDate(.now)
        return HStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(verbatim: day.weekdayText)
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(isToday ? Color.onAccent : Color.inkMuted)
                Text(verbatim: day.dayNumberText)
                    .brandFont(size: 20, relativeTo: .title3)
                    .foregroundStyle(isToday ? Color.onAccent : Color.ink)
            }
            .lineLimit(1)
            .padding(.horizontal, isToday ? 10 : 4)
            .padding(.vertical, 2)
            .background(isToday ? Color.accent : Color.clear, in: .capsule)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: day.longText))
            .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            Menu("Move the plan", systemImage: "ellipsis") {
                PlanShiftButtons(day: day, model: model)
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .accessibilityValue(Text(verbatim: day.longText))
            if showsPlus {
                Button("Plan a meal", systemImage: "plus", action: onAdd)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .accessibilityValue(Text(verbatim: day.longText))
            }
        }
        .frame(minHeight: 32)
    }

    /// The cell of a day without meals: a dashed outline that plans one.
    private var addCell: some View {
        Button(action: onAdd) {
            Image(systemName: "plus")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.inkMuted)
                .frame(maxWidth: .infinity, minHeight: Self.cellHeight)
                .overlay {
                    RoundedRectangle.tile
                        .strokeBorder(.inkMuted.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                }
                .contentShape(.tile)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(Text("Plan a meal"))
        .accessibilityValue(Text(verbatim: day.longText))
    }
}
