import SwiftUI
import UIKit

/// The line icon of a product, or a neutral basket when the product has none or names an unknown one.
struct ProductIcon: View {
    private static let fallback = "basket"

    let key: String?

    var body: some View {
        Image(Self.assetName(for: key))
            .resizable()
            .scaledToFit()
    }

    private static func assetName(for key: String?) -> String {
        let name = "ProductIcons/\(key ?? fallback)"
        return UIImage(named: name) == nil ? "ProductIcons/\(fallback)" : name
    }
}
