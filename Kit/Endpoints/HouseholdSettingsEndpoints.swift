import Foundation

/// The settings of the household.
public enum HouseholdSettingsEndpoints {
    private struct ServingsBody: Encodable {
        let defaultServings: Int
    }

    private struct StockedNeedsBody: Encodable {
        let showStockedNeeds: Bool
    }

    /// `GET /settings/household`: the current settings.
    public static var settings: Endpoint<HouseholdSettings> {
        .resource(.get, "settings/household")
    }

    /// `PATCH /settings/household`: changes the default servings within ``HouseholdSettings/servingsRange``.
    public static func setDefaultServings(_ servings: Int) -> Endpoint<HouseholdSettings> {
        .resource(.patch, "settings/household", body: ServingsBody(defaultServings: servings))
    }

    /// `PATCH /settings/household`: switches the note of what is at home already on the shopping list.
    public static func setShowStockedNeeds(_ shown: Bool) -> Endpoint<HouseholdSettings> {
        .resource(.patch, "settings/household", body: StockedNeedsBody(showStockedNeeds: shown))
    }
}
