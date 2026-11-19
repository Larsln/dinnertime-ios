import Foundation
import DinnertimeKit

/// Keeping track of whether the server can be reached and trying again when it cannot.
extension OfflineCoordinator {
    func networkChanged(isAvailable: Bool) {
        let wasAvailable = hasNetwork
        hasNetwork = isAvailable
        if !isAvailable {
            isOnline = false
        } else if !wasAvailable {
            refreshSoon()
        }
    }

    func markReachable() {
        failures = 0
        retry?.cancel()
        isOnline = hasNetwork
    }

    func markUnreachable() {
        isOnline = false
        scheduleRetry()
    }

    /// Tries again after a pause that grows with every failure, as long as something waits or the server is away.
    func scheduleRetry() {
        guard retry == nil || retry?.isCancelled == true else {
            return
        }
        failures += 1
        let delay = ReconnectBackoff.delay(beforeAttempt: failures)
        retry = Task {
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else {
                return
            }
            retry = nil
            await refresh()
        }
    }
}
