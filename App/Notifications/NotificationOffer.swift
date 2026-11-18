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
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
