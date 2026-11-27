import CryptoKit
import Foundation
import Testing
@testable import DinnertimeKit

/// The direct exchange of shopping list changes between devices of one household.
struct PeerExchangeTests {
    private let early = Date(timeIntervalSince1970: 1_795_000_000)
    private var late: Date { early.addingTimeInterval(60) }
    private let codec = PeerCodec(peerKey: "household-secret")

    private func checked(_ store: OfflineStore, item id: Int) async throws -> Bool? {
        try #require(await store.answer(ShoppingEndpoints.current)).response.items.first { $0.id == id }?.isChecked
    }

    @Test func messagesRoundTripWithinAHousehold() throws {
        let changes = [
            PeerChange(key: "k1", clientTime: early, item: PeerChange.Item(serverID: 39, creationKey: nil), action: .check(true)),
            PeerChange(key: "k2", clientTime: late, item: PeerChange.Item(serverID: nil, creationKey: "k2"), action: .add(label: "Kerzen", listID: 11)),
            PeerChange(key: "k3", clientTime: late, item: PeerChange.Item(serverID: nil, creationKey: "k2"), action: .delete),
            PeerChange(key: "k4", clientTime: late, item: PeerChange.Item(serverID: 39, creationKey: nil), action: .skip(true)),
            PeerChange(key: "k5", clientTime: late, item: PeerChange.Item(serverID: 39, creationKey: nil), action: .substitute(name: "Peperoni", productID: 7)),
        ]

        #expect(codec.open(try codec.seal(changes)) == changes)
    }

    @Test func messagesOfStrangersAndTamperedOnesAreRefused() throws {
        let change = PeerChange(key: "k1", clientTime: early, item: PeerChange.Item(serverID: 39, creationKey: nil), action: .check(true))
        let message = try codec.seal([change])
        var tampered = message
        tampered[tampered.count / 2] ^= 0x01

        #expect(PeerCodec(peerKey: "another-household").open(message) == nil)
        #expect(codec.open(tampered) == nil)
        #expect(codec.open(Data("hello".utf8)) == nil)
        #expect(message.range(of: Data("household-secret".utf8)) == nil)
        #expect(message.range(of: Data("k1".utf8)) == nil)
    }

    @Test func invitationsProveTheSecretWithoutSendingIt() {
        let invitation = codec.invitation()

        #expect(codec.accepts(invitation: invitation))
        #expect(invitation != codec.invitation())
        #expect(!PeerCodec(peerKey: "another-household").accepts(invitation: invitation))
        #expect(!codec.accepts(invitation: nil))
        #expect(!codec.accepts(invitation: Data(repeating: 0, count: 48)))
        #expect(invitation.range(of: Data("household-secret".utf8)) == nil)
    }

    @Test func queuedShoppingChangesAreDescribedForOtherDevices() async throws {
        let store = try await OfflineSupport.syncedStore()
        _ = try await store.answer(ShoppingEndpoints.setChecked(true, itemID: 39), now: early)
        let added = try #require(await store.answer(ShoppingEndpoints.addItem(label: "Kerzen", listID: 11), now: late)).response
        _ = try await store.answer(ShoppingEndpoints.setChecked(true, itemID: added.id), now: late)
        _ = try await store.answer(PantryEndpoints.setAmount(7, id: 16))
        let keys = await store.pendingChanges.map(\.key)
        let changes = await store.shoppingChanges

        #expect(changes.map(\.key) == Array(keys.prefix(3)))
        #expect(changes[0] == PeerChange(key: keys[0], clientTime: early, item: PeerChange.Item(serverID: 39, creationKey: nil), action: .check(true)))
        #expect(changes[1].action == .add(label: "Kerzen", listID: 11))
        #expect(changes[1].item == PeerChange.Item(serverID: nil, creationKey: keys[1]))
        #expect(changes[2].item == PeerChange.Item(serverID: nil, creationKey: keys[1]))
        #expect(changes[2].action == .check(true))
    }

    @Test func aReceivedChangeIsAppliedAndQueuedUnderTheSameKeyAndTime() async throws {
        let store = try await OfflineSupport.syncedStore()
        let change = PeerChange(key: "peer-key-1", clientTime: early, item: PeerChange.Item(serverID: 39, creationKey: nil), action: .check(true))
        let areas = await store.apply([change])
        let entry = try #require(await store.pendingChanges.first)

        #expect(areas == [.shopping])
        #expect(try await checked(store, item: 39) == true)
        #expect(entry.key == "peer-key-1")
        #expect(entry.clientTime == early)
        #expect(entry.method == .patch)
        #expect(entry.path == "shopping-list-items/39")
    }

    @Test func aChangeIsOnlyTakenOnce() async throws {
        let store = try await OfflineSupport.syncedStore()
        let change = PeerChange(key: "peer-key-1", clientTime: early, item: PeerChange.Item(serverID: 39, creationKey: nil), action: .check(true))
        _ = await store.apply([change, change])
        let again = await store.apply([change])

        #expect(again.isEmpty)
        #expect(await store.pendingCount == 1)
    }

    @Test func ownChangesComingBackAreIgnored() async throws {
        let store = try await OfflineSupport.syncedStore()
        _ = try await store.answer(ShoppingEndpoints.setChecked(true, itemID: 39), now: early)
        let own = await store.shoppingChanges
        _ = await store.drain { _, _ in .response(status: 200, body: Data("{}".utf8)) }
        let areas = await store.apply(own)

        #expect(areas.isEmpty)
        #expect(await store.pendingCount == 0)
    }

    @Test func theLaterActionWins() async throws {
        let store = try await OfflineSupport.syncedStore()
        _ = try await store.answer(ShoppingEndpoints.setChecked(true, itemID: 39), now: late)
        let older = PeerChange(key: "older", clientTime: early, item: PeerChange.Item(serverID: 39, creationKey: nil), action: .check(false))
        let newer = PeerChange(key: "newer", clientTime: late.addingTimeInterval(5), item: PeerChange.Item(serverID: 39, creationKey: nil), action: .check(false))

        #expect(await store.apply([older]).isEmpty)
        #expect(try await checked(store, item: 39) == true)
        #expect(await store.pendingCount == 1)

        #expect(await store.apply([newer]) == [.shopping])
        #expect(try await checked(store, item: 39) == false)
        #expect(await store.pendingChanges.map(\.key).last == "newer")
    }

    @Test func itemsCreatedOfflineAreRecognisedByTheirCreationKey() async throws {
        let first = try await OfflineSupport.syncedStore()
        let second = try await OfflineSupport.syncedStore()
        let added = try #require(await first.answer(ShoppingEndpoints.addItem(label: "Kerzen", listID: 11), now: early)).response
        _ = try await first.answer(ShoppingEndpoints.setChecked(true, itemID: added.id), now: late)
        _ = await second.apply(await first.shoppingChanges)
        let list = try #require(await second.answer(ShoppingEndpoints.current)).response
        let item = try #require(list.items.first { $0.label == "Kerzen" })

        #expect(item.isManual)
        #expect(item.isChecked)
        #expect(item.id < 0)
        #expect(await second.pendingChanges.map(\.key) == first.pendingChanges.map(\.key))
        #expect(await second.pendingChanges.map(\.clientTime) == [early, late])
        #expect(await second.apply(await first.shoppingChanges).isEmpty)
    }

    @Test func whicheverDeviceDeliversFirstTheOtherEndsWithTheSameItem() async throws {
        let first = try await OfflineSupport.syncedStore()
        let second = try await OfflineSupport.syncedStore()
        let added = try #require(await first.answer(ShoppingEndpoints.addItem(label: "Kerzen", listID: 11), now: early)).response
        _ = await second.apply(await first.shoppingChanges)
        _ = try await first.answer(ShoppingEndpoints.setChecked(true, itemID: added.id), now: late)
        _ = await second.apply(await first.shoppingChanges)
        let answer = OfflineSupport.created(id: 60, extra: ["label": "Kerzen", "is_manual": true])
        let sentByFirst = Recorder()
        let sentBySecond = Recorder()
        _ = await first.drain { entry, _ in
            await sentByFirst.note(entry)
            return entry.method == .post ? answer : .response(status: 200, body: Data("{}".utf8))
        }
        _ = await second.drain { entry, _ in
            await sentBySecond.note(entry)
            return entry.method == .post ? answer : .response(status: 200, body: Data("{}".utf8))
        }

        #expect(await sentByFirst.paths == ["shopping-lists/11/items", "shopping-list-items/60"])
        #expect(await sentBySecond.paths == ["shopping-lists/11/items", "shopping-list-items/60"])
        #expect(await sentByFirst.keys == sentBySecond.keys)
        #expect(try await checked(second, item: 60) == true)
    }

    @Test func aDeletionReachesTheOtherDevice() async throws {
        let first = try await OfflineSupport.syncedStore()
        let second = try await OfflineSupport.syncedStore()
        let added = try #require(await first.answer(ShoppingEndpoints.addItem(label: "Kerzen", listID: 11), now: early)).response
        _ = await second.apply(await first.shoppingChanges)
        _ = try await first.answer(ShoppingEndpoints.deleteItem(id: added.id), now: late)
        _ = await second.apply(await first.shoppingChanges)
        let list = try #require(await second.answer(ShoppingEndpoints.current)).response

        #expect(!list.items.contains { $0.label == "Kerzen" })
        #expect(await second.pendingCount == 2)
    }

    @Test func skippingAndSubstitutingReachTheOtherDevice() async throws {
        let first = try await OfflineSupport.syncedStore()
        let second = try await OfflineSupport.syncedStore()
        _ = try await first.answer(ShoppingEndpoints.setSkipped(true, itemID: 39), now: early)
        _ = await second.apply(await first.shoppingChanges)
        let skipped = try #require(await second.answer(ShoppingEndpoints.current)).response.items.first { $0.id == 39 }

        #expect(await first.shoppingChanges.map(\.action) == [.skip(true)])
        #expect(skipped?.isSkipped == true)

        _ = try await first.answer(ShoppingEndpoints.setSkipped(false, itemID: 39), now: late)
        _ = try await first.answer(ShoppingEndpoints.substitute(label: "Peperoni aus dem Glas", itemID: 39), now: late.addingTimeInterval(5))
        _ = await second.apply(await first.shoppingChanges)
        let replaced = try #require(await second.answer(ShoppingEndpoints.current)).response.items.first { $0.id == 39 }

        #expect(replaced?.isSkipped == false)
        #expect(replaced?.isChecked == true)
        #expect(replaced?.substitute?.name == "Peperoni aus dem Glas")
        #expect(await second.pendingChanges.map(\.key) == first.pendingChanges.map(\.key))
    }

    @Test func changesOfAnUnknownKindDoNotHoldBackTheOthers() throws {
        let known = PeerChange(key: "k1", clientTime: early, item: PeerChange.Item(serverID: 39, creationKey: nil), action: .check(true))
        let payload = try JSONSerialization.jsonObject(with: JSONEncoder().encode([known, known])) as? [[String: Any]]
        var changes = try #require(payload)
        changes[0]["action"] = ["somethingNew": [:]]
        let message = try ChaChaPoly.seal(try JSONSerialization.data(withJSONObject: changes), using: SymmetricKey(data: SHA256.hash(data: Data("household-secret".utf8)))).combined

        #expect(codec.open(message) == [known])
    }

    @Test func changesToUnknownItemsAreSkipped() async throws {
        let store = try await OfflineSupport.syncedStore()
        let unknown = PeerChange(key: "x", clientTime: early, item: PeerChange.Item(serverID: 9999, creationKey: nil), action: .check(true))
        let foreignList = PeerChange(key: "y", clientTime: early, item: PeerChange.Item(serverID: nil, creationKey: "y"), action: .add(label: "Kerzen", listID: 9999))

        #expect(await store.apply([unknown, foreignList]).isEmpty)
        #expect(await store.pendingCount == 0)
    }

    /// Notes what a device sent.
    private actor Recorder {
        private(set) var paths: [String] = []
        private(set) var keys: [String] = []

        func note(_ entry: OutboxEntry) {
            paths.append(entry.path)
            keys.append(entry.key)
        }
    }
}
