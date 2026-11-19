import DinnertimeKit
import SwiftUI

/// Shows the calendar week with its range, steps to the neighboring weeks and returns to the current one.
struct PlanWeekHeader: View {
    @Binding var week: Week

    var body: some View {
        HStack {
            Button("Previous week", systemImage: "chevron.left") {
                week = week.shifted(byWeeks: -1)
            }
            .labelStyle(.iconOnly)
            Spacer()
            VStack(spacing: 2) {
                Text(verbatim: week.titleText)
                    .font(.headline)
                if !week.isCurrent {
                    Button("Current week") {
                        week = Week(containing: .now)
                    }
                    .font(.caption)
                }
            }
            Spacer()
            Button("Next week", systemImage: "chevron.right") {
                week = week.shifted(byWeeks: 1)
            }
            .labelStyle(.iconOnly)
        }
        .padding(.horizontal)
    }
}
