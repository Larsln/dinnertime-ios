extension ShoppingAmounts {
    /// What to buy: the packages such as "1 × Lidl 200 g", or "2 × 200 g" for a size sold everywhere, or the plain
    /// amount without packages, followed by the needs that cannot be converted, such as "1 × 1 kg + 3 Stück".
    ///
    /// The size is left out for single pieces of a shop, where it adds nothing to the name. Grams and milliliters
    /// are whole numbers, and "≈" stands in front of an amount that rests on an unconfirmed conversion.
    public func purchaseText(unit: BaseUnit, isApproximate: Bool, formatter: AmountFormatter = AmountFormatter()) -> String? {
        let extras = extraAmounts.map { "\(formatter.number($0.quantity)) \($0.unitCode)" }
        let parts = purchaseParts(unit: unit, isAlone: extras.isEmpty, formatter: formatter) + extras
        return parts.isEmpty ? nil : (isApproximate ? "≈ " : "") + parts.joined(separator: " + ")
    }

    /// The amount in as few characters as possible, for a tile: "2 × 200 g" for several equal packages,
    /// otherwise the plain amount, followed by the needs that cannot be converted. An approximate amount starts with "≈".
    public func shortPurchaseText(unit: BaseUnit, isApproximate: Bool, formatter: AmountFormatter = AmountFormatter()) -> String? {
        let extras = extraAmounts.map { "\(formatter.number($0.quantity)) \($0.unitCode)" }
        let parts = shortParts(unit: unit, isAlone: extras.isEmpty, formatter: formatter) + extras
        return parts.isEmpty ? nil : (isApproximate ? "≈ " : "") + parts.joined(separator: " + ")
    }

    private func shortParts(unit: BaseUnit, isAlone: Bool, formatter: AmountFormatter) -> [String] {
        if packages.count == 1, let package = packages.first, package.count > 1 {
            return ["\(package.count) × \(formatter.wholeString(package.amount, unit: unit))"]
        }
        let amount = purchaseAmount.flatMap { $0 > 0 || isAlone ? $0 : nil }
        return amount.map { [formatter.wholeString($0, unit: unit)] } ?? []
    }

    /// The packages, or the purchase amount without packages; an amount of zero only shows when nothing else is bought.
    private func purchaseParts(unit: BaseUnit, isAlone: Bool, formatter: AmountFormatter) -> [String] {
        if packages.isEmpty {
            let amount = purchaseAmount.flatMap { $0 > 0 || isAlone ? $0 : nil }
            return amount.map { [formatter.wholeString($0, unit: unit)] } ?? []
        }
        return packages.map { package in
            let label = package.label.trimmingCharacters(in: .whitespaces)
            let isSinglePiece = unit == .piece && package.amount == 1
            let size = !label.isEmpty && isSinglePiece ? "" : formatter.wholeString(package.amount, unit: unit)
            return ["\(package.count) ×", label, size].filter { !$0.isEmpty }.joined(separator: " ")
        }
    }
}

extension ShoppingListItem {
    /// What to buy of the item's own product; `nil` for items without a product or without an amount of their own.
    public func purchaseText(formatter: AmountFormatter = AmountFormatter()) -> String? {
        guard let product, hasOwnAmounts || variants.isEmpty else {
            return nil
        }
        return purchaseText(unit: product.baseUnit, isApproximate: isApproximate, formatter: formatter)
    }

    /// The short amount for a tile. An item needed only for its variants shows theirs instead.
    public func shortPurchaseText(formatter: AmountFormatter = AmountFormatter()) -> String? {
        guard let product else {
            return nil
        }
        guard !hasOwnAmounts, !variants.isEmpty else {
            return shortPurchaseText(unit: product.baseUnit, isApproximate: isApproximate, formatter: formatter)
        }
        let parts = variants.compactMap { $0.shortPurchaseText(unit: $0.baseUnit, isApproximate: isApproximate, formatter: formatter) }
        return parts.isEmpty ? nil : parts.joined(separator: " + ")
    }

    /// The names of the variants, for a tile that also shows an amount of its own: "+ Rote Zwiebel".
    public var variantNamesText: String? {
        hasOwnAmounts && !variants.isEmpty ? "+ " + variants.map(\.name).joined(separator: ", ") : nil
    }
}
