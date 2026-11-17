import SwiftUI

/// The cover image of a recipe, or a placeholder while it loads or when there is none.
struct CoverImage: View {
    let url: URL?

    @Environment(AppSession.self) private var session

    var body: some View {
        AsyncImage(url: url.map(session.absoluteURL(for:))) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .clipped()
    }

    private var placeholder: some View {
        ZStack {
            Rectangle()
                .fill(.quaternary)
            Image(systemName: "fork.knife")
                .foregroundStyle(.secondary)
        }
    }
}
