import DinnertimeKit
import SwiftUI

/// The measures of the fields and chips of an entry that is filled in on the go.
enum EntryMetrics {
    /// Smallest height of a field.
    static let fieldHeight: CGFloat = 48
    /// Smallest height of a chip.
    static let chipHeight: CGFloat = 36
    /// Space between the edge of a field and its text.
    static let fieldPadding: CGFloat = 14
}

extension View {
    /// Draws a line of input as a field: a filled, framed shape of comfortable height that takes taps anywhere on it.
    func entryField() -> some View {
        padding(.horizontal, EntryMetrics.fieldPadding)
            .frame(minHeight: EntryMetrics.fieldHeight)
            .surface(in: .field)
            .contentShape(.field)
    }
}

/// The choice of the unit a package size is stated in, as a menu behind the number; plain text when there is only one.
struct OfferUnitPicker: View {
    @Binding var unit: OfferUnit
    /// The units to choose from.
    let units: [OfferUnit]

    var body: some View {
        if units.count > 1 {
            Picker("Unit", selection: $unit) {
                ForEach(units, id: \.self) { unit in
                    Text(verbatim: unit.label)
                        .tag(unit)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .tint(.ink)
            .fixedSize()
            .padding(.trailing, -EntryMetrics.fieldPadding / 2)
        } else {
            Text(verbatim: unit.label)
                .foregroundStyle(.inkMuted)
        }
    }
}
