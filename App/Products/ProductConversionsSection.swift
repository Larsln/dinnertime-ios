import MealplannerKit
import SwiftUI

/// The unit conversions of a product, which can be set, marked as impossible and removed.
struct ProductConversionsSection: View {
    @Binding var draft: ProductDraft
    /// Units that have no conversion yet.
    let addableUnits: [MeasureUnit]

    var body: some View {
        Section("Conversions (\(draft.baseUnit.name))") {
            ForEach($draft.conversions) { $conversion in
                VStack(spacing: 8) {
                    LabeledContent {
                        TextField(draft.baseUnit.label, value: $conversion.amount, format: .number)
                            .numericKeyboard(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .disabled(!conversion.isConvertible)
                            .opacity(conversion.isConvertible ? 1 : 0.4)
                    } label: {
                        Text(verbatim: "1 \(conversion.unit.name) =")
                    }
                    Toggle("Cannot be converted", isOn: Binding(
                        get: { !conversion.isConvertible },
                        set: { conversion.isConvertible = !$0 }
                    ))
                    .font(.subheadline)
                }
            }
            .onDelete { offsets in
                draft.conversions.remove(atOffsets: offsets)
            }
            if !addableUnits.isEmpty {
                Menu {
                    ForEach(addableUnits) { unit in
                        Button {
                            draft.conversions.append(ProductDraft.Conversion(unit: unit))
                        } label: {
                            Text(verbatim: unit.name)
                        }
                    }
                } label: {
                    Label("Add unit", systemImage: "plus")
                }
            }
        }
    }
}
