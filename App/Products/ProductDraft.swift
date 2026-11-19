import Foundation
import DinnertimeKit

/// The values of a product while they are edited.
struct ProductDraft {
    /// A package size; `packageID` is `nil` until the server knows it.
    struct Package: Identifiable {
        let id = UUID()
        var packageID: Int?
        var label = ""
        /// Content in the base unit of the product.
        var amount: Double?
    }

    /// How much of the base unit one `unit` of the product is, or that the unit cannot be converted.
    struct Conversion: Identifiable {
        let unit: MeasureUnit
        var amount: Double?
        /// Whether the unit can be converted for the product; without it no amount is saved.
        var isConvertible = true

        /// The amount to save: `nil` for a unit that cannot be converted.
        var savedAmount: Double? {
            isConvertible ? amount : nil
        }

        /// Whether the row states something to save.
        var isComplete: Bool {
            !isConvertible || (amount ?? 0) > 0
        }

        var id: Int {
            unit.id
        }
    }

    var name: String
    /// Key of the icon on the shopping list; `nil` shows the icon of the store section.
    var icon: String?
    var storeSectionID: Int?
    var baseUnit: BaseUnit
    var isPantryStaple: Bool
    /// Days an opened package stays usable; `nil` for products that keep.
    var shelfLife: Int?
    /// What the household noted about the product; empty for none.
    var note: String
    var packages: [Package]
    var conversions: [Conversion]

    init(_ product: Product) {
        name = product.name
        icon = product.icon
        storeSectionID = product.storeSection?.id
        baseUnit = product.baseUnit
        isPantryStaple = product.isPantryStaple ?? false
        shelfLife = product.shelfLifeOpenedDays
        note = product.note ?? ""
        packages = (product.packages ?? []).map { Package(packageID: $0.id, label: $0.label, amount: $0.amountInBase) }
        conversions = (product.conversions ?? []).map { Conversion(unit: $0.unit, amount: $0.amountInBase, isConvertible: $0.amountInBase != nil) }
    }

    /// Whether the draft can be saved.
    var isComplete: Bool {
        name.nilIfBlank != nil
    }

    /// The values of the product itself as the API accepts them.
    var input: ProductInput {
        ProductInput(
            name: name.nilIfBlank ?? "",
            icon: icon,
            storeSectionID: storeSectionID,
            baseUnit: baseUnit,
            isPantryStaple: isPantryStaple,
            shelfLifeOpenedDays: shelfLife,
            note: Product.storedNote(note)
        )
    }
}
