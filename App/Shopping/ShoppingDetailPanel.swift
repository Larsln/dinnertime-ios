import DinnertimeKit
import SwiftUI

/// The details of the chosen position next to the shopping list on wide screens, or a hint while none is chosen.
struct ShoppingDetailPanel: View {
    /// Width of the panel.
    static let width: CGFloat = 320

    let session: AppSession
    /// The chosen item as the list holds it now.
    let item: ShoppingListItem?
    let actions: (ShoppingListItem) -> ShoppingItemActions

    var body: some View {
        Group {
            if let item {
                VStack(spacing: 0) {
                    ShoppingItemHeader(item: item)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 4)
                    ShoppingItemDetailsList(session: session, item: item, actions: actions(item))
                        .id(item.id)
                }
            } else {
                ContentUnavailableView {
                    Label("No item chosen", systemImage: "hand.tap")
                } description: {
                    Text("Tap an item to check it off. Press and hold it to see its details here.")
                }
            }
        }
        .frame(width: Self.width)
        .frame(maxHeight: .infinity)
        .panel(.paper)
    }
}
