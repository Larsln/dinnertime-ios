import MealplannerKit
import SwiftUI

/// One import with its status, the resulting recipe or their number, or the reason it failed.
struct ImportRow: View {
    let item: RecipeImport
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                status
                Spacer()
                Text(item.createdAt, format: .relative(presentation: .named))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if item.recipes.count > 1 {
                Text("\(item.recipes.count) recipes")
                    .font(.headline)
            } else if let recipe = item.recipes.first {
                NavigationLink(value: recipe) {
                    Text(verbatim: recipe.title)
                        .font(.headline)
                }
            }
            Text(verbatim: item.url)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            if item.status == .failed {
                if let message = item.errorMessage {
                    Text(verbatim: message)
                        .font(.callout)
                }
                Button("Try again", systemImage: "arrow.clockwise", action: onRetry)
                    .buttonStyle(.bordered)
            }
        }
    }

    @ViewBuilder
    private var status: some View {
        switch item.status {
        case .pending:
            Label("Waiting", systemImage: "clock")
                .foregroundStyle(.secondary)
        case .processing:
            Label {
                if let stage = item.stage {
                    Text(verbatim: stage.label)
                } else {
                    Text("Importing")
                }
            } icon: {
                Image(systemName: "arrow.triangle.2.circlepath")
            }
            .foregroundStyle(.blue)
        case .completed:
            Label("Imported", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Label("Failed", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }
}
