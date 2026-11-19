import DinnertimeKit
import SwiftUI

/// A recipe as a card to decide on: cover, title, total time and whether everything it needs is in the pantry.
struct DinnerRecipeCard: View {
    private static let coverRatio: CGFloat = 4 / 3

    let recipe: RecipeSummary
    /// Number of products the pantry does not cover; `nil` where that is not told.
    var missingCount: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.accentSoft
                .aspectRatio(Self.coverRatio, contentMode: .fit)
                .overlay {
                    CoverImage(url: recipe.coverURL ?? recipe.coverThumbURL)
                }
                .clipped()
            VStack(alignment: .leading, spacing: 8) {
                Text(verbatim: recipe.title)
                    .brandFont(size: 24, relativeTo: .title2)
                    .foregroundStyle(.ink)
                    .lineLimit(2)
                HStack(spacing: 12) {
                    if let time = recipe.totalTimeText {
                        Label {
                            Text(verbatim: time)
                        } icon: {
                            Image(systemName: "clock")
                        }
                        .foregroundStyle(.inkMuted)
                    }
                    if let missingCount {
                        badge(for: missingCount)
                    }
                }
                .font(.subheadline)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.surface)
        .clipShape(.card)
        .overlay {
            RoundedRectangle.card.strokeBorder(.line)
        }
        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
        .accessibilityElement(children: .combine)
    }

    /// Says that everything is at home, or how many ingredients have to be bought.
    private func badge(for missingCount: Int) -> some View {
        let isComplete = missingCount == 0
        return Group {
            if isComplete {
                Text("Everything at home")
            } else {
                Text("\(missingCount) ingredients missing")
            }
        }
        .font(.footnote.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .foregroundStyle(isComplete ? Color.herb : Color.accentDeep)
        .background(isComplete ? Color.herbSoft : Color.accentSoft, in: .capsule)
    }
}
