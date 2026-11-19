import DinnertimeKit
import SwiftUI

/// The title of the details of a shopping item: the icon of its product on the accent and its name.
struct ShoppingItemHeader: View {
    private static let chipSize: CGFloat = 36
    private static let iconSize: CGFloat = 24

    let item: ShoppingListItem

    var body: some View {
        HStack(spacing: 10) {
            ProductIcon(key: item.product?.icon, sectionKey: item.product?.storeSection?.key)
                .frame(width: Self.iconSize, height: Self.iconSize)
                .foregroundStyle(.onAccent)
                .frame(width: Self.chipSize, height: Self.chipSize)
                .background(.accent, in: .field)
                .accessibilityHidden(true)
            Text(verbatim: item.title)
                .brandFont(size: 20, relativeTo: .title3)
                .foregroundStyle(.ink)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
        }
    }
}
