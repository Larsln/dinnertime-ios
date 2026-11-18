import Foundation

/// Remembers the imports whose outcome the share extension already showed, so that the app does not notify about them again.
///
/// The record lives in the defaults of the App Group, which both processes read.
public struct ShownImportOutcomes: Sendable {
    private static let key = "shownImportOutcomes"
    private static let capacity = 50

    private let suiteName: String?

    /// Uses the defaults named `suiteName`, by default those of the App Group; builds without a group use the private ones.
    public init(suiteName: String? = AppConfiguration.appGroup) {
        self.suiteName = suiteName
    }

    /// Whether the user saw the outcome of the import in the share extension.
    public func contains(_ importID: Int) -> Bool {
        ids.contains(importID)
    }

    /// Records that the outcome of an import was shown; only the most recent imports are kept.
    public func insert(_ importID: Int) {
        defaults.set(Array((ids.filter { $0 != importID } + [importID]).suffix(Self.capacity)), forKey: Self.key)
    }

    /// Forgets an import that runs again after a retry.
    public func remove(_ importID: Int) {
        defaults.set(ids.filter { $0 != importID }, forKey: Self.key)
    }

    /// Whether the app should notify about `outcome`: only when it is final and the extension did not show it.
    public func shouldNotify(about outcome: ImportOutcome) -> Bool {
        outcome.notice != nil && !contains(outcome.importID)
    }

    private var defaults: UserDefaults {
        suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
    }

    private var ids: [Int] {
        defaults.array(forKey: Self.key) as? [Int] ?? []
    }
}
