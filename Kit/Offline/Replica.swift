import Foundation

/// A reference to one stored record.
struct RecordReference: Hashable {
    let kind: RecordKind
    let id: Int
}

/// The local copy of the data of the household, kept as the JSON the server sent.
///
/// All reads of the app are answered from it and all writes are applied to it at once.
/// Changes are tracked so that only what changed is written to disk.
struct Replica {
    /// Records by kind and id.
    private(set) var records: [RecordKind: [Int: JSONObject]] = [:]
    /// The settings of the household.
    var household: JSONObject = [:]
    /// Version of the feed up to which the copy is complete; zero before the first sync.
    var version = 0
    /// Parts of the copy that have to be read from the server again, after a change to them was turned away.
    var pendingRepairs: [RecordRepair] = []
    /// The id the next record created offline gets; temporary ids are negative and count down.
    var nextTemporaryID = -1
    /// Answers of read-only endpoints that are not part of the feed, by path.
    var cachedAnswers: [String: Any] = [:]
    /// Ids of shopping items created offline by the key of the request that created them, for devices that only know the key.
    var itemIDsByCreationKey: [String: Int] = [:]
    /// Keys of the changes to the shopping list this device made or received from devices nearby, oldest first.
    var knownShoppingKeys: [String] = []
    /// When the latest known action on a shopping item happened, by item id.
    var itemActionTimes: [Int: Date] = [:]

    /// The real ids of records created offline by the temporary ids they had, for screens that still hold the old ones.
    private(set) var realIDs: [Int: Int] = [:]

    /// Records written since the last call of ``takeChanges()``.
    private var written: Set<RecordReference> = []
    /// Records removed since the last call of ``takeChanges()``.
    private var removed: Set<RecordReference> = []

    /// All records of a kind.
    func all(_ kind: RecordKind) -> [JSONObject] {
        records[kind].map { Array($0.values) } ?? []
    }

    /// One record, if the copy holds it.
    func record(_ kind: RecordKind, _ id: Int) -> JSONObject? {
        records[kind]?[id]
    }

    /// Stores a record under its id.
    mutating func put(_ kind: RecordKind, _ record: JSONObject) {
        guard let id = record.recordID else {
            return
        }
        records[kind, default: [:]][id] = record
        written.insert(RecordReference(kind: kind, id: id))
        removed.remove(RecordReference(kind: kind, id: id))
    }

    /// Removes a record.
    mutating func remove(_ kind: RecordKind, _ id: Int) {
        guard records[kind]?.removeValue(forKey: id) != nil else {
            return
        }
        removed.insert(RecordReference(kind: kind, id: id))
        written.remove(RecordReference(kind: kind, id: id))
    }

    /// Remembers the key of a change to the shopping list; only the most recent keys are kept.
    mutating func rememberShoppingKey(_ key: String) {
        knownShoppingKeys = Array((knownShoppingKeys + [key]).suffix(500))
    }

    /// Hands out a temporary id for a record created offline.
    mutating func makeTemporaryID() -> Int {
        defer { nextTemporaryID -= 1 }
        return nextTemporaryID
    }

    /// Applies one page of the feed and answers with the areas it touched.
    ///
    /// Shops also touch the shopping list, whose tiles mark the products that have one, and a deleted shop takes its offers along.
    /// The version is only taken over with the last page, so that an interrupted sync starts over.
    mutating func apply(_ changes: SyncChanges) -> Set<RealtimeArea> {
        var areas: Set<RealtimeArea> = []
        for kind in RecordKind.allCases {
            let touched: Set<RealtimeArea> = kind == .stores ? [kind.area, .shopping] : [kind.area]
            for record in changes.changed[kind] ?? [] {
                put(kind, record)
                areas.formUnion(touched)
            }
            for id in changes.deleted[kind] ?? [] where record(kind, id) != nil {
                if kind == .stores {
                    removeOffers(ofStore: id)
                }
                remove(kind, id)
                areas.formUnion(touched)
            }
        }
        if let household = changes.household {
            self.household = household
        }
        version = changes.version
        return areas
    }

    /// Replaces a temporary id by the real one everywhere in the copy.
    mutating func replaceID(_ temporary: Int, with real: Int) {
        for (kind, byID) in records {
            for (id, record) in byID {
                guard let replaced = JSONValue.replacing(temporary, with: real, in: record) as? JSONObject else {
                    continue
                }
                if id == temporary {
                    remove(kind, id)
                    put(kind, replaced)
                } else if !NSDictionary(dictionary: replaced).isEqual(to: record) {
                    put(kind, replaced)
                }
            }
        }
        realIDs[temporary] = real
        pendingRepairs = pendingRepairs.map { $0.replacing(temporary, with: real) }
        itemIDsByCreationKey = itemIDsByCreationKey.mapValues { $0 == temporary ? real : $0 }
        if let time = itemActionTimes.removeValue(forKey: temporary) {
            itemActionTimes[real] = time
        }
    }

    /// The records written and removed since the last call, for the storage on disk.
    mutating func takeChanges() -> (written: [RecordReference], removed: [RecordReference]) {
        defer {
            written = []
            removed = []
        }
        return (Array(written), Array(removed))
    }
}
