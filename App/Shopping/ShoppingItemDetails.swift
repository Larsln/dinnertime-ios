import DinnertimeKit
import SwiftUI

/// The details of a position of the shopping list as a sheet, titled with the icon and the name of the item.
struct ShoppingItemDetails: View {
    let session: AppSession
    let item: ShoppingListItem
    /// Deletes the item; `nil` for items that come from the plan.
    let onDelete: (() -> Void)?
    /// Stores the note of the item's product; `nil` clears it.
    let onSaveNote: (String?) -> Void

    @Environment(\.dismiss) private var dismiss

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
        .presentationDetents([.medium, .large])
    }

    /// Deletes the item and closes the sheet.
    private func deletion(_ delete: @escaping () -> Void) -> () -> Void {
        {
            delete()
            dismiss()
        }
    }
}
