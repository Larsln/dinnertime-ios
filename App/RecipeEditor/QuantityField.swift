import DinnertimeKit
import SwiftUI

/// The quantity of an ingredient, typed as decimal or as fraction such as "1 1/2".
///
/// While the field is not edited it shows the value the way the recipe does: with fractions, or as
/// decimal for weights and volumes. Input that cannot be read leaves the value untouched and is kept
/// as `unreadable`, so that the editor can refuse to save it. The decimal pad has no slash, so the
/// common fractions stand as buttons below the field while it is edited.
struct QuantityField: View {
    private static let glyphs = ["½", "⅓", "¼", "¾"]

    @Binding var quantity: Double?
    /// What was typed and cannot be read; `nil` while the quantity is fine.
    @Binding var unreadable: String?
    let style: KitchenQuantity.Style

    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        Group {
            LabeledContent("Quantity") {
                TextField("Quantity", text: $text)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(unreadable != nil && !isFocused ? Color.accentDeep : Color.ink)
                    .focused($isFocused)
            }
            if isFocused {
                fractions
            }
        }
        .onAppear {
            text = unreadable ?? displayText
        }
        .onChange(of: text) { _, typed in
            read(typed)
        }
        .onChange(of: isFocused) { _, isFocused in
            if !isFocused {
                showStoredValue()
            }
        }
        .onChange(of: style) {
            if !isFocused {
                showStoredValue()
            }
        }
    }

    /// The common fractions as buttons that append to what is typed.
    private var fractions: some View {
        HStack {
            ForEach(Self.glyphs, id: \.self) { glyph in
                Button {
                    text += glyph
                } label: {
                    Text(verbatim: glyph)
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var displayText: String {
        quantity.map { KitchenQuantity.editable($0, style: style) } ?? ""
    }

    /// Takes over what is typed while the field is edited: nothing clears the quantity, a readable
    /// text sets it, anything else is kept as unreadable.
    private func read(_ typed: String) {
        guard isFocused else {
            return
        }
        if typed.nilIfBlank == nil {
            quantity = nil
            unreadable = nil
        } else if let parsed = KitchenQuantity.parse(typed) {
            quantity = parsed
            unreadable = nil
        } else {
            unreadable = typed
        }
    }

    /// Writes the stored value the way the recipe shows it, unless unreadable input waits for correction.
    private func showStoredValue() {
        if unreadable == nil {
            text = displayText
        }
    }
}
