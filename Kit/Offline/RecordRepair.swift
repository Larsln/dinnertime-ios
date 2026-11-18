import Foundation

/// A part of the local copy that is read from the server again after a change to it was turned away.
///
/// Recipes and products are many, so only the one record is fetched; the other kinds are
/// small and are reloaded as a whole.
public enum RecordRepair: Codable, Hashable, Sendable {
    /// One recipe or product, fetched by its detail endpoint.
    case record(kind: RecordKind, id: Int)
    /// All records of a small kind, fetched with `kinds[]`.
    case kind(RecordKind)

    /// Path of the detail endpoint that answers with the record; `nil` for repairs of a whole kind.
    public var detailPath: String? {
        guard case let .record(kind, id) = self else {
            return nil
        }
        return "\(kind == .recipes ? "recipes" : "products")/\(id)"
    }

    /// The repair with a temporary id replaced by the real one.
    func replacing(_ temporary: Int, with real: Int) -> RecordRepair {
        guard case let .record(kind, id) = self, id == temporary else {
            return self
        }
        return .record(kind: kind, id: real)
    }
}

extension Replica {
    /// What has to be read again if the server turns the write of `request` away, judged before it is applied.
    func repairs(for request: LocalRequest) -> [RecordRepair] {
        switch request.path.first {
        case "recipes":
            let record = request.id(at: 1).map { [RecordRepair.record(kind: .recipes, id: $0)] } ?? []
            return record + (request.method == .delete ? [.kind(.mealPlanEntries)] : [])
        case "products":
            return request.id(at: 1).map { [.record(kind: .products, id: $0)] } ?? []
        case "product-packages":
            let holder = all(.products).first { ($0["packages"] as? [JSONObject] ?? []).contains { $0.recordID == request.id(at: 1) } }
            return holder?.recordID.map { [.record(kind: .products, id: $0)] } ?? []
        case "product-offers":
            return productHolding(offer: request.id(at: 1))?.recordID.map { [.record(kind: .products, id: $0)] } ?? []
        case "meal-plan":
            return [.kind(.mealPlanEntries)]
        case "pantry":
            return [.kind(.pantryItems)]
        case "shopping-lists", "shopping-list-items":
            return [.kind(.shoppingLists)]
        case "tools":
            return [.kind(.tools)]
        case "stores":
            let emptied = request.method == .delete ? productsHolding(offersOf: request.id(at: 1)).compactMap(\.recordID) : []
            return [.kind(.stores)] + emptied.sorted().map { .record(kind: .products, id: $0) }
        default:
            return []
        }
    }

    /// Replaces all records of a kind by the pages of a feed that was asked for this kind only.
    ///
    /// Records created offline that still wait to be sent stay.
    mutating func replaceKind(_ kind: RecordKind, with pages: [SyncChanges]) {
        let answered = pages.flatMap { $0.changed[kind] ?? [] }
        let ids = Set(answered.compactMap(\.recordID))
        for id in (records[kind] ?? [:]).keys where id > 0 && !ids.contains(id) {
            remove(kind, id)
        }
        answered.forEach { put(kind, $0) }
    }
}
