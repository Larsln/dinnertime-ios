import MealplannerKit
import SwiftUI

/// One import as a card: its recipes once it is done, its progress while it runs, or the reason it failed.
struct ImportRow: View {
    let item: RecipeImport
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch item.status {
            case .completed where !item.recipes.isEmpty:
                ForEach(item.recipes) { recipe in
                    ImportedRecipeLink(recipe: recipe)
                }
            case .failed:
                HStack(spacing: 12) {
                    ImportStatusLine(symbol: "exclamationmark.triangle.fill", tint: .red, title: source, detail: item.errorMessage)
                    Spacer(minLength: 0)
                    Button("Try again", systemImage: "arrow.clockwise", action: onRetry)
                        .labelStyle(.iconOnly)
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.circle)
                }
            default:
                ImportStatusLine(symbol: "arrow.down.circle", tint: .accentColor, title: source, detail: stageText)
                ProgressView(value: progress)
            }
            footer
        }
        .importCard()
    }

    private var footer: some View {
        HStack(spacing: 4) {
            if item.status == .completed {
                Text(verbatim: source)
                Text(verbatim: "·")
            }
            Text(item.createdAt, format: .relative(presentation: .named))
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }

    /// Site the link points to, without the leading "www".
    private var source: String {
        let host = URL(string: item.url)?.host() ?? item.url

        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    private var stageText: String {
        item.stage?.label ?? String(localized: "Waiting")
    }

    /// Share of the stages that are done, counting the running one as half.
    private var progress: Double {
        let stages = RecipeImport.Stage.allCases
        let current = item.stage.flatMap(stages.firstIndex(of:)) ?? 0

        return (Double(current) + 0.5) / Double(stages.count)
    }
}
