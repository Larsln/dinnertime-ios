import Foundation

/// The text of a step split into plain text and the amounts that follow the servings.
///
/// An amount is marked as a number in curly braces, such as `{250}`, `{1,5}` or `{1/2}`; anything else in braces is plain text.
public struct StepText: Equatable, Sendable {
    /// One part of a step.
    public enum Segment: Equatable, Sendable {
        /// Text that is shown as written.
        case text(String)
        /// An amount as stated for the servings of the recipe.
        case amount(Double)
    }

    /// Scaled amounts from here on stay decimal; they are usually grams or milliliters.
    private static let fractionLimit = 20.0

    public let segments: [Segment]

    public init(_ raw: String) {
        let marker = /\{(\d+(?:[.,]\d+)?|\d+\/\d+)\}/.asciiOnlyDigits()
        var segments: [Segment] = []
        var plain = ""
        var rest = raw[...]
        while let match = rest.firstMatch(of: marker) {
            plain += rest[..<match.range.lowerBound]
            if let value = Self.value(of: match.output.1) {
                Self.append(plain, to: &segments)
                plain = ""
                segments.append(.amount(value))
            } else {
                plain += match.output.0
            }
            rest = rest[match.range.upperBound...]
        }
        Self.append(plain + rest, to: &segments)
        self.segments = segments
    }

    /// The step with every amount multiplied by `factor`, the ratio of wanted to stated servings.
    public func rendered(scaledBy factor: Double = 1, formatter: AmountFormatter = AmountFormatter()) -> String {
        parts(scaledBy: factor, formatter: formatter).map(\.text).joined()
    }

    /// The display text of every segment in order, telling scaled amounts from plain text.
    ///
    /// Amounts are written with kitchen fractions as long as they stay below the limit for those.
    public func parts(scaledBy factor: Double = 1, formatter: AmountFormatter = AmountFormatter()) -> [(text: String, isAmount: Bool)] {
        segments.map { segment in
            switch segment {
            case .text(let text):
                (text, false)
            case .amount(let value):
                (Self.amountText(value * factor, formatter: formatter), true)
            }
        }
    }

    private static func amountText(_ value: Double, formatter: AmountFormatter) -> String {
        value >= fractionLimit ? formatter.number(value) : KitchenQuantity.format(value, formatter: formatter)
    }

    private static func append(_ plain: String, to segments: inout [Segment]) {
        if !plain.isEmpty {
            segments.append(.text(plain))
        }
    }

    /// The number a marker states; `nil` for a fraction that divides by zero.
    private static func value(of marker: Substring) -> Double? {
        let terms = marker.split(separator: "/")
        guard terms.count == 2 else {
            return Double(marker.replacing(",", with: "."))
        }
        guard let numerator = Double(terms[0]), let denominator = Double(terms[1]), denominator > 0 else {
            return nil
        }
        return numerator / denominator
    }
}
