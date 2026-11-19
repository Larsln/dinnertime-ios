import SwiftUI

/// The sign of the app: a plate seen from above that is a clock with its hands at seven.
struct BrandMark: View {
    /// The colors of the parts of the sign.
    private struct Colors {
        let ground: Color
        let plate: Color
        let ring: Color
        let minuteHand: Color
        let hourHand: Color

        static let light = Colors(ground: .accent, plate: .paper, ring: .line, minuteHand: .ink, hourHand: .accent)
        static let dark = Colors(ground: .surface, plate: .accent, ring: .onAccent.opacity(0.25), minuteHand: .onAccent, hourHand: .ink)
    }

    private static let canvas: CGFloat = 512
    private static let cornerRatio: CGFloat = 0.225
    private static let center = CGPoint(x: 256, y: 256)
    private static let handStyle = StrokeStyle(lineWidth: 26, lineCap: .round)

    /// Length of the edges in points.
    let size: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let colors = colorScheme == .dark ? Colors.dark : Colors.light
        Canvas { context, size in
            let scale = size.width / Self.canvas
            context.scaleBy(x: scale, y: scale)
            context.fill(Self.circle(radius: 176), with: .color(colors.plate))
            context.stroke(Self.circle(radius: 126), with: .color(colors.ring), lineWidth: 6)
            context.stroke(Self.hand(to: CGPoint(x: 256, y: 132)), with: .color(colors.minuteHand), style: Self.handStyle)
            context.stroke(Self.hand(to: CGPoint(x: 214, y: 329)), with: .color(colors.hourHand), style: Self.handStyle)
            context.fill(Self.circle(radius: 17), with: .color(colors.minuteHand))
        }
        .frame(width: size, height: size)
        .background(colors.ground)
        .clipShape(.rect(cornerRadius: Self.cornerRatio * size, style: .continuous))
        .accessibilityHidden(true)
    }

    private static func circle(radius: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    }

    private static func hand(to tip: CGPoint) -> Path {
        var path = Path()
        path.move(to: center)
        path.addLine(to: tip)
        return path
    }
}

/// The sign of the app centered above a form, as a row without a background.
struct BrandMarkRow: View {
    var body: some View {
        BrandMark(size: 84)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
    }
}
