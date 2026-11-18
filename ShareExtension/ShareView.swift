import MealplannerKit
import SwiftUI

/// A card with the progress of an import and its outcome.
struct ShareView: View {
    let model: ShareModel
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            if let host = model.host {
                Label {
                    Text(verbatim: host)
                } icon: {
                    Image(systemName: "link")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            content
        }
        .padding(24)
        .frame(maxWidth: 420)
        .background(.background, in: .rect(cornerRadius: 24))
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.25))
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .sending:
            ProgressView()
            Text("Sending link…")
        case let .importing(item):
            Text("The recipe is being imported.")
                .font(.headline)
            ImportStepsView(item: item)
            Button("Continue in background", action: onClose)
                .buttonStyle(.bordered)
        case let .imported(item, wasKnown):
            Label(wasKnown ? "Already in your collection" : "Recipe imported", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundStyle(.green)
            if let recipe = item.recipe {
                ImportedRecipeView(recipe: recipe, serverURL: model.serverURL)
            }
            Button("Done", action: onClose)
                .buttonStyle(.borderedProminent)
        case let .rejected(item):
            failure(message: item.errorMessage)
            HStack {
                Button("Close", action: onClose)
                    .buttonStyle(.bordered)
                Button("Try again") {
                    Task {
                        await model.retry()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        case let .failed(message):
            failure(message: message)
            Button("Close", action: onClose)
                .buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    private func failure(message: String?) -> some View {
        Label("The link could not be imported.", systemImage: "exclamationmark.triangle.fill")
            .font(.headline)
            .foregroundStyle(.red)
        if let message {
            Text(verbatim: message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }
}
