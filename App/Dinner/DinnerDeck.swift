import DinnertimeKit
import SwiftUI

/// One recipe at a time to say yes or no to: with the two buttons or by dragging the card to the right or left.
struct DinnerDeck: View {
    let deck: DinnerDeckPosition
    /// Whether the cards are those somebody else liked, shown a second time.
    let isSecondLook: Bool
    /// Whether a vote is on its way.
    let isDisabled: Bool
    let onDecide: (Bool) -> Void

    var body: some View {
        VStack(spacing: 16) {
            if isSecondLook {
                Text("The other person liked this – do you?")
                    .font(.headline)
                    .foregroundStyle(.ink)
                    .multilineTextAlignment(.center)
            }
            Text("\(deck.position) of \(deck.total)")
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(.inkMuted)
            DinnerSwipeCard(card: deck.card, isDisabled: isDisabled, onDecide: onDecide)
                .id(deck.card.recipe.id)
                .transition(.scale(scale: 0.94).combined(with: .opacity))
            HStack(spacing: 12) {
                Button {
                    onDecide(false)
                } label: {
                    Label("No", systemImage: "xmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                Button {
                    onDecide(true)
                } label: {
                    Label("Yes", systemImage: "heart.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .controlSize(.large)
            .disabled(isDisabled)
            Text("Drag the card right for yes, left for no.")
                .font(.caption)
                .foregroundStyle(.inkMuted)
                .multilineTextAlignment(.center)
        }
        .animation(.easeOut(duration: 0.2), value: deck.card.recipe.id)
    }
}
