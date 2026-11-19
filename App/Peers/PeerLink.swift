import Foundation
import DinnertimeKit
@preconcurrency import MultipeerConnectivity

/// Connects to phones of the household nearby and exchanges shopping list changes with them, without the server.
///
/// Devices find each other over the local network or Bluetooth. A device only accepts an
/// invitation that proves knowledge of the household's secret, the session is encrypted,
/// and every message is sealed with a key made from the secret.
final class PeerLink: NSObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, Sendable {
    /// Bonjour name of the exchange; `NSBonjourServices` lists it.
    private static let serviceType = "mealplan-shop"
    private static let invitationTimeout: TimeInterval = 20

    private let codec: PeerCodec
    private let peerID = MCPeerID(displayName: UUID().uuidString)
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser
    private let onConnect: @Sendable () -> Void
    private let onReceive: @Sendable ([PeerChange]) -> Void

    /// Prepares the exchange for the household with `peerKey`.
    ///
    /// `onConnect` runs when a device joined, `onReceive` with the changes a device sent.
    init(peerKey: String, onConnect: @escaping @Sendable () -> Void, onReceive: @escaping @Sendable ([PeerChange]) -> Void) {
        codec = PeerCodec(peerKey: peerKey)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: Self.serviceType)
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: Self.serviceType)
        self.onConnect = onConnect
        self.onReceive = onReceive
        super.init()
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
    }

    /// Starts looking for devices and being found.
    func start() {
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }

    /// Stops the exchange and leaves the session.
    func stop() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
    }

    /// Sends changes to all connected devices.
    func send(_ changes: [PeerChange]) {
        guard !changes.isEmpty, !session.connectedPeers.isEmpty, let message = try? codec.seal(changes) else {
            return
        }
        try? session.send(message, toPeers: session.connectedPeers, with: .reliable)
    }

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        guard self.peerID.displayName < peerID.displayName else {
            return
        }
        browser.invitePeer(peerID, to: session, withContext: codec.invitation(), timeout: Self.invitationTimeout)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}

    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        let isHousehold = codec.accepts(invitation: context)
        invitationHandler(isHousehold, isHousehold ? session : nil)
    }

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if state == .connected {
            onConnect()
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let changes = codec.open(data) {
            onReceive(changes)
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) {}
}
