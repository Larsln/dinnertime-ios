import MealplannerKit
import SwiftUI

/// Shows the selected week and steps to the previous or next one.
struct WeekSwitcher: View {
    @Binding var week: Week

    var body: some View {
        HStack {
            Button("Previous week", systemImage: "chevron.left") {
                week = week.shifted(byWeeks: -1)
            }
            Spacer()
            Text(verbatim: week.rangeText)
                .font(.headline)
            Spacer()
            Button("Next week", systemImage: "chevron.right") {
                week = week.shifted(byWeeks: 1)
            }
        }
        .labelStyle(.iconOnly)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
}
