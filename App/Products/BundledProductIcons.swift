import Foundation
import DinnertimeKit

extension ProductIconCatalog {
    /// The icon set the app ships, read from the manifest in its resources.
    static let bundled: ProductIconCatalog? = Bundle.main.url(forResource: "ProductIcons", withExtension: "json")
        .flatMap { try? Data(contentsOf: $0) }
        .flatMap { try? ProductIconCatalog(manifest: $0) }

    /// Language the icons are named in: the one the app is shown in.
    static var languageCode: String {
        Bundle.main.preferredLocalizations.first ?? "en"
    }
}
