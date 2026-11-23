import DinnertimeKit
import SwiftUI

/// The meal plan of one week on wide screens: its seven days as columns side by side, above a strip that leads to the shopping list.
struct PlanBoard: View {
    private static let columnSpacing: CGFloat = 10
    private static let margin: CGFloat = 20
    private static let headerWidth: CGFloat = 520

    let session: AppSession
    @Binding var week: Week
    let model: PlanModel
    /// Plans a meal on a day.
    let onAdd: (DayDate) -> Void
    /// Opens a planned meal for changes.
    let onEdit: (MealPlanEntry) -> Void
    let onShowShopping: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            PlanWeekHeader(week: $week)
                .frame(maxWidth: Self.headerWidth)
            ScrollView {
                HStack(alignment: .top, spacing: Self.columnSpacing) {
                    ForEach(week.days, id: \.self) { day in
                        PlanDayColumn(day: day, model: model, onAdd: { onAdd(day) }, onEdit: onEdit)
                    }
                }
                .padding(.horizontal, Self.margin)
                .padding(.bottom, 8)
            }
            PlanShoppingStrip(session: session, week: week, onShow: onShowShopping)
                .padding(.horizontal, Self.margin)
        }
        .padding(.vertical, 12)
        .paperScreen()
    }
}
