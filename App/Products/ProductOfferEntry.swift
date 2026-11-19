import DinnertimeKit
import SwiftUI

/// The fast entry of an offer: the shop as chips, size with its unit and price side by side and one button.
struct ProductOfferEntry: View {
    /// The fields the entry moves between.
    private enum Field: Hashable {
        case amount, price
    }

    @Binding var draft: OfferDraft
    /// Names of the shops to choose from, most used first.
    let stores: [String]
    /// Sign of the currency the price is given in.
    let currencySymbol: String
    let onSave: () -> Void

    @FocusState private var focus: Field?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StoreChips(selection: $draft.store, stores: stores) {
                focus = .amount
            }
            HStack(spacing: 6) {
                field("Size", text: $draft.amount, focus: .amount) {
                    unitPicker
                }
                field("Price", text: $draft.price, focus: .price) {
                    Text(verbatim: currencySymbol)
                        .foregroundStyle(.inkMuted)
                        .padding(.trailing, 8)
                }
                Button(draft.offerID == nil ? "Add" : "Save") {
                    focus = nil
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .fixedSize()
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

    /// The choice of the unit the size is stated in, as a menu right behind the number.
    private var unitPicker: some View {
        Picker("Unit", selection: $draft.unit) {
            ForEach(OfferUnit.allCases, id: \.self) { unit in
                Text(verbatim: unit.label)
                    .tag(unit)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .tint(.ink)
        .fixedSize()
    }

    private func field(_ title: LocalizedStringKey, text: Binding<String>, focus field: Field, @ViewBuilder suffix: () -> some View) -> some View {
        HStack(spacing: 0) {
            TextField(title, text: text)
                .keyboardType(.decimalPad)
                .focused($focus, equals: field)
                .multilineTextAlignment(.trailing)
                .padding(.leading, 8)
                .padding(.trailing, 4)
                .padding(.vertical, 9)
            suffix()
        }
        .surface(in: .field)
    }
}
