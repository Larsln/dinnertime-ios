import MealplannerKit
import SwiftUI
import UIKit

/// The line icon of a product: its own, else the one of its store section, else the general one.
struct ProductIcon: View {
    /// Key of the icon of the product; `nil` or an unknown key falls back to the store section.
    let key: String?
    /// Key of the store section of the product.
    let sectionKey: String?

    var body: some View {
        Image(Self.assetName(icon: key, sectionKey: sectionKey))
            .resizable()
            .scaledToFit()
    }

    private static func assetName(icon: String?, sectionKey: String?) -> String {
        let names = ProductIconCatalog.candidates(icon: icon, sectionKey: sectionKey).map { "ProductIcons/\($0)" }
        return names.first { UIImage(named: $0) != nil } ?? "ProductIcons/\(ProductIconCatalog.fallbackKey)"
    }
}
