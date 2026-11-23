import DinnertimeKit
import SwiftUI

/// What stands behind a position of the shopping list: need, leftovers, spoilage, the recipes that use it,
/// the same for every product bought as it, and the shops and the note of its product.
///
/// The note is stored when it is submitted and when the list goes away.
struct ShoppingItemDetailsList: View {
    let item: ShoppingListItem
    /// Deletes the item; `nil` for items that come from the plan.
    let onDelete: (() -> Void)?
    /// Stores the note of the item's product; `nil` clears it.
    let onSaveNote: (String?) -> Void

    @State private var note: String
    @State private var savedNote: String?
    @State private var offers: ProductOffersModel?

    private let formatter = AmountFormatter()

    init(session: AppSession, item: ShoppingListItem, onDelete: (() -> Void)?, onSaveNote: @escaping (String?) -> Void) {
        self.item = item
        self.onDelete = onDelete
        self.onSaveNote = onSaveNote
        _note = State(initialValue: item.product?.note ?? "")
        _savedNote = State(initialValue: item.product?.note)
        _offers = State(initialValue: item.product.map { ProductOffersModel(session: session, product: $0) })
    }

    var body: some View {
        PaperList {
            if let purchase = item.purchaseText(formatter: formatter) {
                Section {
                    LabeledContent("To buy", value: purchase)
                    if let product = item.product {
                        amounts(of: item, unit: product.baseUnit)
                    }
                } footer: {
                    if item.isApproximate {
                        Text("The amount rests on an unconfirmed conversion.")
                    }
                }
            }
            ForEach(item.variants) { variant in
                Section(variant.name) {
                    if let purchase = variant.purchaseText(unit: variant.baseUnit, isApproximate: item.isApproximate, formatter: formatter) {
                        LabeledContent("To buy", value: purchase)
                    }
                    amounts(of: variant, unit: variant.baseUnit)
                    uses(of: variant, unit: variant.baseUnit)
                }
            }
            if let product = item.product, let offers {
                ProductOffersSection(model: offers, unit: product.baseUnit)
            }
            if item.product != nil {
                Section("Note") {
                    ProductNoteField(text: $note)
                        .onSubmit(saveNote)
                }
            }
            if let product = item.product, !item.uses.isEmpty {
                Section("Used for") {
                    uses(of: item, unit: product.baseUnit)
                }
            }
            if let onDelete {
                Section {
                    Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                }
            }
        }
        .onDisappear(perform: saveNote)
    }

    /// Stores the note if it differs from what was stored last.
    private func saveNote() {
        let edited = Product.storedNote(note)
        guard item.product != nil, edited != savedNote else {
            return
        }
        savedNote = edited
        onSaveNote(edited)
    }

    @ViewBuilder
    private func amounts(of amounts: some ShoppingAmounts, unit: BaseUnit) -> some View {
        if let needed = amounts.neededAmount {
            LabeledContent("Needed", value: formatter.wholeString(needed, unit: unit))
        }
        if let leftover = amounts.leftoverAmount, leftover > 0 {
            LabeledContent("Leftover", value: formatter.wholeString(leftover, unit: unit))
        }
        if let wasted = amounts.wastedAmount, wasted > 0 {
            LabeledContent("Expires unused", value: formatter.wholeString(wasted, unit: unit))
                .foregroundStyle(.accentDeep)
        }
    }

    /// The recipes that use the product, each with its day and amount.
    private func uses(of amounts: some ShoppingAmounts, unit: BaseUnit) -> some View {
        ForEach(amounts.uses, id: \.self) { use in
            LabeledContent {
                Text(verbatim: formatter.wholeString(use.amount, unit: unit))
            } label: {
                Text(verbatim: use.title)
                Text(verbatim: use.date.longText)
            }
        }
    }
}
