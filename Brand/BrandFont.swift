import SwiftUI
import UIKit

/// The typeface of large titles and section headings, a variable font bundled with the app.
enum BrandFont {
    private static let family = "Bricolage Grotesque"
    private static let weightAxis = 2_003_265_652
    private static let opticalSizeAxis = 1_869_640_570
    private static let boldWeight: CGFloat = 700
    private static let opticalSizes: ClosedRange<CGFloat> = 12...96
    private static let largeTitleSize: CGFloat = 34

    /// The bold cut at a size in points, drawn for that optical size; the bold system font when the typeface is missing.
    static func bold(size: CGFloat) -> UIFont {
        guard !UIFont.fontNames(forFamilyName: family).isEmpty else {
            return .systemFont(ofSize: size, weight: .bold)
        }
        let opticalSize = min(max(size, opticalSizes.lowerBound), opticalSizes.upperBound)
        let descriptor = UIFontDescriptor(fontAttributes: [
            .family: family,
            UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String): [
                weightAxis: boldWeight,
                opticalSizeAxis: opticalSize,
            ],
        ])
        return UIFont(descriptor: descriptor, size: size)
    }

    /// Sets the large navigation titles in the typeface; the bars themselves stay as the system draws them.
    @MainActor
    static func applyToNavigationTitles() {
        let font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: bold(size: largeTitleSize))
        var attributes: [NSAttributedString.Key: Any] = [.font: font]
        attributes[.foregroundColor] = UIColor(named: "Ink")
        UINavigationBar.appearance().largeTitleTextAttributes = attributes
    }
}

/// Sets text in the brand typeface at a size that follows the text size the user chose.
private struct BrandFontModifier: ViewModifier {
    @ScaledMetric private var size: CGFloat

    init(size: CGFloat, relativeTo style: Font.TextStyle) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: style)
    }

    func body(content: Content) -> some View {
        content.font(Font(BrandFont.bold(size: size)))
    }
}

extension View {
    /// Sets text in the brand typeface; `size` is the size at the standard text size and grows with `style`.
    func brandFont(size: CGFloat, relativeTo style: Font.TextStyle) -> some View {
        modifier(BrandFontModifier(size: size, relativeTo: style))
    }

    /// The style of a title at the top of content, such as the name of a recipe.
    func contentTitleStyle() -> some View {
        brandFont(size: 28, relativeTo: .title)
            .foregroundStyle(.ink)
    }

    /// The style of a heading above a group of content.
    func sectionHeadingStyle() -> some View {
        brandFont(size: 20, relativeTo: .title3)
            .foregroundStyle(.ink)
            .textCase(nil)
    }

    /// The style of a small label above content: bold capitals with a little spacing.
    func overlineStyle(_ color: Color = .inkMuted) -> some View {
        font(.caption.weight(.bold))
            .textCase(.uppercase)
            .tracking(0.6)
            .foregroundStyle(color)
    }
}
