import Foundation
import DinnertimeKit

/// One ingredient line while it is edited; its component is the group it belongs to.
struct IngredientDraft: Identifiable {
    let id = UUID()
    var product: Product?
    var quantity: Double?
    /// Unit of the quantity; `nil` counts pieces.
    var unitID: Int?
    var note = ""
    var isEstimated = false
    /// Text of a line without a product.
    var rawText = ""

    init() {}

    init(_ ingredient: Ingredient) {
        product = ingredient.product
        quantity = ingredient.quantity
        unitID = ingredient.unit?.id
        note = ingredient.note ?? ""
        isEstimated = ingredient.isEstimated
        rawText = ingredient.rawText ?? ""
    }

    /// The line as the API accepts it within `section`; `nil` for lines that name neither a product nor a text.
    func input(section: String?) -> RecipeInput.Ingredient? {
        guard product != nil || rawText.nilIfBlank != nil else {
            return nil
        }
        return RecipeInput.Ingredient(
            section: section,
            productID: product?.id,
            quantity: quantity,
            unitID: unitID,
            note: note.nilIfBlank,
            isEstimated: isEstimated,
            rawText: product == nil ? rawText.nilIfBlank : nil
        )
    }
}
