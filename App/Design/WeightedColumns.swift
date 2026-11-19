import SwiftUI

/// Lays its subviews out side by side, aligned at the top, in columns whose widths follow fixed weights.
struct WeightedColumns: Layout {
    /// The share of the width every column takes, in the order of the subviews.
    let weights: [CGFloat]
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let heights = zip(subviews, widths(in: width)).map { subview, column in
            subview.sizeThatFits(ProposedViewSize(width: column, height: nil)).height
        }
        return CGSize(width: width, height: heights.max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        for (subview, column) in zip(subviews, widths(in: bounds.width)) {
            subview.place(at: CGPoint(x: x, y: bounds.minY), anchor: .topLeading, proposal: ProposedViewSize(width: column, height: nil))
            x += column + spacing
        }
    }

    private func widths(in total: CGFloat) -> [CGFloat] {
        let available = max(0, total - spacing * CGFloat(weights.count - 1))
        let sum = weights.reduce(0, +)
        return weights.map { sum > 0 ? available * $0 / sum : 0 }
    }
}
