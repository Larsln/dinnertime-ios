import MealplannerKit
import SwiftUI

/// Changes the amount of a pantry item.
struct EditPantryAmountView: View {
    let item: PantryItem
    let onSave: (Double, PantryItem) async -> Bool

    @State private var amount: Double?
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss

    init(item: PantryItem, onSave: @escaping (Double, PantryItem) async -> Bool) {
        self.item = item
        self.onSave = onSave
        _amount = State(initialValue: item.amount)
    }

    var body: some View {
        NavigationStack {
            Form {
                AmountField(amount: $amount, unit: item.product.baseUnit)
            }
            .navigationTitle(Text(verbatim: item.product.name))
            .navigationBarTitleDisplayMode(.inline)
            .sheetToolbar(confirm: "Save", isEnabled: (amount ?? 0) > 0 && !isSaving, onCancel: { dismiss() }, onConfirm: save)
        }
        .presentationDetents([.medium])
    }

    private func save() {
        guard let amount else {
            return
        }
        isSaving = true
        Task {
            if await onSave(amount, item) {
                dismiss()
            }
            isSaving = false
        }
    }
}
