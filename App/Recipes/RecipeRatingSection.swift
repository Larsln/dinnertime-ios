import MealplannerKit
import SwiftUI

/// Lets the user rate a recipe and withdraw the rating.
struct RecipeRatingSection: View {
    let model: RecipeDetailModel

    var body: some View {
        Section("Your rating") {
            RatingControl(rating: model.summary.rating) { value in
                rate(value)
            }
            if model.summary.rating != nil {
                Button("Withdraw rating", systemImage: "arrow.uturn.backward") {
                    rate(nil)
                }
            }
        }
        .disabled(model.isMarking)
    }

    private func rate(_ rating: Int?) {
        Task {
            await model.rate(rating)
        }
    }
}
