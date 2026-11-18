import Foundation
import Observation
import UserNotifications

/// Decides when to offer notifications to the user and asks the system for the permission.
@MainActor
@Observable
final class NotificationPermission {
    private static let declinedKey = "notificationOfferDeclined"

    /// Whether the offer is shown: the system was not asked yet and the user did not decline the offer.
    private(set) var isOffered = false

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Reads the state of the permission.
    func refresh() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isOffered = settings.authorizationStatus == .notDetermined && !defaults.bool(forKey: Self.declinedKey)
    }

    /// Lets the system ask the user.
    func request() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        await refresh()
    }

    /// Withdraws the offer for good.
    func decline() {
        defaults.set(true, forKey: Self.declinedKey)
        isOffered = false
    }
}
