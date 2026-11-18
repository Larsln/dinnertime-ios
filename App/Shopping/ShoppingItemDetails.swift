import MealplannerKit
import SwiftUI

/// What stands behind a position of the shopping list: need, leftovers, spoilage and the recipes that use it.
struct ShoppingItemDetails: View {
    let item: ShoppingListItem
    /// Deletes the item; `nil` for items that come from the plan.
    let onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    private let formatter = AmountFormatter()

    var body: some View {
        NavigationStack {
            List {
                if let purchase = item.purchaseText(formatter: formatter) {
                    Section {
                        LabeledContent("To buy", value: purchase)
                        if let product = item.product {
                            amounts(of: product)
                        }
                    } footer: {
                        if item.isApproximate {
                            Text("The amount rests on an unconfirmed conversion.")
                        }
                    }
                }
                if let product = item.product, !item.uses.isEmpty {
                    Section("Used for") {
                        ForEach(item.uses, id: \.self) { use in
                            LabeledContent {
                                Text(verbatim: formatter.string(use.amount, unit: product.baseUnit))
                            } label: {
                                Text(verbatim: use.title)
                                Text(verbatim: use.date.longText)
                            }
                        }
                    }
                }
                if let onDelete {
                    Section {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            onDelete()
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(Text(verbatim: item.title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private func amounts(of product: Product) -> some View {
        if let needed = item.neededAmount {
            LabeledContent("Needed", value: formatter.string(needed, unit: product.baseUnit))
        }
        if let leftover = item.leftoverAmount, leftover > 0 {
            LabeledContent("Leftover", value: formatter.string(leftover, unit: product.baseUnit))
        }
        if let wasted = item.wastedAmount, wasted > 0 {
            LabeledContent("Expires unused", value: formatter.string(wasted, unit: product.baseUnit))
                .foregroundStyle(.orange)
        }
    }
}
