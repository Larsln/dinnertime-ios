import DinnertimeKit
import SwiftUI

/// A recipe an import produced, with its cover, that opens the recipe.
struct ImportedRecipeLink: View {
    let recipe: RecipeSummary

    var body: some View {
        NavigationLink(value: recipe) {
            HStack(spacing: 12) {
                CoverImage(url: recipe.coverThumbURL ?? recipe.coverURL)
                    .frame(width: 56, height: 56)
                    .clipShape(.rect(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: recipe.title)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                    if !recipe.labelLine.isEmpty {
                        Text(verbatim: recipe.labelLine)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
