import Foundation

/// Keeps the local copy on disk: one file per record and one for everything else.
///
/// Every file is written atomically, so a kill of the app leaves either the old or the new state.
struct ReplicaFiles {
    /// What is stored besides the records.
    private struct Meta: Codable {
        var version = 0
        var needsFullSync = false
        var nextTemporaryID = -1
        var itemIDsByCreationKey: [String: Int] = [:]
        var itemActionTimes: [Int: Date] = [:]
        var knownShoppingKeys: [String]?
    }

    /// Directory of the copy.
    let directory: URL

    private var recordsDirectory: URL {
        directory.appending(path: "records")
    }

    private var metaFile: URL {
        directory.appending(path: "meta.json")
    }

    private var householdFile: URL {
        directory.appending(path: "household.json")
    }

    private var answersFile: URL {
        directory.appending(path: "answers.json")
    }

    /// Reads the copy; what is missing or unreadable starts empty.
    func load() -> Replica {
        var replica = Replica()
        for kind in RecordKind.allCases {
            let files = (try? FileManager.default.contentsOfDirectory(at: directory(of: kind), includingPropertiesForKeys: nil)) ?? []
            for file in files {
                if let data = try? Data(contentsOf: file), let record = try? JSONValue.object(from: data) {
                    replica.put(kind, record)
                }
            }
        }
        _ = replica.takeChanges()
        if let data = try? Data(contentsOf: metaFile), let meta = try? JSONDecoder().decode(Meta.self, from: data) {
            replica.version = meta.version
            replica.needsFullSync = meta.needsFullSync
            replica.nextTemporaryID = meta.nextTemporaryID
            replica.itemIDsByCreationKey = meta.itemIDsByCreationKey
            replica.itemActionTimes = meta.itemActionTimes
            replica.knownShoppingKeys = meta.knownShoppingKeys ?? []
        }
        replica.household = (try? Data(contentsOf: householdFile)).flatMap { try? JSONValue.object(from: $0) } ?? [:]
        replica.cachedAnswers = (try? Data(contentsOf: answersFile)).flatMap { try? JSONValue.object(from: $0) } ?? [:]
        return replica
    }

    /// Writes what changed in `replica` since it was saved last.
    func save(_ replica: inout Replica) throws {
        let changes = replica.takeChanges()
        for reference in changes.removed {
            try? FileManager.default.removeItem(at: file(of: reference))
        }
        for reference in changes.written {
            guard let record = replica.record(reference.kind, reference.id) else {
                continue
            }
            try FileManager.default.createDirectory(at: directory(of: reference.kind), withIntermediateDirectories: true)
            try JSONValue.data(record).write(to: file(of: reference), options: .atomic)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let meta = Meta(
            version: replica.version,
            needsFullSync: replica.needsFullSync,
            nextTemporaryID: replica.nextTemporaryID,
            itemIDsByCreationKey: replica.itemIDsByCreationKey,
            itemActionTimes: replica.itemActionTimes,
            knownShoppingKeys: replica.knownShoppingKeys
        )
        try JSONEncoder().encode(meta).write(to: metaFile, options: .atomic)
        try JSONValue.data(replica.household).write(to: householdFile, options: .atomic)
        try JSONValue.data(replica.cachedAnswers).write(to: answersFile, options: .atomic)
    }

    /// Deletes the copy.
    func wipe() {
        try? FileManager.default.removeItem(at: directory)
    }

    private func directory(of kind: RecordKind) -> URL {
        recordsDirectory.appending(path: kind.rawValue)
    }

    private func file(of reference: RecordReference) -> URL {
        directory(of: reference.kind).appending(path: "\(reference.id).json")
    }
}
