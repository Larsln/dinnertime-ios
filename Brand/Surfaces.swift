import SwiftUI

/// The corner radii of content the app draws itself.
enum Corner {
    /// Fields and thumbnails.
    static let field: CGFloat = 12
    /// Tiles and compact cards.
    static let tile: CGFloat = 16
    /// Cards.
    static let card: CGFloat = 20
}

extension Shape where Self == RoundedRectangle {
    /// The shape of fields and thumbnails.
    static var field: RoundedRectangle { RoundedRectangle(cornerRadius: Corner.field, style: .continuous) }
    /// The shape of tiles and compact cards.
    static var tile: RoundedRectangle { RoundedRectangle(cornerRadius: Corner.tile, style: .continuous) }
    /// The shape of cards.
    static var card: RoundedRectangle { RoundedRectangle(cornerRadius: Corner.card, style: .continuous) }
}

extension View {
    /// Puts a list, a form or a scroll view on the background of the screens.
    func paperBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(.paper)
    }

    /// Fills the screen with its background behind content that does not scroll.
    func paperScreen() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.paper)
    }

    /// Draws the rows of a list or form as surface.
    func surfaceRows() -> some View {
        listRowBackground(Color.surface)
    }

    /// Draws content on a filled, rounded shape with a hairline around it.
    func surface(_ fill: Color = .surface, in shape: RoundedRectangle = .card) -> some View {
        background(fill, in: shape)
            .overlay {
                shape.strokeBorder(.line)
            }
    }
}
