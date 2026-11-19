import DinnertimeKit
import SwiftUI

/// The titles of the recipes an import produced from a video with several dishes.
struct ImportedRecipeTitles: View {
    let recipes: [RecipeSummary]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(recipes) { recipe in
                Label {
                    Text(verbatim: recipe.title)
                } icon: {
                    Image(systemName: "fork.knife")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
