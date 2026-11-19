import DinnertimeKit
import SwiftUI

/// Summary of an ingredient line in the editor.
struct IngredientDraftRow: View {
    let line: IngredientDraft
    let units: [MeasureUnit]

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                if let name {
                    Text(verbatim: name)
                } else {
                    Text("New ingredient")
                        .foregroundStyle(.inkMuted)
                }
                if let note = line.note.nilIfBlank {
                    Text(verbatim: note)
                        .font(.caption)
                        .foregroundStyle(.inkMuted)
                }
            }
            Spacer()
            if let amount {
                Text(verbatim: amount)
                    .monospacedDigit()
            }
        }
    }

    private var name: String? {
        line.product?.name ?? line.rawText.nilIfBlank
    }

    private var amount: String? {
        guard let quantity = line.quantity else {
            return nil
        }
        let number = AmountFormatter().number(quantity)
        guard let unit = units.first(where: { $0.id == line.unitID }) else {
            return number
        }
        return "\(number) \(unit.code ?? unit.name)"
    }
}
