import Foundation

/// The choice of how many dishes a shared video shows, which keeps the import from mixing them up.
public enum DishCount {
    /// What the user can pick; `nil` lets the server find out.
    public static let choices: [Int?] = [nil] + (1...8).map { $0 }

    /// Name of the choice, in the language of the device.
    public static var title: String {
        String(localized: "Dishes in the video", bundle: .kit)
    }

    /// Name of one of the ``choices``.
    public static func label(for count: Int?) -> String {
        count.map { $0.formatted() } ?? String(localized: "Automatic", bundle: .kit)
    }
}
