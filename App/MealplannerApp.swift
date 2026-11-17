import SwiftUI

/// Entry point of the app.
@main
struct MealplannerApp: App {
    @State private var session = AppSession()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
        }
    }
}
