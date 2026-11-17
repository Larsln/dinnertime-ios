/// The display parts of an ingredient line.
public struct IngredientText: Equatable, Sendable {
    /// Quantity with its unit, if the line states one.
    public let amount: String?
    /// Name of the product or the unparsed text of the line.
    public let name: String
}

extension Ingredient {
    /// Display text with the quantity multiplied by `factor`, the ratio of wanted to stated servings.
    public func text(scaledBy factor: Double = 1, formatter: AmountFormatter = AmountFormatter()) -> IngredientText {
        let scaled = quantity.map { $0 * factor }
        return IngredientText(amount: scaled.map { amountText($0, formatter: formatter) }, name: name(for: scaled))
    }

    private func amountText(_ quantity: Double, formatter: AmountFormatter) -> String {
        let number = formatter.number(quantity)
        guard let unit else {
            return number
        }
        return "\(number) \(unit.code ?? unit.name)"
    }

    private func name(for quantity: Double?) -> String {
        guard let product else {
            return rawText ?? ""
        }
        let countsSeveral = unit == nil && (quantity ?? 1) > 1
        return countsSeveral ? product.pluralName ?? product.name : product.name
    }
}
