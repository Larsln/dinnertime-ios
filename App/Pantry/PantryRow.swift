import DinnertimeKit
import SwiftUI

/// One pantry item with its amount and dates.
struct PantryRow: View {
    let item: PantryItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: item.product.name)
                if let openedOn = item.openedOn {
                    Text("Opened: \(openedOn.shortText)")
                        .font(.caption)
                        .foregroundStyle(.inkMuted)
                }
                if let expiresOn = item.expiresOn {
                    Text("Expires: \(expiresOn.shortText)")
                        .font(.caption)
                        .foregroundStyle(expiresOn < DayDate(.now) ? Color.accentDeep : Color.inkMuted)
                }
            }
            Spacer()
            Text(verbatim: AmountFormatter().wholeString(item.amount, unit: item.product.baseUnit))
                .monospacedDigit()
        }
    }
}
