import DinnertimeKit
import Observation

/// The settings of the household, loaded once per session and shared by the screens that preset servings or show prices.
@MainActor
@Observable
final class HouseholdStore: ErrorReporting {
    var errorMessage: String?
    /// Servings to preset; the fallback until the settings are loaded.
    private(set) var defaultServings = HouseholdSettings.fallbackServings
    /// ISO 4217 code of the currency prices are shown in; the fallback until the settings are loaded.
    private(set) var currency = HouseholdSettings.fallbackCurrency
    /// The shop an offer was last entered for in this session, preselected for the next one.
    var lastStore: String?

    private let session: AppSession

    init(session: AppSession) {
        self.session = session
    }

    /// Loads the settings; on failure the known value stays.
    func load() async {
        if let settings = try? await session.send(HouseholdSettingsEndpoints.settings) {
            defaultServings = settings.defaultServings
            currency = settings.currency
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
