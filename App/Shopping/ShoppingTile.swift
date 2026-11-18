import MealplannerKit
import SwiftUI

/// A square tile of the shopping list: a line icon, the product's name and a short amount.
///
/// Tapping it checks the product off or brings it back; a long press opens the details.
struct ShoppingTile: View {
    let item: ShoppingListItem
    let onToggle: () -> Void
    let onShowDetails: () -> Void

    var body: some View {
        VStack(spacing: 3) {
            ProductIcon(key: item.product?.icon, sectionKey: item.product?.storeSection?.key)
                .frame(width: 34, height: 34)
            Text(verbatim: item.title)
                .font(.caption.weight(.medium))
                .lineLimit(1)
            if let amount = item.shortPurchaseText() {
                Text(verbatim: item.isApproximate ? "\(amount) ≈" : amount)
                    .font(.system(size: 10))
                    .lineLimit(1)
                    .opacity(0.75)
            }
        }
        .minimumScaleFactor(0.8)
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .foregroundStyle(item.isChecked ? AnyShapeStyle(.secondary) : AnyShapeStyle(.white))
        .background(item.isChecked ? AnyShapeStyle(Color.secondary.opacity(0.15)) : AnyShapeStyle(.tint), in: .rect(cornerRadius: 12))
        .contentShape(.rect(cornerRadius: 12))
        .onTapGesture(perform: onToggle)
        .onLongPressGesture(perform: onShowDetails)
        .sensoryFeedback(.selection, trigger: item.isChecked)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(item.isChecked ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction(named: Text("Details"), onShowDetails)
    }
}
