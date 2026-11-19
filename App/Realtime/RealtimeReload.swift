import DinnertimeKit
import SwiftUI

/// Reloads the data of a screen when the local copy of its area changed.
private struct RealtimeReload: ViewModifier {
    let area: RealtimeArea
    let reload: () async -> Void

    @Environment(OfflineCoordinator.self) private var offline

    func body(content: Content) -> some View {
        content.onChange(of: offline.revision(of: area)) {
            Task {
                await reload()
            }
        }
    }
}

/// Fetches the changes of the server before a screen reloads on pull to refresh.
private struct ServerRefresh: ViewModifier {
    let reload: () async -> Void

    @Environment(OfflineCoordinator.self) private var offline

    func body(content: Content) -> some View {
        content.refreshable {
            await offline.refresh()
            await reload()
        }
    }
}

extension View {
    /// Runs `reload` whenever data of `area` changed, on this device or on another.
    func reloadsOnChange(of area: RealtimeArea, reload: @escaping () async -> Void) -> some View {
        modifier(RealtimeReload(area: area, reload: reload))
    }

    /// Adds pull to refresh that syncs with the server and then runs `reload`.
    func refreshesFromServer(reload: @escaping () async -> Void) -> some View {
        modifier(ServerRefresh(reload: reload))
    }
}
