extension ShoppingListItem {
    /// What to buy: the packages such as "2 × Becher 200 g", or the plain amount without packages.
    public func purchaseText(formatter: AmountFormatter = AmountFormatter()) -> String? {
        guard let product else {
            return nil
        }
        if packages.isEmpty {
            return purchaseAmount.map { formatter.string($0, unit: product.baseUnit) }
        }
        return packages.map { package in
            "\(package.count) × \(package.label) \(formatter.string(package.amount, unit: product.baseUnit))"
        }.joined(separator: " + ")
    }
}
