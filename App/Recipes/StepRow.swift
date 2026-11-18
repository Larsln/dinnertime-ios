import MealplannerKit
import SwiftUI

/// One numbered step whose marked amounts follow the servings and stand out in a heavier weight.
struct StepRow: View {
    let step: RecipeStep
    let scale: Double

    var body: some View {
        Text(line)
    }

    private var line: AttributedString {
        var line = AttributedString("\(step.position). ")
        for part in StepText(step.text).parts(scaledBy: scale) {
            var run = AttributedString(part.text)
            if part.isAmount {
                run.font = .body.weight(.semibold)
            }
            line += run
        }
        return line
    }
}
