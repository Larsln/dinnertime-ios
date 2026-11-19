import DinnertimeKit
import SwiftUI

/// One step with its number on a dark disc; its marked amounts follow the servings and stand out in bold and color.
struct StepRow: View {
    let step: RecipeStep
    let scale: Double

    @ScaledMetric(relativeTo: .footnote) private var discSize: CGFloat = 26

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(verbatim: String(step.position))
                .font(.footnote.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.paper)
                .frame(minWidth: discSize, minHeight: discSize)
                .background(.ink, in: .capsule)
            Text(line)
                .frame(minHeight: discSize, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    private var line: AttributedString {
        var line = AttributedString()
        for part in StepText(step.text).parts(scaledBy: scale) {
            var run = AttributedString(part.text)
            if part.isAmount {
                run.font = .body.weight(.bold)
                run.foregroundColor = .accentDeep
            }
            line += run
        }
        return line
    }
}
