import Foundation

/// The pantry.
public enum PantryEndpoints {
    private struct CreateBody: Encodable {
        let productId: Int
        let amount: Double
        let openedOn: DayDate?
        let expiresOn: DayDate?
    }

    private struct AmountBody: Encodable {
        let amount: Double
    }

    /// `GET /pantry`: all items, soonest expiry first.
    public static var list: Endpoint<[PantryItem]> {
        .resource(.get, "pantry")
    }

    /// `POST /pantry`: adds an amount of a product.
    ///
    /// Without `expiresOn` the server derives the expiry from the shelf life of the product.
    public static func create(productID: Int, amount: Double, openedOn: DayDate?, expiresOn: DayDate?) -> Endpoint<PantryItem> {
        let body = CreateBody(productId: productID, amount: amount, openedOn: openedOn, expiresOn: expiresOn)
        return .resource(.post, "pantry", body: body)
    }

    /// `PATCH /pantry/{id}`: changes the amount of an item.
    public static func setAmount(_ amount: Double, id: Int) -> Endpoint<PantryItem> {
        .resource(.patch, "pantry/\(id)", body: AmountBody(amount: amount))
    }

    /// `DELETE /pantry/{id}`: removes an item.
    public static func delete(id: Int) -> Endpoint<Void> {
        .empty(.delete, "pantry/\(id)")
    }
}
