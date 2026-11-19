import Foundation
import DinnertimeKit

/// The exchange of shopping list changes with phones of the household nearby.
extension OfflineCoordinator {
    /// Starts exchanging shopping list changes with phones of the household nearby, while the list is on screen.
    ///
    /// The exchange runs whether or not the server can be reached: every change carries its own
    /// key, so one that arrives by both ways is only applied once.
    func startSharingShoppingList() {
        guard peers == nil, let key = peerKeys.load() else {
            return
        }
        let link = PeerLink(peerKey: key) { [weak self] in
            Task { @MainActor in
                await self?.sendQueuedShoppingChanges()
            }
        } onReceive: { [weak self] changes in
            Task { @MainActor in
                await self?.receive(changes)
            }
        }
        peers = link
        link.start()
    }

    /// Ends the exchange with phones nearby.
    func stopSharingShoppingList() {
        peers?.stop()
        peers = nil
    }

    func sendQueuedShoppingChanges() async {
        peers?.send(await store.shoppingChanges)
    }

    func receive(_ changes: [PeerChange]) async {
        bump(await store.apply(changes))
        pendingCount = await store.pendingCount
        refreshSoon()
    }
}
