import MealplannerKit
import SwiftUI

/// The one place a recipe is rated: the stars with the own rating, the way to withdraw it and the household average.
struct RecipeRatingBlock: View {
    let model: RecipeDetailModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                StarRatingControl(rating: model.summary.rating) { points in
                    rate(points)
                }
                valueText
                    .font(.subheadline.weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(model.summary.rating == nil ? .secondary : .primary)
                Spacer(minLength: 0)
                if model.summary.rating != nil {
                    Button("Withdraw rating", systemImage: "xmark.circle.fill") {
                        rate(nil)
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                }
            }
            if let average = model.summary.averageRatingText() {
                Text("Ø \(average) of 5 from \(model.summary.ratingCount) ratings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .disabled(model.isMarking)
    }

    private var valueText: Text {
        model.summary.rating.map { Text("\(StarScale.starsText(points: $0)) of \(StarScale.starCount)") } ?? Text("not rated")
    }

    private func rate(_ rating: Int?) {
        Task {
            await model.rate(rating)
        }
    }
}
