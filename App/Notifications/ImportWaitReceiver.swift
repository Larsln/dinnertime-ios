import Foundation
import DinnertimeKit

/// Receives the answers of the background transfers that wait for imports.
final class ImportWaitReceiver: NSObject, URLSessionDownloadDelegate, Sendable {
    private let onOutcome: @Sendable (ImportOutcome) -> Void
    private let onFinishEvents: @Sendable (String) -> Void

    /// Reports every outcome and, per session identifier, when the system delivered all its events.
    init(onOutcome: @escaping @Sendable (ImportOutcome) -> Void, onFinishEvents: @escaping @Sendable (String) -> Void) {
        self.onOutcome = onOutcome
        self.onFinishEvents = onFinishEvents
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let data = try? Data(contentsOf: location), let outcome = ImportOutcome(waitAnswer: data) {
            onOutcome(outcome)
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        if let identifier = session.configuration.identifier {
            onFinishEvents(identifier)
        }
    }
}
