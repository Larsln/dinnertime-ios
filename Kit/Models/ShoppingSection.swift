/// The items of a shopping list that are found in the same area of the store.
public struct ShoppingSection: Identifiable, Sendable {
    /// Where the items of a section are found.
    public enum Kind: Hashable, Sendable {
        /// A known area of the store.
        case store(StoreSection)
        /// Products that have no area assigned.
        case unassigned
        /// Manual entries and ingredient lines without a product.
        case freeText
    }

    public let kind: Kind
    public let items: [ShoppingListItem]

    public var id: Kind {
        kind
    }
}

extension ShoppingList {
    /// Items grouped by area, keeping the walking order of the list.
    public var sections: [ShoppingSection] {
        var order: [ShoppingSection.Kind] = []
        var groups: [ShoppingSection.Kind: [ShoppingListItem]] = [:]
        for item in items {
            let kind = item.sectionKind
            if groups[kind] == nil {
                order.append(kind)
            }
            groups[kind, default: []].append(item)
        }
        return order.map { ShoppingSection(kind: $0, items: groups[$0] ?? []) }
    }
}

extension ShoppingListItem {
    fileprivate var sectionKind: ShoppingSection.Kind {
        guard let product else {
            return .freeText
        }
        return product.storeSection.map(ShoppingSection.Kind.store) ?? .unassigned
    }
}
