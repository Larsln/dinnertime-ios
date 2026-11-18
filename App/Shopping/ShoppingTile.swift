import MealplannerKit
import SwiftUI

/// A square tile of the shopping list: a line icon, the product's name and a short amount.
///
/// Tapping it checks the product off or brings it back; a short long press opens the details.
/// A small mark in the corner tells that the product carries a note.
struct ShoppingTile: View {
    let item: ShoppingListItem
    let onToggle: () -> Void
    let onShowDetails: () -> Void

    private static let pressDuration = 0.25

    @State private var detailsShown = 0

    /// A press that opens the details once it lasts long enough and checks the item off or on otherwise.
    private var press: some Gesture {
        LongPressGesture(minimumDuration: Self.pressDuration)
            .onEnded { _ in
                detailsShown += 1
                onShowDetails()
            }
            .exclusively(before: TapGesture().onEnded(onToggle))
    }

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
        .overlay(alignment: .topTrailing) {
            if item.product?.note != nil {
                Image(systemName: "note.text")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(item.isChecked ? AnyShapeStyle(.secondary) : AnyShapeStyle(.white.opacity(0.85)))
                    .padding(5)
                    .accessibilityLabel(Text("Has a note"))
            }
        }
        .contentShape(.rect(cornerRadius: 12))
        .gesture(press)
        .sensoryFeedback(.selection, trigger: item.isChecked)
        .sensoryFeedback(.impact(weight: .light), trigger: detailsShown)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(item.isChecked ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction(named: Text("Details"), onShowDetails)
    }
}
