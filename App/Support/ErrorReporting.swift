import DinnertimeKit

/// A view model that keeps the message of its last failure for an alert.
@MainActor
protocol ErrorReporting: AnyObject {
    /// Message of the last failure; `nil` once it was dismissed.
    var errorMessage: String? { get set }
}

extension ErrorReporting {
    /// Runs `operation` and keeps the message if it fails.
    ///
    /// Returns whether the operation succeeded.
    @discardableResult
    func attempt(_ operation: () async throws -> Void) async -> Bool {
        do {
            try await operation()
            return true
        } catch {
            report(error)
            return false
        }
    }

    /// Keeps the message of `error`, unless the user needs no alert for it, and notes it in the error log.
    func report(_ error: any Error) {
        if let message = error.userMessage {
            ErrorLog.shared.record(message, context: String(describing: Self.self))
            errorMessage = message
        }
    }
}

extension Error {
    /// Message to present to the user.
    ///
    /// Cancelled work and an expired session need none: the latter returns to the sign-in.
    var userMessage: String? {
        if self is CancellationError || self as? APIError == .unauthorized {
            return nil
        }
        return localizedDescription
    }
}
