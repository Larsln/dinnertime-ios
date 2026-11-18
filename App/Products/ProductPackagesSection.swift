import MealplannerKit
import SwiftUI

/// The package sizes of a product, which can be added, corrected and removed.
struct ProductPackagesSection: View {
    @Binding var draft: ProductDraft

    var body: some View {
        Section("Package sizes (\(draft.baseUnit.name))") {
            ForEach($draft.packages) { $package in
                HStack {
                    TextField("Label, e.g. tub", text: $package.label)
                    TextField(draft.baseUnit.label, value: $package.amount, format: .number)
                        .numericKeyboard(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                }
            }
            .onDelete { offsets in
                draft.packages.remove(atOffsets: offsets)
            }
            Button("Add package", systemImage: "plus") {
                draft.packages.append(ProductDraft.Package())
            }
        }
    }
}
