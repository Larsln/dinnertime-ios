import Foundation
import MealplannerKit
import Observation

/// Loads the current shopping list and applies changes to it.
@MainActor
@Observable
final class ShoppingModel: ErrorReporting {
    private static let notFoundStatus = 404

    var errorMessage: String?
    private(set) var list: ShoppingList?
    private(set) var hasLoaded = false
    private(set) var isWorking = false

    private let session: AppSession

    init(session: AppSession) {
        self.session = session
    }

    /// Whether the leftovers of the list can still be moved to the pantry.
    var canStockLeftovers: Bool {
        list.map { $0.leftoversStockedAt == nil } ?? false
    }

    /// Whether the list was made for `week`, so that updating it refreshes instead of replacing it.
    func covers(_ week: Week) -> Bool {
        list.map { $0.startsOn == week.start && $0.endsOn == week.end } ?? false
    }

    /// Loads the list of the latest period; a server without lists has none.
    func load() async {
        await attempt {
            do {
                list = try await session.send(ShoppingEndpoints.current)
            } catch APIError.server(Self.notFoundStatus, _) {
                list = nil
            }
            hasLoaded = true
        }
    }

    /// Creates the list for `week` from the plan, or refreshes it if it exists.
    func update(for week: Week) async {
        await work {
            list = try await session.send(ShoppingEndpoints.create(from: week.start, to: week.end))
        }
    }

    /// Moves the leftovers of the list to the pantry.
    func stockLeftovers() async {
        guard let listID = list?.id else {
            return
        }
        await work {
            list = try await session.send(ShoppingEndpoints.stockLeftovers(listID: listID))
        }
    }

    /// Adds a manual item from free text; the server links a product of that name.
    func addItem(label: String) async {
        let label = label.trimmingCharacters(in: .whitespaces)
        guard let listID = list?.id, !label.isEmpty else {
            return
        }
        await attempt {
            show(try await session.send(ShoppingEndpoints.addItem(label: label, listID: listID)))
        }
    }

    /// Adds a product as manual item; one that is on the list already is brought back unchecked.
    func addItem(_ product: Product) async {
        guard let listID = list?.id else {
            return
        }
        await attempt {
            show(try await session.send(ShoppingEndpoints.addItem(productID: product.id, listID: listID)))
        }
    }

    /// The first `limit` products whose name or alias contains `text`, those that start with it first.
    func products(matching text: String, limit: Int = 6) async -> [Product] {
        guard let found = try? await session.send(ProductEndpoints.search(text)).items else {
            return []
        }
        let leading = found.filter { $0.name.range(of: text, options: [.caseInsensitive, .anchored]) != nil }
        let ids = Set(leading.map(\.id))
        return Array((leading + found.filter { !ids.contains($0.id) }).prefix(limit))
    }

    /// Removes an item.
    func delete(_ item: ShoppingListItem) async {
        await attempt {
            try await session.send(ShoppingEndpoints.deleteItem(id: item.id))
            list?.items.removeAll { $0.id == item.id }
        }
    }

    /// Checks an item off or on again; the change shows at once and is undone if the server rejects it.
    func toggle(_ item: ShoppingListItem) async {
        let checked = !item.isChecked
        var optimistic = item
        optimistic.checkedAt = checked ? .now : nil
        replace(optimistic)
        do {
            replace(try await session.send(ShoppingEndpoints.setChecked(checked, itemID: item.id)))
        } catch {
            replace(item)
            report(error)
        }
    }

    private func work(_ operation: () async throws -> Void) async {
        isWorking = true
        defer { isWorking = false }
        await attempt(operation)
    }

    private func show(_ item: ShoppingListItem) {
        if list?.items.contains(where: { $0.id == item.id }) == true {
            replace(item)
        } else {
            list?.items.append(item)
        }
    }

    private func replace(_ item: ShoppingListItem) {
        if let index = list?.items.firstIndex(where: { $0.id == item.id }) {
            list?.items[index] = item
        }
    }
}
