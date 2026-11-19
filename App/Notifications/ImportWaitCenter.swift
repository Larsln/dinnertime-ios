import Foundation
import DinnertimeKit
import UserNotifications

/// Turns the outcomes of imports that finished in the background into local notifications.
///
/// The share extension starts a transfer that waits for each import. The system hands its
/// events to the app, which notifies about the outcome unless the extension already showed
/// it, and waits again when the server gave up waiting before the import finished.
@MainActor
final class ImportWaitCenter {
    static let shared = ImportWaitCenter()

    private var sessions: [String: URLSession] = [:]
    private var completions: [String: () -> Void] = [:]
    private let shown = ShownImportOutcomes()
    private let credentialStore = CredentialStore()

    /// Connects to the transfers the app itself started, so that their answers arrive.
    func resume() {
        _ = session(of: ImportWaitSession(owner: .app))
    }

    /// Connects to the session the system reports events for and keeps the handler to call once all are delivered.
    func attach(identifier: String, completion: @escaping () -> Void) {
        let known = ImportWaitSession.Owner.allCases.map { ImportWaitSession(owner: $0) }
        guard let session = known.first(where: { $0.owns(identifier) }) else {
            completion()
            return
        }
        completions[identifier] = completion
        _ = self.session(of: session)
    }

    private func session(of description: ImportWaitSession) -> URLSession {
        if let session = sessions[description.identifier] {
            return session
        }
        let receiver = ImportWaitReceiver { outcome in
            Task { @MainActor in
                ImportWaitCenter.shared.handle(outcome)
            }
        } onFinishEvents: { identifier in
            Task { @MainActor in
                ImportWaitCenter.shared.completions.removeValue(forKey: identifier)?()
            }
        }
        let session = URLSession(configuration: description.configuration, delegate: receiver, delegateQueue: nil)
        sessions[description.identifier] = session
        return session
    }

    private func handle(_ outcome: ImportOutcome) {
        if case let .unfinished(importID) = outcome, let credentials = try? credentialStore.load() {
            try? ImportWaitSession.start(importID: importID, credentials: credentials, on: session(of: ImportWaitSession(owner: .app)))
        }
        if shown.shouldNotify(about: outcome), let notice = outcome.notice {
            post(notice)
        }
    }

    private func post(_ notice: ImportNotice) {
        let content = UNMutableNotificationContent()
        content.title = notice.title
        content.body = notice.body
        content.sound = .default
        content.userInfo = notice.userInfo
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "import-\(notice.importID)", content: content, trigger: nil))
    }
}
