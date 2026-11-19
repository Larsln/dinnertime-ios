import MealplannerKit

/// An offer while it is entered: the shop and, as typed, the size with its unit and the price of the package.
struct OfferDraft: Equatable {
    /// Id of the offer that is corrected; `nil` for a new one.
    var offerID: Int?
    var store: String
    var amount = ""
    /// Unit the size is stated in.
    var unit: OfferUnit
    var price = ""

    /// A new offer, with the shop and the unit that are preselected.
    init(store: String = "", unit: OfferUnit) {
        self.store = store
        self.unit = unit
    }

    /// The values of an existing offer, to correct them; a size stored without a unit takes `fallbackUnit`.
    init(_ offer: ProductOffer, fallbackUnit: OfferUnit, formatter: AmountFormatter = AmountFormatter()) {
        offerID = offer.id
        store = offer.store
        amount = formatter.input(offer.amount)
        unit = offer.unit ?? fallbackUnit
        price = formatter.input(offer.price)
    }

    /// The shop as it is stored; `nil` while none is chosen.
    var storedStore: String? {
        ProductOffer.storedStore(store)
    }

    /// The size of the package; `nil` when none was typed.
    var amountValue: Double? {
        NumberInput.value(amount).flatMap { $0 > 0 ? $0 : nil }
    }

    /// The price of the package; `nil` when none was typed.
    var priceValue: Double? {
        NumberInput.price(price)
    }

    /// Whether the draft can be saved: it names a shop, and what was typed as size and price are numbers.
    var isComplete: Bool {
        storedStore != nil
            && (amount.nilIfBlank == nil || amountValue != nil)
            && (price.nilIfBlank == nil || priceValue != nil)
    }
}
