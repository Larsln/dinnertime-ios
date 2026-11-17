import SwiftUI

/// Shows setup, sign-in or the main interface, depending on the state of the session.
struct RootView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        Group {
            switch session.phase {
            case .launching:
                ProgressView()
            case .serverSetup:
                ServerSetupView(session: session)
            case let .signIn(connection):
                SignInView(session: session, connection: connection)
            case .signedIn:
                MainTabView(session: session)
            }
        }
        .task {
            await session.start()
        }
    }
}
