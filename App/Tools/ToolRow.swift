import DinnertimeKit
import SwiftUI

/// A tool with the number of recipes that need it and the switch that says whether the household has it.
struct ToolRow: View {
    let tool: Tool
    let onSetOwned: (Bool) -> Void

    var body: some View {
        Toggle(isOn: Binding(get: { tool.isOwned }, set: { onSetOwned($0) })) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: tool.name)
                if let count = tool.recipeCount {
                    Text("\(count) recipes")
                        .font(.caption)
                        .foregroundStyle(.inkMuted)
                }
            }
        }
        .tint(.herb)
    }
}
