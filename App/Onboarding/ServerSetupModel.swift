import Foundation
import DinnertimeKit
import Observation

/// Asks for the address of the server and validates it.
@MainActor
@Observable
final class ServerSetupModel: ErrorReporting {
    var address: String
    var errorMessage: String?
    private(set) var isConnecting = false

    private let session: AppSession

    init(session: AppSession) {
        self.session = session
        address = session.lastServerURL?.absoluteString ?? ""
    }

    /// Whether the input is complete enough to try it.
    var canConnect: Bool {
        !address.trimmingCharacters(in: .whitespaces).isEmpty && !isConnecting
    }

    /// Checks the address against the server and moves on to the sign-in.
    func connect() async {
        guard let url = ServerAddress.normalize(address) else {
            errorMessage = String(localized: "Please enter a valid server address.")
            return
        }
        isConnecting = true
        defer { isConnecting = false }
        await attempt {
            try await session.connect(to: url)
        }
    }
}
