import DinnertimeKit
import SwiftUI

/// The details of a position of the shopping list as a sheet, titled with the icon and the name of the item.
///
/// The sheet of an item with a product opens at full height, so that the entry of a package and the keyboard fit.
struct ShoppingItemDetails: View {
    let session: AppSession
    let item: ShoppingListItem
    /// Deletes the item; `nil` for items that come from the plan.
    let onDelete: (() -> Void)?
    /// Stores the note of the item's product; `nil` clears it.
    let onSaveNote: (String?) -> Void

    @State private var detent: PresentationDetent
    @Environment(\.dismiss) private var dismiss

    init(session: AppSession, item: ShoppingListItem, onDelete: (() -> Void)?, onSaveNote: @escaping (String?) -> Void) {
        self.session = session
        self.item = item
        self.onDelete = onDelete
        self.onSaveNote = onSaveNote
        _detent = State(initialValue: item.product == nil ? .medium : .large)
    }

    var body: some View {
        NavigationStack {
            ShoppingItemDetailsList(session: session, item: item, onDelete: onDelete.map(deletion), onSaveNote: onSaveNote)
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

    /// Deletes the item and closes the sheet.
    private func deletion(_ delete: @escaping () -> Void) -> () -> Void {
        {
            delete()
            dismiss()
        }
    }
}
