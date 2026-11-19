import DinnertimeKit
import SwiftUI

/// Asks for amount and dates of a product that goes into the pantry.
struct PantryItemForm: View {
    let onAdd: (PantryItemDraft) async -> Bool
    let onFinish: () -> Void

    @State private var draft: PantryItemDraft
    @State private var isSaving = false

    init(product: Product, onAdd: @escaping (PantryItemDraft) async -> Bool, onFinish: @escaping () -> Void) {
        self.onAdd = onAdd
        self.onFinish = onFinish
        _draft = State(initialValue: PantryItemDraft(product: product))
    }

    var body: some View {
        PaperForm {
            Section {
                AmountField(amount: $draft.amount, unit: draft.product.baseUnit)
            }
            Section {
                OptionalDatePicker(title: "Opened", date: $draft.openedOn)
                OptionalDatePicker(title: "Set expiry date", date: $draft.expiresOn)
            } footer: {
                Text("Without an expiry date it follows from the shelf life of the product.")
            }
        }
        .navigationTitle(Text(verbatim: draft.product.name))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add", action: save)
                    .disabled(!draft.isComplete || isSaving)
            }
        }
    }

    private func save() {
        isSaving = true
        Task {
            if await onAdd(draft) {
                onFinish()
            }
            isSaving = false
        }
    }
}
