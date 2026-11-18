import MealplannerKit
import SwiftUI

/// A slider from 0 (bad) to 10 (good) in whole steps that reports the value when the user lets go.
///
/// Without a rating the slider rests dimmed in the middle and the value reads "Not rated".
struct RatingControl: View {
    private static let restingValue = 5.0
    private static let unratedOpacity = 0.4

    let rating: Int?
    let onSelect: (Int) -> Void

    @State private var value: Double
    @State private var isEditing = false

    init(rating: Int?, onSelect: @escaping (Int) -> Void) {
        self.rating = rating
        self.onSelect = onSelect
        _value = State(initialValue: rating.map(Double.init) ?? Self.restingValue)
    }

    var body: some View {
        HStack(spacing: 12) {
            Slider(value: $value, in: bounds, step: 1) {
                Text("Your rating")
            } onEditingChanged: { editing in
                isEditing = editing
                if !editing {
                    onSelect(Int(value))
                }
            }
            .opacity(showsValue ? 1 : Self.unratedOpacity)
            Group {
                if showsValue {
                    Text("\(Int(value)) / \(RecipeSummary.ratingRange.upperBound)")
                        .monospacedDigit()
                } else {
                    Text("Not rated")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minWidth: 72, alignment: .trailing)
        }
        .onChange(of: rating) { _, rating in
            value = rating.map(Double.init) ?? Self.restingValue
        }
    }

    private var showsValue: Bool {
        rating != nil || isEditing
    }

    private var bounds: ClosedRange<Double> {
        Double(RecipeSummary.ratingRange.lowerBound)...Double(RecipeSummary.ratingRange.upperBound)
    }
}
