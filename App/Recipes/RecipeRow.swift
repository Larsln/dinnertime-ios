import DinnertimeKit
import SwiftUI

/// Cover image, title, course, tags and marks of a recipe.
struct RecipeRow: View {
    private static let imageSize: CGFloat = 76

    let recipe: RecipeSummary

    var body: some View {
        HStack(spacing: 12) {
            CoverImage(url: recipe.coverThumbURL ?? recipe.coverURL)
                .frame(width: Self.imageSize, height: Self.imageSize)
                .clipShape(.field)
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: recipe.title)
                    .font(.headline)
                if !recipe.labelLine.isEmpty {
                    Text(verbatim: recipe.labelLine)
                        .font(.footnote)
                        .foregroundStyle(.inkMuted)
                        .lineLimit(2)
                }
                RecipeMarks(recipe: recipe)
            }
            Spacer(minLength: 0)
        }
    }
}
