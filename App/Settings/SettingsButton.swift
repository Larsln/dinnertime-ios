import SwiftUI

/// Adds the button that opens the settings to the navigation bar.
private struct SettingsToolbar: ViewModifier {
    let session: AppSession

    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Settings", systemImage: "gearshape") {
                        isPresented = true
                    }
                }
            }
            .sheet(isPresented: $isPresented) {
                SettingsView(session: session)
            }
    }
}

extension View {
    /// Makes the settings reachable from the navigation bar of a root screen.
    func settingsToolbar(session: AppSession) -> some View {
        modifier(SettingsToolbar(session: session))
    }
}
