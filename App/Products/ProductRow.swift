import MealplannerKit
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
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if product.isPantryStaple == true {
                Image(systemName: "refrigerator")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Pantry staple")
            }
            if product.status == .suggested {
                Image(systemName: "sparkles")
                    .foregroundStyle(.orange)
                    .accessibilityLabel("Suggested")
            }
        }
    }

    private var details: String {
        let section = product.storeSection?.name ?? String(localized: "No section")
        return ([section] + (product.aliases ?? [])).joined(separator: " · ")
    }
}
