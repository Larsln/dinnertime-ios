extension ShoppingListItem {
    /// What to buy: the packages such as "2 × Becher 200 g", or the plain amount without packages.
    ///
    /// The size is left out for single pieces, where it only repeats the label.
    public func purchaseText(formatter: AmountFormatter = AmountFormatter()) -> String? {
        guard let product else {
            return nil
        }
        if packages.isEmpty {
            return purchaseAmount.map { formatter.string($0, unit: product.baseUnit) }
        }
        return packages.map { package in
            let isSinglePiece = product.baseUnit == .piece && package.amount == 1
            let size = isSinglePiece ? "" : " \(formatter.string(package.amount, unit: product.baseUnit))"
            return "\(package.count) × \(package.label)\(size)"
        }.joined(separator: " + ")
    }
}
