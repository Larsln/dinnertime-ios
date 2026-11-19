import SwiftUI

/// Keeps the content of a list, form or scroll view at a width that reads well and centers it on wide screens.
///
/// The view itself still spans the screen, so that it scrolls from anywhere; on narrow screens nothing changes.
private struct ReadableWidth: ViewModifier {
    let maximum: CGFloat

    @State private var margin: CGFloat?

    func body(content: Content) -> some View {
        content
            .contentMargins(.horizontal, margin, for: .scrollContent)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { width in
                margin = width > maximum ? (width - maximum) / 2 : nil
            }
    }
}

/// The widths content is limited to on wide screens.
enum ReadableMetrics {
    /// Lists and forms.
    static let form: CGFloat = 720
    /// A recipe with ingredients and method side by side.
    static let recipe: CGFloat = 1040
    /// Width of a recipe panel from which the ingredients and the method stand side by side.
    static let recipeColumns: CGFloat = 560
    /// Corner radius of the large panels on wide screens.
    static let panelCorner: CGFloat = 30
    /// Space around the large panels on wide screens.
    static let panelMargin: CGFloat = 14
}

extension View {
    /// Limits the content of a scrolling view to a readable width and centers it.
    func readableWidth(_ maximum: CGFloat = ReadableMetrics.form) -> some View {
        modifier(ReadableWidth(maximum: maximum))
    }

    /// Draws a view as a large rounded panel with a hairline around it, as wide screens use for what stands next to a list.
    func panel(_ fill: Color = .surface) -> some View {
        let shape = RoundedRectangle(cornerRadius: ReadableMetrics.panelCorner, style: .continuous)
        return background(fill)
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(.line)
            }
    }
}
