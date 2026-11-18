import Foundation
import MealplannerKit

/// Listens to the change events of the server and has the local copy fetch what changed.
///
/// The connection lives as long as ``run()`` does, which the app starts in the foreground
/// and cancels in the background.
@MainActor
final class RealtimeClient {
    private static let notFoundStatus = 404

    private var hasConnected = false
    private let session: AppSession

    init(session: AppSession) {
        self.session = session
    }

    /// Keeps one connection open until the surrounding task is cancelled.
    ///
    /// After a failure it waits with growing pauses, asks for a new token and connects again.
    /// On servers without realtime it returns at once.
    func run() async {
        var failures = 0
        while !Task.isCancelled {
            do {
                try await listen {
                    failures = 0
                }
            } catch APIError.server(Self.notFoundStatus, _), APIError.unauthorized {
                return
            } catch {
                failures += 1
            }
            try? await Task.sleep(for: .seconds(ReconnectBackoff.delay(beforeAttempt: max(failures, 1))))
        }
    }

    /// Opens the stream and follows it until it ends or fails; `onConnect` runs once the server accepted the connection.
    private func listen(onConnect: () -> Void) async throws {
        guard case let .signedIn(serverURL) = session.phase else {
            throw APIError.unauthorized
        }
        let connection = try await session.send(RealtimeEndpoints.connection)
        let (bytes, response) = try await URLSession.shared.bytes(for: connection.request(serverURL: serverURL))
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        onConnect()
        markReconnected()
        var parser = ServerSentEventParser()
        for try await byte in bytes {
            if let event = parser.consume(byte), !RealtimeArea.areas(in: event).isEmpty {
                session.offline.refreshSoon()
            }
        }
    }

    /// Fetches the changes after a reconnect, because events may have been missed in between.
    private func markReconnected() {
        if hasConnected {
            session.offline.refreshSoon()
        }
        hasConnected = true
    }
}
