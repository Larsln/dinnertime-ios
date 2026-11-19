import SwiftUI

/// The three steps of planning a week; finished steps carry a checkmark and lead back when tapped.
struct WizardStepIndicator: View {
    private static let circleSize: CGFloat = 24

    @Binding var step: PlanWizardModel.Step

    var body: some View {
        HStack(spacing: 8) {
            ForEach(PlanWizardModel.Step.allCases, id: \.self) { item in
                Button {
                    step = item
                } label: {
                    HStack(spacing: 6) {
                        badge(for: item)
                        Text(verbatim: item.title)
                            .font(.footnote.weight(item == step ? .semibold : .regular))
                            .foregroundStyle(item == step ? Color.ink : Color.inkMuted)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .disabled(item.rawValue >= step.rawValue)
                .accessibilityAddTraits(item == step ? .isSelected : [])
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.paper)
    }

    @ViewBuilder
    private func badge(for item: PlanWizardModel.Step) -> some View {
        let isDone = item.rawValue < step.rawValue
        Group {
            if isDone {
                Image(systemName: "checkmark")
                    .font(.caption2.weight(.bold))
            } else {
                Text(verbatim: String(item.rawValue + 1))
                    .font(.caption.weight(.semibold))
            }
        }
        .foregroundStyle(item.rawValue <= step.rawValue ? Color.onAccent : Color.inkMuted)
        .frame(width: Self.circleSize, height: Self.circleSize)
        .background(item.rawValue <= step.rawValue ? Color.accent : Color.sunken, in: .circle)
    }
}

extension PlanWizardModel.Step {
    /// Name of the step.
    var title: String {
        switch self {
        case .days: String(localized: "Days")
        case .preferences: String(localized: "Preferences")
        case .preview: String(localized: "Preview")
        }
    }
}
