import Foundation
import DinnertimeKit
import Observation

/// Lets the user say how many dishes a shared link shows, sends it to the import queue of the server and follows the import while the sheet is open.
///
/// A background transfer waits for the outcome as well, so that the app can notify the user
/// after the sheet was closed. It is cancelled once the sheet itself showed the outcome.
@MainActor
@Observable
final class ShareModel {
    /// Progress of the share.
    enum State: Equatable {
        /// The shared content is searched for a link.
        case preparing
        /// The link waits for the user to choose the number of dishes and start the import.
        case choosing
        case sending
        /// The server works on the import.
        case importing(RecipeImport)
        /// The import produced a recipe; `wasKnown` when the link had been imported before.
        case imported(RecipeImport, wasKnown: Bool)
        /// The server could not turn the link into a recipe.
        case rejected(RecipeImport)
        /// There is no connection; the link is kept and imported later.
        case waiting
        /// The link never reached the import queue.
        case failed(message: String)
    }

    private static let pollInterval: Duration = .seconds(2)

    private(set) var state = State.preparing
    /// Number of dishes the user says the video shows; `nil` lets the server find out.
    var dishCount: Int?
    /// Host of the shared link.
    private(set) var host: String?
    /// Root of the server, to load cover images from.
    private(set) var serverURL: URL?

    private var link: URL?
    private let credentialStore: CredentialStore
    private let shown: ShownImportOutcomes
    private let waitSession: URLSession

    init(credentialStore: CredentialStore = CredentialStore(), shown: ShownImportOutcomes = ShownImportOutcomes()) {
        self.credentialStore = credentialStore
        self.shown = shown
        waitSession = URLSession(configuration: ImportWaitSession(owner: .shareExtension).configuration)
    }

    /// Extracts the link from the shared `items` and offers the choice of the number of dishes.
    func prepare(_ items: [NSExtensionItem]) async {
        guard let credentials = try? credentialStore.load() else {
            state = .failed(message: Self.signInMessage)
            return
        }
        guard let link = await SharedLinkLoader.link(in: items) else {
            state = .failed(message: String(localized: "The shared content contains no link."))
            return
        }
        self.link = link
        host = link.host()
        serverURL = credentials.serverURL
        state = .choosing
    }

    /// Queues the import of the link with the chosen number of dishes and follows it to its outcome.
    func start() async {
        guard state == .choosing, let link else {
            return
        }
        guard let credentials = try? credentialStore.load() else {
            state = .failed(message: Self.signInMessage)
            return
        }
        let dishCount = dishCount
        state = .sending
        await run(credentials) { client in
            do {
                let created = try await client.send(ImportEndpoints.create(url: link, dishCount: dishCount))
                return (created, created.status == .completed)
            } catch APIError.unreachable {
                PendingLinks().add(link, dishCount: dishCount)
                throw LinkKept()
            }
        }
    }

    /// Queues a rejected import again and follows it.
    func retry() async {
        guard case let .rejected(item) = state, let credentials = try? credentialStore.load() else {
            return
        }
        state = .sending
        shown.remove(item.id)
        await run(credentials) { client in
            (try await client.send(ImportEndpoints.retry(id: item.id)), false)
        }
    }

    /// Starts an import with `start` and follows it; `start` also says whether the recipe existed before.
    private func run(_ credentials: Credentials, start: (APIClient) async throws -> (RecipeImport, Bool)) async {
        let client = APIClient(serverURL: credentials.serverURL, token: credentials.token)
        do {
            let (item, wasKnown) = try await start(client)
            if item.isActive {
                try? ImportWaitSession.start(importID: item.id, credentials: credentials, on: waitSession)
            }
            await follow(item, wasKnown: wasKnown, client: client)
        } catch APIError.unauthorized {
            state = .failed(message: Self.signInMessage)
        } catch is LinkKept {
            state = .waiting
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    /// Refreshes the import until it is completed or failed, then keeps the app from notifying about it.
    private func follow(_ item: RecipeImport, wasKnown: Bool, client: APIClient) async {
        var current = item
        while current.isActive {
            state = .importing(current)
            try? await Task.sleep(for: Self.pollInterval)
            if Task.isCancelled {
                return
            }
            current = (try? await client.send(ImportEndpoints.detail(id: current.id))) ?? current
        }
        shown.insert(current.id)
        await ImportWaitSession.cancel(importID: current.id, on: waitSession)
        state = current.status == .completed ? .imported(current, wasKnown: wasKnown) : .rejected(current)
    }

    /// Thrown when the server could not be reached and the link was kept for later.
    private struct LinkKept: Error {}

    private static var signInMessage: String {
        String(localized: "You are not signed in. Open \(AppConfiguration.displayName) and sign in first.")
    }
}
