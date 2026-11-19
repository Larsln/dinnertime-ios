import DinnertimeKit

/// An offer while it is entered: the shop, empty for a size sold everywhere, and, as typed, the size with its unit and the price of the package.
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

    /// The values of an existing offer of a product bought by `baseUnit`, to correct them.
    ///
    /// A size stored without a unit, or with one that does not measure the product any more, takes the base unit.
    init(_ offer: ProductOffer, baseUnit: BaseUnit, formatter: AmountFormatter = AmountFormatter()) {
        offerID = offer.id
        store = offer.store ?? ""
        amount = formatter.input(offer.amount)
        unit = offer.unit.flatMap { $0.fits(baseUnit) ? $0 : nil } ?? OfferUnit(baseUnit)
        price = formatter.input(offer.price)
    }

    /// The shop as it is stored; `nil` for a size sold everywhere.
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

    /// Whether the draft can be saved: it names a shop or a size, and what was typed as size and price are numbers.
    var isComplete: Bool {
        (storedStore != nil || amountValue != nil)
            && (amount.nilIfBlank == nil || amountValue != nil)
            && (price.nilIfBlank == nil || priceValue != nil)
    }
}
