import MealplannerKit
import SwiftUI

/// Input for an amount of a product in its base unit.
struct AmountField: View {
    @Binding var amount: Double?
    let unit: BaseUnit

    var body: some View {
        LabeledContent("Amount") {
            HStack {
                TextField("Amount", value: $amount, format: .number)
                    .numericKeyboard(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text(verbatim: unit.label)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
