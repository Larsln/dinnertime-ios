import DinnertimeKit
import SwiftUI

/// Fills the share sheet with the progress of an import and its outcome.
struct ShareView: View {
    /// Name of the button that starts the import, for the interface tests.
    static let startIdentifier = "startImport"

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
                .foregroundStyle(.inkMuted)
            }
            content
        }
        .frame(maxWidth: 420)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tint(.accent)
        .background(.paper)
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .preparing:
            ProgressView()
        case .choosing:
            DishCountPicker(selection: Bindable(model).dishCount)
            Button("Import") {
                Task {
                    await model.start()
                }
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier(Self.startIdentifier)
        case .sending:
            ProgressView()
            Text("Sending link…")
        case let .importing(item):
            Text("The recipe is being imported.")
                .sectionHeadingStyle()
            ImportStepsView(item: item)
            Button("Continue in background", action: onClose)
                .buttonStyle(.bordered)
        case let .imported(item, wasKnown):
            Label {
                if wasKnown {
                    Text("Already in your collection")
                } else {
                    Text(verbatim: ImportProgress.completionTitle(recipeCount: item.recipes.count))
                }
            } icon: {
                Image(systemName: "checkmark.circle.fill")
            }
            .font(.headline)
            .foregroundStyle(.doneMark)
            if item.recipes.count > 1 {
                ImportedRecipeTitles(recipes: item.recipes)
            } else if let recipe = item.recipes.first {
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
        case .waiting:
            Label("Waiting for a connection", systemImage: "clock")
                .font(.headline)
            Text("The link is imported as soon as the server can be reached.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.inkMuted)
            Button("Done", action: onClose)
                .buttonStyle(.borderedProminent)
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
            .foregroundStyle(.accentDeep)
        if let message {
            Text(verbatim: message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.inkMuted)
        }
    }
}
