import MealplannerKit
import Observation

/// Loads the pantry and applies changes to it.
@MainActor
@Observable
final class PantryModel: ErrorReporting {
    var errorMessage: String?
    private(set) var items: [PantryItem] = []
    private(set) var hasLoaded = false

    private let session: AppSession

    init(session: AppSession) {
        self.session = session
    }

    /// Loads all items, soonest expiry first.
    func load() async {
        await attempt {
            items = try await session.send(PantryEndpoints.list)
            hasLoaded = true
        }
    }

    /// Adds an amount of a product; returns whether the server accepted it.
    func add(_ draft: PantryItemDraft) async -> Bool {
        guard let amount = draft.amount else {
            return false
        }
        return await attempt {
            let endpoint = PantryEndpoints.create(
                productID: draft.product.id,
                amount: amount,
                openedOn: draft.openedOn.map { DayDate($0) },
                expiresOn: draft.expiresOn.map { DayDate($0) }
            )
            _ = try await session.send(endpoint)
            items = try await session.send(PantryEndpoints.list)
        }
    }

    /// Changes the amount of an item; returns whether the server accepted it.
    func setAmount(_ amount: Double, of item: PantryItem) async -> Bool {
        await attempt {
            let updated = try await session.send(PantryEndpoints.setAmount(amount, id: item.id))
            if let index = items.firstIndex(where: { $0.id == updated.id }) {
                items[index] = updated
            }
        }
    }

    /// Removes an item.
    func delete(_ item: PantryItem) async {
        await attempt {
            try await session.send(PantryEndpoints.delete(id: item.id))
            items.removeAll { $0.id == item.id }
        }
    }
}
