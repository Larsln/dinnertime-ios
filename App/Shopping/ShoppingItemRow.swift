import MealplannerKit
import SwiftUI

/// One position of the shopping list with what to buy, leftovers and the recipes that use it.
struct ShoppingItemRow: View {
    let item: ShoppingListItem
    let onToggle: () -> Void

    private let formatter = AmountFormatter()

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isChecked ? .green : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: item.title)
                        .strikethrough(item.isChecked)
                        .foregroundStyle(item.isChecked ? .secondary : .primary)
                    details
                }
            }
        }
        .tint(.primary)
    }

    @ViewBuilder
    private var details: some View {
        if let purchase = item.purchaseText(formatter: formatter) {
            Group {
                if item.isApproximate {
                    Text("approx. \(purchase)")
                } else {
                    Text(verbatim: purchase)
                }
            }
            .font(.subheadline)
        }
        if let product = item.product {
            Group {
                if let leftover = item.leftoverAmount, leftover > 0 {
                    Text("Leftover: \(formatter.string(leftover, unit: product.baseUnit))")
                }
                if let wasted = item.wastedAmount, wasted > 0 {
                    Text("Expires unused: \(formatter.string(wasted, unit: product.baseUnit))")
                        .foregroundStyle(.orange)
                }
                ForEach(item.uses, id: \.self) { use in
                    Text(verbatim: "\(use.date.weekdayText) · \(use.title) · \(formatter.string(use.amount, unit: product.baseUnit))")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
