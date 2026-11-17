import Foundation

extension Bundle {
    /// Bundle of the shared framework, which holds its localized strings.
    static let kit = Bundle(for: KitBundleToken.self)
}

/// Anchor used to locate the framework bundle.
private final class KitBundleToken {}
