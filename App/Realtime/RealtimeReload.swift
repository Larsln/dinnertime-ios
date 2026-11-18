import MealplannerKit
import SwiftUI

/// Reloads the data of a screen when the server reports a change of its area.
private struct RealtimeReload: ViewModifier {
    let area: RealtimeArea
    let reload: () async -> Void

    @Environment(RealtimeClient.self) private var realtime

    func body(content: Content) -> some View {
        content.onChange(of: realtime.revision(of: area)) {
            Task {
                await reload()
            }
        }
    }
}

extension View {
    /// Runs `reload` whenever another device changed data of `area`.
    func reloadsOnChange(of area: RealtimeArea, reload: @escaping () async -> Void) -> some View {
        modifier(RealtimeReload(area: area, reload: reload))
    }
}
