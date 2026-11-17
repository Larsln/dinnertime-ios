import Foundation
import MealplannerKit
import Observation

/// Sends a shared link to the import queue of the server.
@MainActor
@Observable
final class ShareModel {
    /// Progress of the share.
    enum State: Equatable {
        case sending
        /// The server queued the import.
        case queued
        /// The link was imported before; the recipe has this title.
        case alreadyImported(title: String)
        case failed(message: String)
    }

    private(set) var state = State.sending

    private let credentialStore: CredentialStore

    init(credentialStore: CredentialStore = CredentialStore()) {
        self.credentialStore = credentialStore
    }

    /// Whether the share reached the server.
    var didSucceed: Bool {
        switch state {
        case .queued, .alreadyImported: true
        case .sending, .failed: false
        }
    }

    /// Extracts the link from the shared `items` and queues its import.
    func share(_ items: [NSExtensionItem]) async {
        state = await result(for: items)
    }

    private func result(for items: [NSExtensionItem]) async -> State {
        guard let credentials = try? credentialStore.load() else {
            return .failed(message: Self.signInMessage)
        }
        guard let link = await SharedLinkLoader.link(in: items) else {
            return .failed(message: String(localized: "The shared content contains no link."))
        }
        do {
            let client = APIClient(serverURL: credentials.serverURL, token: credentials.token)
            let created = try await client.send(ImportEndpoints.create(url: link))
            if created.status == .completed, let recipe = created.recipe {
                return .alreadyImported(title: recipe.title)
            }
            return .queued
        } catch APIError.unauthorized {
            return .failed(message: Self.signInMessage)
        } catch {
            return .failed(message: error.localizedDescription)
        }
    }

    private static var signInMessage: String {
        String(localized: "You are not signed in. Open \(AppConfiguration.displayName) and sign in first.")
    }
}
