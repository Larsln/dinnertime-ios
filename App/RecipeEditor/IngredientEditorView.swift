import MealplannerKit
import SwiftUI

/// Edits one ingredient line: its product or free text, amount, note and estimate mark.
struct IngredientEditorView: View {
    @Binding var line: IngredientDraft
    let units: [MeasureUnit]
    let session: AppSession

    var body: some View {
        Form {
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
                LabeledContent("Quantity") {
                    TextField("Quantity", value: $line.quantity, format: .number)
                        .numericKeyboard(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                Picker("Unit", selection: $line.unitID) {
                    Text("pieces")
                        .tag(Int?.none)
                    ForEach(units) { unit in
                        Text(verbatim: unit.code ?? unit.name)
                            .tag(Int?.some(unit.id))
                    }
                }
                Toggle("Quantity estimated", isOn: $line.isEstimated)
            }
            Section {
                TextField("Note", text: $line.note)
            }
        }
        .navigationTitle("Ingredient")
        .navigationBarTitleDisplayMode(.inline)
    }
}
