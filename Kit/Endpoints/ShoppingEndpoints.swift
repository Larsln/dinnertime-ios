import Foundation

/// Shopping lists and their items.
public enum ShoppingEndpoints {
    private struct PeriodBody: Encodable {
        let from: DayDate
        let to: DayDate
    }

    private struct LabelBody: Encodable {
        let label: String
    }

    private struct ProductBody: Encodable {
        let productId: Int
    }

    private struct CheckedBody: Encodable {
        let checked: Bool
    }

    private struct SkippedBody: Encodable {
        let skipped: Bool
    }

    private struct SubstituteBody: Encodable {
        let checked = true
        var substituteProductId: Int?
        var substituteLabel: String?
    }

    /// `GET /shopping-lists/current`: the list of the latest period; answers `404` if there is none.
    public static var current: Endpoint<ShoppingList> {
        .resource(.get, "shopping-lists/current")
    }

    /// `POST /shopping-lists`: creates the list of a period or refreshes the existing one.
    public static func create(from: DayDate, to: DayDate) -> Endpoint<ShoppingList> {
        .resource(.post, "shopping-lists", body: PeriodBody(from: from, to: to))
    }

    /// `POST /shopping-lists/{id}/stock-leftovers`: moves the leftovers of a list to the pantry.
    public static func stockLeftovers(listID: Int) -> Endpoint<ShoppingList> {
        .resource(.post, "shopping-lists/\(listID)/stock-leftovers")
    }

    /// `POST /shopping-lists/{id}/items`: adds a manual item from free text.
    ///
    /// The server links a product whose name or alias equals `label`, ignoring case.
    public static func addItem(label: String, listID: Int) -> Endpoint<ShoppingListItem> {
        .resource(.post, "shopping-lists/\(listID)/items", body: LabelBody(label: label))
    }

    /// `POST /shopping-lists/{id}/items`: adds a product as manual item.
    ///
    /// A list that already has a manual item for the product answers with that item, unchecked.
    public static func addItem(productID: Int, listID: Int) -> Endpoint<ShoppingListItem> {
        .resource(.post, "shopping-lists/\(listID)/items", body: ProductBody(productId: productID))
    }

    /// `PATCH /shopping-list-items/{id}`: checks an item off or on again.
    public static func setChecked(_ checked: Bool, itemID: Int) -> Endpoint<ShoppingListItem> {
        .resource(.patch, "shopping-list-items/\(itemID)", body: CheckedBody(checked: checked))
    }

    /// `PATCH /shopping-list-items/{id}`: strikes an item off the list without buying it, or opens it again.
    ///
    /// A skipped item adds nothing to the pantry and a refresh of the list does not bring its product back.
    public static func setSkipped(_ skipped: Bool, itemID: Int) -> Endpoint<ShoppingListItem> {
        .resource(.patch, "shopping-list-items/\(itemID)", body: SkippedBody(skipped: skipped))
    }

    /// `PATCH /shopping-list-items/{id}`: checks an item off with the product that was bought in its place.
    public static func substitute(productID: Int, itemID: Int) -> Endpoint<ShoppingListItem> {
        .resource(.patch, "shopping-list-items/\(itemID)", body: SubstituteBody(substituteProductId: productID))
    }

    /// `PATCH /shopping-list-items/{id}`: checks an item off with what was bought in its place, as free text.
    ///
    /// The server links a product whose name or alias equals `label`, ignoring case.
    public static func substitute(label: String, itemID: Int) -> Endpoint<ShoppingListItem> {
        .resource(.patch, "shopping-list-items/\(itemID)", body: SubstituteBody(substituteLabel: label))
    }

    /// `DELETE /shopping-list-items/{id}`: removes an item.
    public static func deleteItem(id: Int) -> Endpoint<Void> {
        .empty(.delete, "shopping-list-items/\(id)")
    }
}
