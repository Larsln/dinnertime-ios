import DinnertimeKit
import SwiftUI

/// The tools a recipe needs and its steps as a column, grouped by component, with the amounts scaled to the wanted servings.
struct RecipeMethodColumn: View {
    let recipe: Recipe
    /// Ratio of wanted to stated servings.
    let scale: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Method")
                .sectionHeadingStyle()
                .accessibilityAddTraits(.isHeader)
            if !recipe.tools.isEmpty {
                tools
            }
            ForEach(recipe.stepGroups) { group in
                if let title = group.title {
                    Text(verbatim: title)
                        .font(.headline)
                        .padding(.top, 6)
                        .accessibilityAddTraits(.isHeader)
                }
                ForEach(group.steps) { step in
                    StepRow(step: step, scale: scale)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tools: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tools")
                .overlineStyle()
            ForEach(recipe.tools) { tool in
                if tool.isOwned {
                    Text(verbatim: tool.name)
                } else {
                    HStack {
                        Text(verbatim: tool.name)
                        Spacer()
                        Label("Not available", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.accentDeep)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.sunken, in: .tile)
    }
}
