import DinnertimeKit
import SwiftUI

/// The days of a week as rows and the meals as columns, each cell a slot that can be selected.
struct SlotMatrix: View {
    private static let cellHeight: CGFloat = 40

    @Binding var selection: MealSlotSelection

    var body: some View {
        Grid(horizontalSpacing: 4, verticalSpacing: 4) {
            GridRow {
                Color.clear
                    .gridCellUnsizedAxes([.horizontal, .vertical])
                ForEach(selection.meals, id: \.self) { meal in
                    Text(verbatim: meal.label)
                        .font(.caption2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity)
                }
            }
            ForEach(selection.days, id: \.self) { day in
                GridRow {
                    Text(verbatim: day.weekdayDayText)
                        .font(.footnote)
                        .monospacedDigit()
                        .gridColumnAlignment(.leading)
                    ForEach(selection.meals, id: \.self) { meal in
                        cell(MealSlot(date: day, meal: meal))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cell(_ slot: MealSlot) -> some View {
        let isSelected = selection.selected.contains(slot)
        if selection.isOpen(slot) {
            Button {
                selection.toggle(slot)
            } label: {
                Image(systemName: "checkmark")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.onAccent)
                    .opacity(isSelected ? 1 : 0)
                    .frame(maxWidth: .infinity, minHeight: Self.cellHeight)
                    .background(isSelected ? Color.accent : Color.sunken, in: .field)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text(verbatim: "\(slot.date.weekdayDayText), \(slot.meal.label)"))
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        } else {
            Text("planned")
                .font(.caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(.inkMuted)
                .frame(maxWidth: .infinity, minHeight: Self.cellHeight)
                .overlay {
                    RoundedRectangle.field
                        .strokeBorder(.line)
                }
        }
    }
}
