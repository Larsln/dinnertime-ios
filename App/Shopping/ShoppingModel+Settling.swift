import DinnertimeKit
import Foundation

/// Settling items without buying their product: skipping them and buying something else instead.
extension ShoppingModel {
    /// Strikes an item off the list without buying it, or opens it again.
    ///
    /// A skipped item adds nothing to the pantry and does not come back when the list is refreshed.
    /// The change shows at once and is undone if the server rejects it.
    func setSkipped(_ skipped: Bool, _ item: ShoppingListItem) async {
        var optimistic = item
        optimistic.skippedAt = skipped ? .now : nil
        await settle(item, showing: optimistic, with: ShoppingEndpoints.setSkipped(skipped, itemID: item.id))
    }

    /// Checks an item off with what was bought in its place; the product of the item is not counted as bought.
    func substitute(_ choice: SubstituteChoice, for item: ShoppingListItem) async {
        var optimistic = item
        optimistic.checkedAt = .now
        switch choice {
        case let .product(product):
            optimistic.substitute = .init(productID: product.id, name: product.name)
            await settle(item, showing: optimistic, with: ShoppingEndpoints.substitute(productID: product.id, itemID: item.id))
        case let .text(text):
            optimistic.substitute = .init(productID: nil, name: text)
            await settle(item, showing: optimistic, with: ShoppingEndpoints.substitute(label: text, itemID: item.id))
        }
    }

    private func settle(_ item: ShoppingListItem, showing optimistic: ShoppingListItem, with endpoint: Endpoint<ShoppingListItem>) async {
        replace(optimistic)
        do {
            replace(try await session.send(endpoint))
        } catch {
            replace(item)
            report(error)
        }
    }
}
