import MealplannerKit
import SwiftUI

/// A large square tile of the shopping list: tapping it checks the product off or brings it back.
///
/// The tile only names the product and what to buy; everything else is behind the info button and a long press.
struct ShoppingTile: View {
    let item: ShoppingListItem
    let onToggle: () -> Void
    let onShowDetails: () -> Void

    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 4) {
                Text(verbatim: item.title)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(2)
                if let purchase = item.purchaseText() {
                    Text(verbatim: purchase)
                        .font(.caption2)
                        .lineLimit(2)
                        .opacity(0.9)
                }
            }
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.8)
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .foregroundStyle(item.isChecked ? AnyShapeStyle(.secondary) : AnyShapeStyle(.white))
            .background(item.isChecked ? AnyShapeStyle(Color.secondary.opacity(0.15)) : AnyShapeStyle(.tint), in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(item.isChecked ? .isSelected : [])
        .overlay(alignment: .topTrailing) {
            Button("Details", systemImage: "info.circle", action: onShowDetails)
                .labelStyle(.iconOnly)
                .font(.footnote)
                .foregroundStyle(item.isChecked ? AnyShapeStyle(.secondary) : AnyShapeStyle(.white.opacity(0.85)))
                .padding(6)
        }
        .contextMenu {
            Button("Details", systemImage: "info.circle", action: onShowDetails)
        }
    }
}
