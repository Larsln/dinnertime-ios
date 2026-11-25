import DinnertimeKit
import SwiftUI

/// Name, store section, aliases and state of a product in a list.
struct ProductRow: View {
    let product: Product

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: product.name)
                Text(verbatim: details)
                    .font(.caption)
                    .foregroundStyle(.inkMuted)
            }
            Spacer(minLength: 0)
            if product.isStaple {
                Image(systemName: "refrigerator")
                    .foregroundStyle(.inkMuted)
                    .accessibilityLabel("Pantry staple")
            }
            if product.status == .suggested {
                Image(systemName: "sparkles")
                    .foregroundStyle(.accentDeep)
                    .accessibilityLabel("Suggested")
            }
        }
    }

    private var details: String {
        let section = product.storeSection?.name ?? String(localized: "No section")
        let buyAs = product.buyAs.map { String(localized: "bought as \($0.name)") }
        return ([section] + (product.aliases ?? []) + [buyAs].compactMap(\.self)).joined(separator: " · ")
    }
}
