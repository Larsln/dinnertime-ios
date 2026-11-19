import DinnertimeKit
import SwiftUI

/// The stages of an import below each other; finished ones are checked and the current one spins.
struct ImportStepsView: View {
    private static let markSize: CGFloat = 22

    let item: RecipeImport

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(RecipeImport.Stage.allCases, id: \.self) { stage in
                let state = ImportProgress.state(of: stage, in: item)
                HStack(spacing: 12) {
                    mark(for: state)
                        .frame(width: Self.markSize, height: Self.markSize)
                    Text(verbatim: stage.label)
                        .font(state == .active ? .body.weight(.semibold) : .body)
                        .foregroundStyle(state == .upcoming ? .secondary : .primary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func mark(for state: ImportProgress.StepState) -> some View {
        switch state {
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.green)
        case .active:
            ProgressView()
        case .upcoming:
            Image(systemName: "circle")
                .font(.title3)
                .foregroundStyle(.tertiary)
        }
    }
}
