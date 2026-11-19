extension ShoppingListItem {
    /// What to buy: the packages such as "1 × Lidl 200 g", or "2 × 200 g" for a size sold everywhere, or the plain
    /// amount without packages, followed by the needs that cannot be converted, such as "1 × 1 kg + 3 Stück".
    ///
    /// The size is left out for single pieces of a shop, where it adds nothing to the name.
    public func purchaseText(formatter: AmountFormatter = AmountFormatter()) -> String? {
        guard let product else {
            return nil
        }
        let extras = extraAmounts.map { "\(formatter.number($0.quantity)) \($0.unitCode)" }
        let parts = purchaseParts(of: product, isAlone: extras.isEmpty, formatter: formatter) + extras
        return parts.isEmpty ? nil : parts.joined(separator: " + ")
    }

    /// The amount in as few characters as possible, for a tile: "2 × 200 g" for several equal packages,
    /// otherwise the plain amount, followed by the needs that cannot be converted.
    public func shortPurchaseText(formatter: AmountFormatter = AmountFormatter()) -> String? {
        guard let product else {
            return nil
        }
        let extras = extraAmounts.map { "\(formatter.number($0.quantity)) \($0.unitCode)" }
        let parts = shortParts(of: product, isAlone: extras.isEmpty, formatter: formatter) + extras
        return parts.isEmpty ? nil : parts.joined(separator: " + ")
    }

    private func shortParts(of product: Product, isAlone: Bool, formatter: AmountFormatter) -> [String] {
        if packages.count == 1, let package = packages.first, package.count > 1 {
            return ["\(package.count) × \(formatter.string(package.amount, unit: product.baseUnit))"]
        }
        let amount = purchaseAmount.flatMap { $0 > 0 || isAlone ? $0 : nil }
        return amount.map { [formatter.string($0, unit: product.baseUnit)] } ?? []
    }

    /// The packages, or the purchase amount without packages; an amount of zero only shows when nothing else is bought.
    private func purchaseParts(of product: Product, isAlone: Bool, formatter: AmountFormatter) -> [String] {
        if packages.isEmpty {
            let amount = purchaseAmount.flatMap { $0 > 0 || isAlone ? $0 : nil }
            return amount.map { [formatter.string($0, unit: product.baseUnit)] } ?? []
        }
        return packages.map { package in
            let label = package.label.trimmingCharacters(in: .whitespaces)
            let isSinglePiece = product.baseUnit == .piece && package.amount == 1
            let size = !label.isEmpty && isSinglePiece ? "" : formatter.string(package.amount, unit: product.baseUnit)
            return ["\(package.count) ×", label, size].filter { !$0.isEmpty }.joined(separator: " ")
        }
    }
}
