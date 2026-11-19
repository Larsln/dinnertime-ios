import DinnertimeKit
import SwiftUI

/// Edits one ingredient line: its product or free text, amount, note and estimate mark.
struct IngredientEditorView: View {
    @Binding var line: IngredientDraft
    let units: [MeasureUnit]
    let session: AppSession

    var body: some View {
        PaperForm {
            Section {
                NavigationLink {
                    ProductPickerView(session: session, allowsCreation: true) { product in
                        line.product = product
                    }
                } label: {
                    LabeledContent("Product", value: line.product?.name ?? String(localized: "Choose"))
                }
                if line.product == nil {
                    TextField("or free text", text: $line.rawText)
                } else {
                    Button("Remove product", role: .destructive) {
                        line.product = nil
                    }
                }
            }
            Section {
                QuantityField(quantity: $line.quantity, unreadable: $line.unreadableQuantity, style: unit.quantityStyle)
                Picker("Unit", selection: $line.unitID) {
                    Text("pieces")
                        .tag(Int?.none)
                    ForEach(units) { unit in
                        Text(verbatim: unit.code ?? unit.name)
                            .tag(Int?.some(unit.id))
                    }
                }
                Toggle("Quantity estimated", isOn: $line.isEstimated)
                    .tint(.herb)
            } footer: {
                if line.unreadableQuantity != nil {
                    Text("Quantity not readable. Allowed are e.g. 2, 1.5, 1/2 or 1 1/2.")
                        .foregroundStyle(.accentDeep)
                }
            }
            Section {
                TextField("Note", text: $line.note)
            }
        }
        .navigationTitle("Ingredient")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// The chosen unit; `nil` while the line counts pieces.
    private var unit: MeasureUnit? {
        units.first { $0.id == line.unitID }
    }
}
