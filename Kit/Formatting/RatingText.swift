import Foundation

extension RecipeSummary {
    /// The household average with one decimal, such as "7.5"; `nil` while nobody rated the recipe.
    public func averageRatingText(locale: Locale = .current) -> String? {
        averageRating.map { $0.formatted(.number.precision(.fractionLength(1)).locale(locale)) }
    }
}
