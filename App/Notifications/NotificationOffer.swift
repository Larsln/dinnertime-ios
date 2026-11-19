import SwiftUI

/// A card that explains what notifications are for and lets the user allow them.
struct NotificationOffer: View {
    let permission: NotificationPermission

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Allow notifications to learn when a recipe you shared was imported or could not be imported.", systemImage: "bell.badge")
                .font(.subheadline)
            HStack {
                Spacer()
                Button("Not now") {
                    permission.decline()
                }
                .buttonStyle(.bordered)
                Button("Allow") {
                    Task {
                        await permission.request()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .surface(.accentSoft)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

extension View {
    /// Shows the offer to allow notifications below a list while it stands.
    func notificationOffer(_ permission: NotificationPermission) -> some View {
        safeAreaInset(edge: .bottom) {
            if permission.isOffered {
                NotificationOffer(permission: permission)
            }
        }
    }
}
