import Foundation

/// A planned meal a shopping list was made for, with what the list holds for it.
public struct ShoppingDish: Hashable, Identifiable, Sendable {
    /// One product the meal uses and where it comes from.
    public struct Ingredient: Hashable, Identifiable, Sendable {
        /// Where the product for the meal comes from.
        public enum Source: Hashable, Sendable {
            /// Still to be bought.
            case open
            /// Checked off or replaced.
            case settled
            /// Struck off the list without buying it.
            case skipped
            /// At home already.
            case stock
        }

        public let productID: Int
        public let name: String
        /// Amount the meal consumes; `nil` when it is not tracked.
        public let amount: Double?
        public let unit: BaseUnit
        public let source: Source

        public var id: Int {
            productID
        }

        /// The name with the amount the meal consumes, or the name alone.
        public func text(formatter: AmountFormatter = AmountFormatter()) -> String {
            amount.map { "\(name) \(formatter.string($0, unit: unit))" } ?? name
        }
    }

    public let entry: MealPlanEntry
    /// What the meal uses, each product once: to be bought first, then settled, skipped and from the stock, each by name.
    public let ingredients: [Ingredient]

    public var id: Int {
        entry.id
    }
}

extension ShoppingList {
    /// Whether `day` lies in the period of the list.
    public func covers(_ day: DayDate) -> Bool {
        !(day < startsOn) && !(endsOn < day)
    }

    /// The meals among `entries` that fall into the period of the list, by day and meal, each with the products the
    /// list names for it: those of its items and their variants, and those the stock covers.
    ///
    /// A product with several positions, such as a bought one and an open one for what is still missing,
    /// shows once: as open before settled, skipped and in stock, with the amount of that position.
    public func dishes(from entries: [MealPlanEntry]) -> [ShoppingDish] {
        entries
            .filter { covers($0.date) }
            .sorted { ($0.date, Self.rank(of: $0.meal), $0.id) < ($1.date, Self.rank(of: $1.meal), $1.id) }
            .map { ShoppingDish(entry: $0, ingredients: ingredients(for: $0)) }
    }

    private func ingredients(for entry: MealPlanEntry) -> [ShoppingDish.Ingredient] {
        var found: [ShoppingDish.Ingredient] = []
        for item in items {
            let source: ShoppingDish.Ingredient.Source = item.isSkipped ? .skipped : item.isChecked ? .settled : .open
            if let product = item.product, let amount = Self.amount(of: item.uses, for: entry) {
                found.append(.init(productID: product.id, name: product.name, amount: amount, unit: product.baseUnit, source: source))
            }
            for variant in item.variants {
                if let amount = Self.amount(of: variant.uses, for: entry) {
                    found.append(.init(productID: variant.productID, name: variant.name, amount: amount, unit: variant.baseUnit, source: source))
                }
            }
        }
        for need in inStock {
            let uses = need.uses.filter { $0.recipeID == entry.recipe.id && $0.date == entry.date }
            if !uses.isEmpty {
                let amounts = uses.compactMap(\.amount)
                let amount = amounts.isEmpty ? nil : amounts.reduce(0, +)
                found.append(.init(productID: need.productID, name: need.name, amount: amount, unit: need.baseUnit, source: .stock))
            }
        }
        var names: Set<String> = []
        return found
            .sorted { ($0.source.rank, $0.name.lowercased()) < ($1.source.rank, $1.name.lowercased()) }
            .filter { names.insert($0.name.lowercased()).inserted }
    }

    /// Position of a meal within its day.
    private static func rank(of meal: MealType) -> Int {
        MealType.allCases.firstIndex(of: meal) ?? 0
    }

    /// What `entry` consumes according to `uses`; `nil` when none of them is for it.
    private static func amount(of uses: [ShoppingListItem.Use], for entry: MealPlanEntry) -> Double? {
        let own = uses.filter { $0.recipeID == entry.recipe.id && $0.date == entry.date }
        return own.isEmpty ? nil : own.map(\.amount).reduce(0, +)
    }
}

extension ShoppingDish.Ingredient.Source {
    fileprivate var rank: Int {
        switch self {
        case .open: 0
        case .settled: 1
        case .skipped: 2
        case .stock: 3
        }
    }
}
