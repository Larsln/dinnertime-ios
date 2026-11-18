import MealplannerKit
import SwiftUI

/// Name, store section, base unit, shelf life and pantry staple mark of a product.
struct ProductDetailsSection: View {
    @Binding var draft: ProductDraft
    let storeSections: [StoreSection]

    var body: some View {
        Section {
            LabeledContent("Name") {
                TextField("Name", text: $draft.name)
                    .multilineTextAlignment(.trailing)
            }
            Picker("Store section", selection: $draft.storeSectionID) {
                Text("No section")
                    .tag(Int?.none)
                ForEach(storeSections) { section in
                    Text(verbatim: section.name)
                        .tag(Int?.some(section.id))
                }
            }
            Picker("Bought in", selection: $draft.baseUnit) {
                ForEach(BaseUnit.allCases, id: \.self) { unit in
                    Text(verbatim: unit.name)
                }
            }
            NumberField(title: "Shelf life once opened (days)", value: $draft.shelfLife)
            Toggle("Always in stock, never on the shopping list", isOn: $draft.isPantryStaple)
        }
    }
}
