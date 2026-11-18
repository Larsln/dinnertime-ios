import MealplannerKit
import SwiftUI
import UIKit

/// The cover image of a recipe, or a placeholder while it loads or when there is none.
///
/// Every image is downloaded once and then shown from the device, also without a connection.
struct CoverImage: View {
    let url: URL?

    @Environment(OfflineCoordinator.self) private var offline
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(.quaternary)
                Image(systemName: "fork.knife")
                    .foregroundStyle(.secondary)
            }
        }
        .clipped()
        .task(id: url) {
            image = await load()
        }
    }

    /// The stored image, or the downloaded one, which is stored for the next time.
    private func load() async -> UIImage? {
        guard let url else {
            return nil
        }
        let address = url.relativeString
        if let data = offline.images.data(for: address) {
            return UIImage(data: data)
        }
        guard url.scheme != nil, let (data, response) = try? await URLSession.shared.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200, let image = UIImage(data: data)
        else {
            return nil
        }
        offline.images.store(data, for: address)
        return image
    }
}
