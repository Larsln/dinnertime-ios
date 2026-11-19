import DinnertimeKit
import SwiftUI

/// The tools a recipe needs and its steps, grouped by component, with the amounts in the steps scaled to the wanted servings.
struct RecipeMethodList: View {
    let recipe: Recipe
    /// Ratio of wanted to stated servings.
    let scale: Double

    var body: some View {
        if !recipe.tools.isEmpty {
            Section("Tools") {
                ForEach(recipe.tools) { tool in
                    if tool.isOwned {
                        Text(verbatim: tool.name)
                    } else {
                        LabeledContent {
                            Label("Not available", systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(.accentDeep)
                        } label: {
                            Text(verbatim: tool.name)
                        }
                    }
                }
            }
        }
        ForEach(recipe.stepGroups) { group in
            Section {
                ForEach(group.steps) { step in
                    StepRow(step: step, scale: scale)
                }
            } header: {
                if let title = group.title {
                    Text(verbatim: title)
                        .sectionHeadingStyle()
                }
            }
        }
    }
}
