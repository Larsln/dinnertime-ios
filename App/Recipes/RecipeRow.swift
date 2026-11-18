import MealplannerKit
import SwiftUI

/// Cover image, title, course, tags and marks of a recipe.
struct RecipeRow: View {
    private static let imageSize: CGFloat = 56

    let recipe: RecipeSummary

    var body: some View {
        HStack(spacing: 12) {
            CoverImage(url: recipe.coverURL)
                .frame(width: Self.imageSize, height: Self.imageSize)
                .clipShape(.rect(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: recipe.title)
                    .font(.headline)
                if !recipe.labelLine.isEmpty {
                    Text(verbatim: recipe.labelLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
            RecipeMarks(recipe: recipe)
        }
    }
}
