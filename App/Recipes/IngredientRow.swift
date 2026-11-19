import DinnertimeKit
import SwiftUI

/// One ingredient line with its scaled amount.
struct IngredientRow: View {
    let ingredient: Ingredient
    let scale: Double

    var body: some View {
        let text = ingredient.text(scaledBy: scale)
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: text.name)
                if let note = ingredient.note {
                    Text(verbatim: note)
                        .font(.caption)
                        .foregroundStyle(.inkMuted)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if let amount = text.amount {
                    Text(verbatim: amount)
                        .monospacedDigit()
                }
                if ingredient.isEstimated {
                    Text("(estimated)")
                        .font(.caption)
                        .foregroundStyle(.inkMuted)
                }
            }
        }
    }
}
