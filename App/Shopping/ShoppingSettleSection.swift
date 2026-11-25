import DinnertimeKit
import SwiftUI

/// The ways to settle a shopping item without buying its product: not buying it at all, or buying something
/// else in its place. A skipped item can be brought back, and a replaced one names what was bought.
struct ShoppingSettleSection: View {
    let session: AppSession
    let item: ShoppingListItem
    let actions: ShoppingItemActions

    @State private var picksSubstitute = false

    var body: some View {
        Section {
            if let substitute = item.substitute {
                LabeledContent("Bought instead", value: substitute.name)
            }
            if item.isSkipped {
                Button("Buy after all", systemImage: "arrow.uturn.backward") {
                    actions.setSkipped(false)
                }
            } else {
                Button("Bought a substitute…", systemImage: "arrow.triangle.swap") {
                    picksSubstitute = true
                }
                if !item.isChecked {
                    Button("Don't buy", systemImage: "nosign") {
                        actions.setSkipped(true)
                    }
                }
            }
        } footer: {
            if item.isSkipped {
                Text("Not bought: it does not go to the pantry and stays off the list.")
            } else if !item.isChecked {
                Text("Neither adds this product to the pantry.")
            }
        }
        .sheet(isPresented: $picksSubstitute) {
            NavigationStack {
                ProductPickerView(session: session, allowsCreation: false, onUseText: { actions.substitute(.text($0)) }) { product in
                    actions.substitute(.product(product))
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            picksSubstitute = false
                        }
                    }
                }
            }
        }
    }
}
