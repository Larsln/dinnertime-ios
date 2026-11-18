import Foundation

extension RecipeSummary {
    /// The household average in stars with one decimal, such as "3.8"; `nil` while nobody rated the recipe.
    public func averageRatingText(locale: Locale = .current) -> String? {
        averageRating.map { ($0 / 2).formatted(.number.precision(.fractionLength(1)).locale(locale)) }
    }
}
