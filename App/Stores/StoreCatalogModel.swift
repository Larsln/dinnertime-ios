import MealplannerKit
import Observation

/// Lists the shops of the household and applies changes to them.
@MainActor
@Observable
final class StoreCatalogModel: ErrorReporting {
    var searchText = ""
    var errorMessage: String?
    private(set) var hasLoaded = false

    private var all: [Store] = []
    private let session: AppSession

    init(session: AppSession) {
        self.session = session
    }

    /// The shops whose name contains the search text, by name.
    var stores: [Store] {
        all.matching(searchText)
    }

    /// Loads all shops.
    func load() async {
        await attempt {
            all = try await session.send(StoreEndpoints.list)
            hasLoaded = true
        }
    }

    /// Creates a shop with `name` and lists it.
    func create(name: String) async {
        await attempt {
            _ = try await session.send(StoreEndpoints.create(name: name))
            all = try await session.send(StoreEndpoints.list)
        }
    }

    /// States whether the household buys at a shop at the moment; the change shows at once and is undone if it is rejected.
    func setActive(_ isActive: Bool, for store: Store) async {
        var optimistic = store
        optimistic.isActive = isActive
        replace(optimistic)
        do {
            replace(try await session.send(StoreEndpoints.setActive(isActive, id: store.id)))
        } catch {
            replace(store)
            report(error)
        }
    }

    /// Renames a shop and puts it where its new name belongs.
    func rename(_ store: Store, to name: String) async {
        await attempt {
            _ = try await session.send(StoreEndpoints.rename(id: store.id, to: name))
            all = try await session.send(StoreEndpoints.list)
        }
    }

    /// Deletes a shop together with its offers.
    func delete(_ store: Store) async {
        await attempt {
            try await session.send(StoreEndpoints.delete(id: store.id))
            all.removeAll { $0.id == store.id }
        }
    }

    private func replace(_ store: Store) {
        if let index = all.firstIndex(where: { $0.id == store.id }) {
            all[index] = store
        }
    }
}
