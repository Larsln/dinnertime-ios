import DinnertimeKit
import SwiftUI

/// Cover, title, course and time of the recipe an import produced.
struct ImportedRecipeView: View {
    private static let imageHeight: CGFloat = 150

    let recipe: RecipeSummary
    /// Root of the server, which cover addresses may be relative to.
    let serverURL: URL?

    var body: some View {
        VStack(spacing: 10) {
            if let url = coverURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(.quaternary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: Self.imageHeight)
                .clipShape(.rect(cornerRadius: 14))
            }
            Text(verbatim: recipe.title)
                .font(.headline)
                .multilineTextAlignment(.center)
            if !details.isEmpty {
                Text(verbatim: details)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var coverURL: URL? {
        guard let url = recipe.coverURL else {
            return nil
        }
        return url.scheme == nil ? URL(string: url.relativeString, relativeTo: serverURL)?.absoluteURL : url
    }

    private var details: String {
        let minutes = (recipe.prepMinutes ?? 0) + (recipe.cookMinutes ?? 0)
        let time = minutes > 0 ? Duration.seconds(minutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated)) : nil
        return [recipe.courseName, time].compactMap { $0 }.joined(separator: " · ")
    }
}
