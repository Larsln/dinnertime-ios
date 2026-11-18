extension ShoppingListItem {
    /// What to buy: the packages such as "2 × Becher 200 g", or the plain amount without packages,
    /// followed by the needs that cannot be converted, such as "1 × Packung 1 kg + 3 Stück".
    ///
    /// The size is left out for single pieces, where it only repeats the label.
    public func purchaseText(formatter: AmountFormatter = AmountFormatter()) -> String? {
        guard let product else {
            return nil
        }
        let extras = extraAmounts.map { "\(formatter.number($0.quantity)) \($0.unitCode)" }
        let parts = purchaseParts(of: product, isAlone: extras.isEmpty, formatter: formatter) + extras
        return parts.isEmpty ? nil : parts.joined(separator: " + ")
    }

    /// The packages, or the purchase amount without packages; an amount of zero only shows when nothing else is bought.
    private func purchaseParts(of product: Product, isAlone: Bool, formatter: AmountFormatter) -> [String] {
        if packages.isEmpty {
            let amount = purchaseAmount.flatMap { $0 > 0 || isAlone ? $0 : nil }
            return amount.map { [formatter.string($0, unit: product.baseUnit)] } ?? []
        }
        return packages.map { package in
            let isSinglePiece = product.baseUnit == .piece && package.amount == 1
            let size = isSinglePiece ? "" : " \(formatter.string(package.amount, unit: product.baseUnit))"
            return "\(package.count) × \(package.label)\(size)"
        }
    }
}
