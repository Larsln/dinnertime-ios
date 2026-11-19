import DinnertimeKit
import SwiftUI

/// The seven days of a week side by side; today is highlighted and days with entries carry a dot.
struct WeekStrip: View {
    private static let circleSize: CGFloat = 34
    private static let dotSize: CGFloat = 5

    let week: Week
    /// Days that have at least one entry.
    let plannedDays: Set<DayDate>
    let onSelect: (DayDate) -> Void

    var body: some View {
        let today = DayDate(.now)
        HStack(spacing: 0) {
            ForEach(week.days, id: \.self) { day in
                Button {
                    onSelect(day)
                } label: {
                    VStack(spacing: 4) {
                        Text(verbatim: day.weekdayInitial)
                            .font(.caption2)
                            .foregroundStyle(.inkMuted)
                        Text(verbatim: day.dayNumberText)
                            .font(.callout.weight(day == today ? .bold : .regular))
                            .monospacedDigit()
                            .foregroundStyle(day == today ? Color.onAccent : Color.ink)
                            .frame(width: Self.circleSize, height: Self.circleSize)
                            .background(day == today ? Color.accent : Color.clear, in: .circle)
                        Circle()
                            .fill(.tint)
                            .frame(width: Self.dotSize, height: Self.dotSize)
                            .opacity(plannedDays.contains(day) ? 1 : 0)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: day.longText))
            }
        }
        .padding(.horizontal, 8)
    }
}
