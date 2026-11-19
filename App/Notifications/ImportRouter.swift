import DinnertimeKit
import Observation

/// Carries the screen a tapped notification asks for to the views that can show it.
@MainActor
@Observable
final class ImportRouter {
    static let shared = ImportRouter()

    /// Where to go next; cleared by the view that went there.
    var destination: ImportDestination?
}
