import DinnertimeKit
import SwiftUI

/// A strip below the week that tells how far the shopping for it is and leads to the shopping list.
struct PlanShoppingStrip: View {
    let session: AppSession
    let week: Week
    let onShow: () -> Void

    /// The current shopping list; `nil` while there is none or it is not read yet.
    @State private var list: ShoppingList?

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Shopping for the week")
                    .font(.headline)
                    .foregroundStyle(.ink)
                Text(verbatim: summary)
                    .font(.subheadline)
                    .foregroundStyle(.inkMuted)
            }
            Spacer(minLength: 0)
            Button("To the shopping list", action: onShow)
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .surface()
        .task(id: week) {
            await load()
        }
        .reloadsOnChange(of: .shopping) {
            await load()
        }
    }

    /// How many products are left to buy, when the current list was made for the week.
    private var summary: String {
        guard let list, list.startsOn == week.start, list.endsOn == week.end else {
            return String(localized: "No list for this week yet.")
        }
        let done = list.settledItems.count
        return String(localized: "\(list.items.count - done) to buy, \(done) done")
    }

    private func load() async {
        list = try? await session.send(ShoppingEndpoints.current)
    }
}
