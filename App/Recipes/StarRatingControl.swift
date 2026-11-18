import MealplannerKit
import SwiftUI

/// Five stars in half steps that set a rating by tapping or dragging across them; the value is reported on release.
///
/// Without a rating the stars are drawn as faint outlines, with a rating of zero as outlines in the color of the filled ones.
struct StarRatingControl: View {
    private static let starSize: CGFloat = 30
    private static let spacing: CGFloat = 4
    private static let dragDistance: CGFloat = 8

    let rating: Int?
    let onSelect: (Int) -> Void

    /// Value under the finger while dragging.
    @State private var draft: Int?

    var body: some View {
        HStack(spacing: Self.spacing) {
            ForEach(0..<StarScale.starCount, id: \.self) { index in
                Image(systemName: symbol(forStar: index))
                    .resizable()
                    .scaledToFit()
                    .frame(width: Self.starSize, height: Self.starSize)
                    .foregroundStyle(shown == nil ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.yellow))
            }
        }
        .contentShape(.rect)
        .gesture(SpatialTapGesture().onEnded { tap in
            onSelect(points(at: tap.location.x))
        })
        .gesture(DragGesture(minimumDistance: Self.dragDistance)
            .onChanged { drag in
                draft = points(at: drag.location.x)
            }
            .onEnded { drag in
                draft = nil
                onSelect(points(at: drag.location.x))
            })
        .accessibilityElement()
        .accessibilityLabel("Your rating")
        .accessibilityValue(valueText)
        .accessibilityAdjustableAction { direction in
            let range = RecipeSummary.ratingRange
            let current = rating ?? range.lowerBound
            onSelect(direction == .increment ? min(current + 1, range.upperBound) : max(current - 1, range.lowerBound))
        }
    }

    /// The rating to draw: the one under the finger, or the stored one.
    private var shown: Int? {
        draft ?? rating
    }

    private var valueText: Text {
        shown.map { Text("\($0) of \(RecipeSummary.ratingRange.upperBound)") } ?? Text("not rated")
    }

    private var width: CGFloat {
        CGFloat(StarScale.starCount) * Self.starSize + CGFloat(StarScale.starCount - 1) * Self.spacing
    }

    private func points(at x: CGFloat) -> Int {
        StarScale.points(at: x, width: width)
    }

    private func symbol(forStar index: Int) -> String {
        switch StarScale.fill(ofStar: index, points: shown ?? 0) {
        case .full: "star.fill"
        case .half: "star.leadinghalf.filled"
        case .empty: "star"
        }
    }
}
