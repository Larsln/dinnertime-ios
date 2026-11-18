import MealplannerKit
import Observation

/// The settings of the household, loaded once per session and shared by the screens that preset servings.
@MainActor
@Observable
final class HouseholdStore: ErrorReporting {
    var errorMessage: String?
    /// Servings to preset; the fallback until the settings are loaded.
    private(set) var defaultServings = HouseholdSettings.fallbackServings

    private let session: AppSession

    init(session: AppSession) {
        self.session = session
    }

    /// Loads the settings; on failure the known value stays.
    func load() async {
        if let settings = try? await session.send(HouseholdSettingsEndpoints.settings) {
            defaultServings = settings.defaultServings
        }
    }

    /// Changes the default servings; the change shows at once and is undone if the server rejects it.
    func setDefaultServings(_ servings: Int) async {
        let previous = defaultServings
        defaultServings = servings
        do {
            defaultServings = try await session.send(HouseholdSettingsEndpoints.setDefaultServings(servings)).defaultServings
        } catch {
            defaultServings = previous
            report(error)
        }
    }
}
