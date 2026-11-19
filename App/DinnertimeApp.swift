import SwiftUI

/// Entry point of the app.
@main
struct DinnertimeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var session = AppSession()

    init() {
        BrandFont.applyToNavigationTitles()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .environment(session.offline)
        }
    }
}
