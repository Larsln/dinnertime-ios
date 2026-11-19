import SwiftUI

/// A small label that says when the server is away and how many changes wait to be sent.
struct OfflineIndicator: View {
    @Environment(OfflineCoordinator.self) private var offline

    var body: some View {
        if !offline.isOnline || offline.pendingCount > 0 {
            HStack(spacing: 6) {
                Image(systemName: offline.isOnline ? "arrow.triangle.2.circlepath" : "wifi.slash")
                if !offline.isOnline {
                    Text("Offline")
                }
                if offline.pendingCount > 0 {
                    Text("\(offline.pendingCount) changes waiting")
                }
            }
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(.inkMuted)
            .background(.surface, in: .capsule)
            .overlay {
                Capsule()
                    .strokeBorder(.line)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

/// The hint under an action that only works with a connection to the server.
struct ConnectionHint: View {
    var body: some View {
        Label("Needs a connection to the server.", systemImage: "wifi.slash")
            .font(.footnote)
            .foregroundStyle(.inkMuted)
    }
}
