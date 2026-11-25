import DinnertimeKit

/// What was bought in place of a shopping item: a product of the household, or something only named.
enum SubstituteChoice {
    case product(Product)
    case text(String)
}

/// What can be done about a shopping item from its details.
struct ShoppingItemActions {
    /// Deletes the item; `nil` for items that come from the plan.
    var delete: (() -> Void)?
    /// Stores the note of the item's product; `nil` clears it.
    var saveNote: (String?) -> Void
    /// Strikes the item off the list without buying it, or opens it again.
    var setSkipped: (Bool) -> Void
    /// Checks the item off with what was bought in its place.
    var substitute: (SubstituteChoice) -> Void

    /// The same actions, each followed by `finish` when it settles or removes the item.
    func finishing(with finish: @escaping () -> Void) -> ShoppingItemActions {
        ShoppingItemActions(
            delete: delete.map { delete in { delete(); finish() } },
            saveNote: saveNote,
            setSkipped: { setSkipped($0); finish() },
            substitute: { substitute($0); finish() }
        )
    }
}
