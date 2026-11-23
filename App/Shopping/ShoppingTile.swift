import DinnertimeKit
import SwiftUI

/// A square tile of the shopping list: a line icon, the product's name and a short amount, followed by the names
/// of the products bought as it, so whoever shops sees the nuance and decides what to take.
///
/// Tapping it checks the product off or brings it back; a short long press opens the details.
/// A small mark in the corner tells that the product carries a note or a shop that sells it.
struct ShoppingTile: View {
    let item: ShoppingListItem
    /// Whether the details of the item are shown next to the list, which the tile marks with a frame.
    var isSelected = false
    let onToggle: () -> Void
    let onShowDetails: () -> Void

    private static let pressDuration = 0.25
    private static let markSize: CGFloat = 7

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

    /// The icon of the product, or a check mark once the product is checked off.
    @ViewBuilder
    private var icon: some View {
        if item.isChecked {
            Image(systemName: "checkmark")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.doneMark)
                .accessibilityHidden(true)
        } else {
            ProductIcon(key: item.product?.icon, sectionKey: item.product?.storeSection?.key)
        }
    }

    var body: some View {
        VStack(spacing: 3) {
            icon
                .frame(width: 34, height: 34)
            Text(verbatim: item.title)
                .font(.caption.weight(.semibold))
                .strikethrough(item.isChecked)
                .lineLimit(1)
            if let amount = item.shortPurchaseText() {
                Text(verbatim: amount)
                    .font(.system(size: 10))
                    .lineLimit(1)
            }
            if let variants = item.variantNamesText {
                Text(verbatim: variants)
                    .font(.system(size: 10))
                    .lineLimit(1)
                    .opacity(0.85)
            }
        }
        .minimumScaleFactor(0.8)
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .foregroundStyle(item.isChecked ? Color.doneInk : Color.onAccent)
        .background(item.isChecked ? Color.sunken : Color.accent, in: .tile)
        .overlay {
            if item.isChecked {
                RoundedRectangle.tile
                    .strokeBorder(.line)
            }
        }
        .overlay {
            if isSelected {
                RoundedRectangle.tile
                    .strokeBorder(.ink, lineWidth: 3)
            }
        }
        .overlay(alignment: .topTrailing) {
            if let product = item.product, product.hasBuyingHints {
                RoundedRectangle(cornerRadius: 2)
                    .fill(item.isChecked ? Color.doneInk : Color.onAccent)
                    .frame(width: Self.markSize, height: Self.markSize)
                    .padding(Self.markSize)
                    .accessibilityElement()
                    .accessibilityLabel(product.note == nil ? Text("Has a shop") : Text("Has a note"))
            }
        }
        .contentShape(.tile)
        .gesture(press)
        .sensoryFeedback(.selection, trigger: item.isChecked)
        .sensoryFeedback(.impact(weight: .light), trigger: detailsShown)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(item.isChecked ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction(named: Text("Details"), onShowDetails)
    }
}
