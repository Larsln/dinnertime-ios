import SwiftUI

/// Shown after sign-in until the data of the household was loaded for the first time.
struct FirstSyncView: View {
    @Environment(OfflineCoordinator.self) private var offline

    var body: some View {
        if offline.firstSyncFailed {
            ContentUnavailableView {
                Label("No connection", systemImage: "wifi.slash")
            } description: {
                Text("The data of your household is loaded as soon as the server can be reached.")
            } actions: {
                Button("Try again") {
                    offline.refreshSoon()
                }
            }
        } else {
            VStack(spacing: 12) {
                ProgressView()
                Text("Loading the data of your household…")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
