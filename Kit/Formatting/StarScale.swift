/// Maps a rating in points to a row of stars in half steps: every half star is one point.
public enum StarScale {
    /// How much of a star is filled.
    public enum Fill: Equatable, Sendable {
        case empty, half, full
    }

    /// Number of stars that show the whole range of ratings.
    public static let starCount = (RecipeSummary.ratingRange.upperBound + 1) / 2

    /// The fill of the star at `index`, counted from zero, for a rating of `points`.
    public static func fill(ofStar index: Int, points: Int) -> Fill {
        let remaining = points - index * 2
        return remaining >= 2 ? .full : remaining == 1 ? .half : .empty
    }

    /// The rating a touch at horizontal position `x` on a row of stars of `width` stands for.
    ///
    /// The row is divided into one step per point; touches left of the first half star give zero.
    public static func points(at x: Double, width: Double) -> Int {
        let range = RecipeSummary.ratingRange
        guard width > 0 else {
            return range.lowerBound
        }
        let points = Int((x / width * Double(range.upperBound)).rounded(.up))
        return min(max(points, range.lowerBound), range.upperBound)
    }
}
