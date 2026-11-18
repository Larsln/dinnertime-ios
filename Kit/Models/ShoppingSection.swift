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

        /// Place in the walking order: the areas of the store by position, then products without area, then free text.
        fileprivate var rank: Int {
            switch self {
            case let .store(section):
                section.position
            case .unassigned:
                Int.max - 1
            case .freeText:
                Int.max
            }
        }
    }

    public let kind: Kind
    public let items: [ShoppingListItem]

    public var id: Kind {
        kind
    }
}

extension ShoppingList {
    /// The items that are still to buy, grouped by area in walking order.
    ///
    /// Items added on this device stand at the end of the list, so the areas are put in order here.
    public var openSections: [ShoppingSection] {
        Self.sections(of: items.filter { !$0.isChecked })
    }

    /// The items that were checked off, in the order of the list.
    public var checkedItems: [ShoppingListItem] {
        items.filter(\.isChecked)
    }

    private static func sections(of items: [ShoppingListItem]) -> [ShoppingSection] {
        var order: [ShoppingSection.Kind] = []
        var groups: [ShoppingSection.Kind: [ShoppingListItem]] = [:]
        for item in items {
            let kind = item.sectionKind
            if groups[kind] == nil {
                order.append(kind)
            }
            groups[kind, default: []].append(item)
        }
        let ranked = order.enumerated().sorted { ($0.element.rank, $0.offset) < ($1.element.rank, $1.offset) }.map(\.element)
        return ranked.map { ShoppingSection(kind: $0, items: groups[$0] ?? []) }
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
