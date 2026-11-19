import SwiftUI

extension View {
    /// Draws a row of a plain list as a card of its own, with the disclosure mark of a link inside it.
    ///
    /// - Parameters:
    ///   - fill: Color of the card.
    ///   - leading: Space left of the card that the content of the row uses for something else.
    func cardRow(_ fill: Color = .surface, shape: RoundedRectangle = .card, leading: CGFloat = 0) -> some View {
        listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(
                top: CardRowMetrics.gap + CardRowMetrics.padding,
                leading: CardRowMetrics.margin + (leading > 0 ? 0 : CardRowMetrics.padding),
                bottom: CardRowMetrics.gap + CardRowMetrics.padding,
                trailing: CardRowMetrics.margin + CardRowMetrics.padding
            ))
            .listRowBackground(
                shape
                    .fill(fill)
                    .overlay {
                        shape.strokeBorder(.line)
                    }
                    .padding(.vertical, CardRowMetrics.gap)
                    .padding(.leading, CardRowMetrics.margin + leading)
                    .padding(.trailing, CardRowMetrics.margin)
            )
    }
}

/// The measures of rows that are drawn as cards.
enum CardRowMetrics {
    /// Space between the card and the edges of the screen.
    static let margin: CGFloat = 16
    /// Half of the space between two cards.
    static let gap: CGFloat = 5
    /// Space between the edge of the card and its content.
    static let padding: CGFloat = 10
}
