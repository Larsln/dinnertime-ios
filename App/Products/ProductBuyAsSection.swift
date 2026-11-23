import DinnertimeKit
import SwiftUI

/// Chooses the product another one is bought as, such as onions for red onions: both share an entry on the
/// shopping list, while recipes keep their own. Only products bought as themselves are offered, since this
/// works one level deep.
struct ProductBuyAsSection: View {
    let session: AppSession
    let product: Product
    @Binding var buyAs: ProductReference?

    var body: some View {
        Section {
            NavigationLink {
                ProductPickerView(session: session, allowsCreation: false, isSelectable: isOffered) { chosen in
                    buyAs = ProductReference(id: chosen.id, name: chosen.name)
                }
            } label: {
                LabeledContent("Buy as", value: buyAs?.name ?? String(localized: "As itself"))
            }
            if buyAs != nil {
                Button("Buy as itself again", systemImage: "xmark.circle") {
                    buyAs = nil
                }
            }
        } footer: {
            Text("Shares the shopping list entry of the chosen product, such as red onions with onions or pickle brine with pickles. Recipes keep it as it is.")
        }
    }

    private func isOffered(_ candidate: Product) -> Bool {
        candidate.id != product.id && candidate.buyAs == nil
    }
}
