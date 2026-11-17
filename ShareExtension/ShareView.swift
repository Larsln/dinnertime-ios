import SwiftUI

/// Shows the progress and the outcome of a share.
struct ShareView: View {
    let model: ShareModel
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            switch model.state {
            case .sending:
                ProgressView()
                Text("Sending link…")
            case .queued:
                outcome("The recipe is being imported.", systemImage: "checkmark.circle.fill", color: .green)
            case let .alreadyImported(title):
                outcome("This recipe is already in your collection.", systemImage: "checkmark.circle.fill", color: .green)
                Text(verbatim: title)
                    .foregroundStyle(.secondary)
            case let .failed(message):
                outcome("The link could not be imported.", systemImage: "exclamationmark.triangle.fill", color: .red)
                Text(verbatim: message)
                    .foregroundStyle(.secondary)
                Button("Close", action: onClose)
                    .buttonStyle(.borderedProminent)
            }
        }
        .multilineTextAlignment(.center)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }

    @ViewBuilder
    private func outcome(_ title: LocalizedStringKey, systemImage: String, color: Color) -> some View {
        Image(systemName: systemImage)
            .font(.largeTitle)
            .foregroundStyle(color)
        Text(title)
            .font(.headline)
    }
}
