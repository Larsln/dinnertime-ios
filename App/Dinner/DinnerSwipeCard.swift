import DinnertimeKit
import SwiftUI

/// A card of a dinner round that follows the finger: dragged far enough to the right it is a yes,
/// to the left a no, and released earlier it springs back.
struct DinnerSwipeCard: View {
    private static let threshold: CGFloat = 96
    private static let degreesPerPoint = 0.05
    private static let flight: CGFloat = 640

    let card: DinnerRound.Card
    /// Whether a vote is on its way, so that the card takes no other.
    let isDisabled: Bool
    let onDecide: (Bool) -> Void

    @State private var offset: CGFloat = 0
    @State private var hasDecided = false
    @GestureState private var isDragging = false

    var body: some View {
        DinnerRecipeCard(recipe: card.recipe, missingCount: card.missingCount)
            .overlay(alignment: offset > 0 ? .topLeading : .topTrailing) {
                if offset != 0 {
                    answer
                }
            }
            .offset(x: offset)
            .rotationEffect(.degrees(offset * Self.degreesPerPoint))
            .gesture(drag, isEnabled: !isDisabled)
            .onChange(of: isDragging) { _, isDragging in
                if !isDragging, !hasDecided {
                    springBack()
                }
            }
            .onChange(of: isDisabled) { _, isDisabled in
                if !isDisabled {
                    hasDecided = false
                    springBack()
                }
            }
            .accessibilityAction(named: Text("Yes")) {
                onDecide(true)
            }
            .accessibilityAction(named: Text("No")) {
                onDecide(false)
            }
    }

    /// The answer the drag stands for, the clearer the nearer the card is to the point where it counts.
    private var answer: some View {
        let isYes = offset > 0
        return Text(isYes ? "Yes" : "No")
            .brandFont(size: 18, relativeTo: .headline)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .foregroundStyle(isYes ? Color.onAccent : Color.paper)
            .background(isYes ? Color.herb : Color.ink, in: .capsule)
            .padding(16)
            .opacity(min(abs(offset) / Self.threshold, 1))
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 12)
            .updating($isDragging) { _, isDragging, _ in
                isDragging = true
            }
            .onChanged { value in
                offset = value.translation.width
            }
            .onEnded { value in
                let distance = value.translation.width
                guard abs(distance) >= Self.threshold else {
                    springBack()
                    return
                }
                hasDecided = true
                withAnimation(.easeOut(duration: 0.2)) {
                    offset = distance > 0 ? Self.flight : -Self.flight
                }
                onDecide(distance > 0)
            }
    }

    private func springBack() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            offset = 0
        }
    }
}
