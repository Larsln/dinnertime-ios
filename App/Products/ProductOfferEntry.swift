import MealplannerKit
import SwiftUI

/// The fast entry of an offer: the shop as chips, size and price side by side and one button.
struct ProductOfferEntry: View {
    /// The fields the entry moves between.
    private enum Field: Hashable {
        case amount, price
    }

    @Binding var draft: OfferDraft
    /// Names of the known shops, most used first.
    let stores: [String]
    /// Unit the size is given in.
    let unit: BaseUnit
    /// Sign of the currency the price is given in.
    let currencySymbol: String
    let onSave: () -> Void

    @FocusState private var focus: Field?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StoreChips(selection: $draft.store, stores: stores) {
                focus = .amount
            }
            HStack(spacing: 8) {
                field("Size", text: $draft.amount, suffix: unit.label, keyboard: .numberPad, focus: .amount)
                field("Price", text: $draft.price, suffix: currencySymbol, keyboard: .decimalPad, focus: .price)
                Button(draft.offerID == nil ? "Add" : "Save") {
                    focus = nil
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!draft.isComplete)
            }
        }
        .padding(.vertical, 2)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                if focus != nil {
                    Spacer()
                    Button("Done") {
                        focus = nil
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func field(_ title: LocalizedStringKey, text: Binding<String>, suffix: String, keyboard: UIKeyboardType, focus field: Field) -> some View {
        HStack(spacing: 4) {
            TextField(title, text: text)
                .keyboardType(keyboard)
                .focused($focus, equals: field)
                .multilineTextAlignment(.trailing)
            Text(verbatim: suffix)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.secondary.opacity(0.12), in: .rect(cornerRadius: 8))
    }
}
