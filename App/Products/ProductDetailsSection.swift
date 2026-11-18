import MealplannerKit
import SwiftUI

/// Name, icon, store section, base unit, shelf life and pantry staple mark of a product.
struct ProductDetailsSection: View {
    @Binding var draft: ProductDraft
    let storeSections: [StoreSection]

    @State private var picksIcon = false

    var body: some View {
        Section {
            LabeledContent("Name") {
                TextField("Name", text: $draft.name)
                    .multilineTextAlignment(.trailing)
            }
            Button {
                picksIcon = true
            } label: {
                LabeledContent("Icon on the shopping list") {
                    ProductIcon(key: draft.icon, sectionKey: sectionKey)
                        .frame(width: 28, height: 28)
                        .foregroundStyle(.tint)
                }
            }
            .foregroundStyle(.primary)
            .sheet(isPresented: $picksIcon) {
                IconPickerView(selection: $draft.icon, sectionKey: sectionKey)
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

    /// Key of the chosen store section, whose icon stands in for a product without one.
    private var sectionKey: String? {
        storeSections.first { $0.id == draft.storeSectionID }?.key
    }
}
