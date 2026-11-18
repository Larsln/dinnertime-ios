import MealplannerKit
import SwiftUI

/// One proposal of the planner with the buttons that lock it or ask for another recipe.
struct ProposalRow: View {
    private static let imageSize: CGFloat = 48

    let proposal: MealProposal
    let isLocked: Bool
    let onToggleLock: () -> Void
    let onReroll: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            VStack(spacing: 0) {
                Text(verbatim: proposal.date.dayNumberText)
                    .font(.headline)
                    .monospacedDigit()
                Text(verbatim: proposal.date.weekdayText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 34)
            CoverImage(url: proposal.recipe.coverURL)
                .frame(width: Self.imageSize, height: Self.imageSize)
                .clipShape(.rect(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: proposal.recipe.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Text(verbatim: details)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Button(isLocked ? "Unlock" : "Lock", systemImage: isLocked ? "lock.fill" : "lock.open", action: onToggleLock)
                .tint(isLocked ? .accentColor : .secondary)
            Button("Reroll", systemImage: "dice", action: onReroll)
                .disabled(isLocked)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
    }

    private var details: String {
        [proposal.meal.label, proposal.recipe.totalTimeText].compactMap { $0 }.joined(separator: " · ")
    }
}
