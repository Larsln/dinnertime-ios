import DinnertimeKit
import SwiftUI

/// Weekday and day of the month at the left of a day of the plan; today stands on the accent.
///
/// On a day that already has meals the marker carries a plus and plans another one when tapped.
struct PlanDayMarker: View {
    /// Width of the column the markers stand in.
    static let width: CGFloat = 44

    let day: DayDate
    /// Plans a meal on the day; `nil` where the row next to the marker does that.
    let onAdd: (() -> Void)?

    var body: some View {
        if let onAdd {
            Button(action: onAdd) {
                label(showsPlus: true)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text("Plan a meal"))
            .accessibilityValue(Text(verbatim: day.longText))
        } else {
            label(showsPlus: false)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: day.longText))
        }
    }

    private func label(showsPlus: Bool) -> some View {
        let isToday = day == DayDate(.now)
        return VStack(spacing: 0) {
            Text(verbatim: day.weekdayText)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(isToday ? Color.onAccent : Color.inkMuted)
            Text(verbatim: day.dayNumberText)
                .brandFont(size: 22, relativeTo: .title2)
                .foregroundStyle(isToday ? Color.onAccent : Color.ink)
            if showsPlus {
                Image(systemName: "plus")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isToday ? Color.onAccent : Color.accent)
                    .padding(.top, 2)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .padding(.vertical, 8)
        .frame(width: Self.width)
        .background(isToday ? Color.accent : Color.clear, in: .tile)
    }
}
