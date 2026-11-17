import Foundation
import MealplannerKit

/// The input for a new pantry item.
struct PantryItemDraft {
    let product: Product
    var amount: Double?
    /// Day the package was opened; `nil` for unopened stock.
    var openedOn: Date? = .now
    /// Fixed expiry; without it the server derives one from the shelf life of the product.
    var expiresOn: Date?

    /// Whether the draft can be sent.
    var isComplete: Bool {
        (amount ?? 0) > 0
    }
}
