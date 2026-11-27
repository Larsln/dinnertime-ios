import DinnertimeKit
import SwiftUI

/// What the meals of the list need that is at home already, as a quiet note instead of tiles.
struct ShoppingStockNote: View {
    let needs: [StockedNeed]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("In stock", systemImage: "refrigerator")
                .font(.footnote.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            Text(verbatim: needs.map { $0.text() }.joined(separator: " · "))
                .font(.footnote)
        }
        .foregroundStyle(.inkMuted)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
