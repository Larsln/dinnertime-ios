import DinnertimeKit
import SwiftUI

/// The one place a recipe is rated: the stars with the own rating, the way to withdraw it and, to the right, the household average.
struct RecipeRatingBlock: View {
    let model: RecipeDetailModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                StarRatingControl(rating: model.summary.rating) { points in
                    rate(points)
                }
                if model.summary.rating != nil {
                    Button("Withdraw rating", systemImage: "xmark.circle.fill") {
                        rate(nil)
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .foregroundStyle(.inkMuted)
                }
                Spacer(minLength: 0)
                if let average = model.summary.averageRatingText() {
                    Text(verbatim: "Ø \(average) (\(model.summary.ratingCount))")
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(.inkMuted)
                        .accessibilityLabel("Ø \(average) of 5 from \(model.summary.ratingCount) ratings")
                }
            }
        }
    }

    private func rate(_ rating: Int?) {
        Task {
            await model.rate(rating)
        }
    }
}
