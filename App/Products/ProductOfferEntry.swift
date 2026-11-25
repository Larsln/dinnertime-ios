import DinnertimeKit
import SwiftUI

/// The entry of a package size, stacked so that it can be filled in with one hand: where it is sold as chips,
/// the size with its unit, the price, and one button across the width.
struct ProductOfferEntry: View {
    /// The fields the entry moves between.
    private enum Field: Hashable {
        case amount, price
    }

    @Binding var draft: OfferDraft
    /// Names of the shops to choose from, preferred ones first.
    let stores: [String]
    /// The units the size can be stated in.
    let units: [OfferUnit]
    /// Sign of the currency the price is given in.
    let currencySymbol: String
    let onSave: () -> Void

    /// How strongly the button shows while there is nothing to store yet: the same button, dimmed.
    private static let dimmedOpacity = 0.4

    @FocusState private var focus: Field?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StoreChips(selection: $draft.store, stores: stores) {
                focus = .amount
            }
            field("Size", text: $draft.amount, focus: .amount) {
                OfferUnitPicker(unit: $draft.unit, units: units)
            }
            field("Price", text: $draft.price, focus: .price) {
                Text(verbatim: currencySymbol)
                    .foregroundStyle(.inkMuted)
            }
            Button {
                guard draft.isComplete else {
                    return
                }
                focus = nil
                onSave()
            } label: {
                Text(draft.offerID == nil ? "Add" : "Save")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.accent)
            .opacity(draft.isComplete ? 1 : Self.dimmedOpacity)
            .allowsHitTesting(draft.isComplete)
            .accessibilityRespondsToUserInteraction(draft.isComplete)
        }
        .padding(.vertical, 6)
    }

    /// A number field across the width with what belongs behind the number at its trailing edge; a tap anywhere on it starts typing.
    private func field(_ title: LocalizedStringKey, text: Binding<String>, focus field: Field, @ViewBuilder suffix: () -> some View) -> some View {
        HStack(spacing: 8) {
            TextField(title, text: text)
                .keyboardType(.decimalPad)
                .focused($focus, equals: field)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            suffix()
        }
        .entryField()
        .onTapGesture {
            focus = field
        }
    }
}
