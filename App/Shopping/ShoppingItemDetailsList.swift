import DinnertimeKit
import SwiftUI

/// What stands behind a position of the shopping list: need, leftovers, spoilage, the recipes that use it,
/// and the shops and the note of its product.
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
                        amounts(of: product)
                    }
                } footer: {
                    if item.isApproximate {
                        Text("The amount rests on an unconfirmed conversion.")
                    }
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
                    ForEach(item.uses, id: \.self) { use in
                        LabeledContent {
                            Text(verbatim: formatter.wholeString(use.amount, unit: product.baseUnit))
                        } label: {
                            Text(verbatim: use.title)
                            Text(verbatim: use.date.longText)
                        }
                    }
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
    private func amounts(of product: Product) -> some View {
        if let needed = item.neededAmount {
            LabeledContent("Needed", value: formatter.wholeString(needed, unit: product.baseUnit))
        }
        if let leftover = item.leftoverAmount, leftover > 0 {
            LabeledContent("Leftover", value: formatter.wholeString(leftover, unit: product.baseUnit))
        }
        if let wasted = item.wastedAmount, wasted > 0 {
            LabeledContent("Expires unused", value: formatter.wholeString(wasted, unit: product.baseUnit))
                .foregroundStyle(.accentDeep)
        }
    }
}
