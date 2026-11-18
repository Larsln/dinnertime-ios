import MealplannerKit
import SwiftUI

/// The tools a recipe needs and its steps, grouped by component.
struct RecipeMethodList: View {
    let recipe: Recipe

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
                                .foregroundStyle(.orange)
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
                    Text(verbatim: "\(step.position). \(step.text)")
                }
            } header: {
                if let title = group.title {
                    Text(verbatim: title)
                }
            }
        }
    }
}
