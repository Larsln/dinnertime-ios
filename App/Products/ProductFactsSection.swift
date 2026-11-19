import DinnertimeKit
import SwiftUI

/// What the server knows about a product beyond its editable values.
struct ProductFactsSection: View {
    let product: Product

    var body: some View {
        Section {
            if product.status == .suggested {
                Label("Suggested", systemImage: "sparkles")
                    .foregroundStyle(.accentDeep)
            }
            if product.enrichedAt == nil {
                Label("Suggestions are pending", systemImage: "hourglass")
                    .foregroundStyle(.inkMuted)
            }
            if let count = product.recipeCount {
                LabeledContent("Used in ingredient lines", value: count, format: .number)
            }
            if let aliases = product.aliases, !aliases.isEmpty {
                LabeledContent("Also known as", value: aliases.joined(separator: ", "))
            }
        }
    }
}
