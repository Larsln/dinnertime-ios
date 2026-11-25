import DinnertimeKit
import SwiftUI

/// The details of a position of the shopping list as a sheet, titled with the icon and the name of the item.
///
/// Settling or deleting the item closes the sheet. The sheet of an item with a product opens at full height, so that the entry of a package and the keyboard fit.
struct ShoppingItemDetails: View {
    let session: AppSession
    let item: ShoppingListItem
    let actions: ShoppingItemActions

    @State private var detent: PresentationDetent
    @Environment(\.dismiss) private var dismiss

    init(session: AppSession, item: ShoppingListItem, actions: ShoppingItemActions) {
        self.session = session
        self.item = item
        self.actions = actions
        _detent = State(initialValue: item.product == nil ? .medium : .large)
    }

    var body: some View {
        NavigationStack {
            ShoppingItemDetailsList(session: session, item: item, actions: actions.finishing { dismiss() })
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        ShoppingItemHeader(item: item)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
        .presentationDetents([.medium, .large], selection: $detent)
    }
}
