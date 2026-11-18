import Foundation

/// What a run through the queue of changes did.
public struct DrainReport: Equatable, Sendable {
    /// Number of changes the server took over.
    public var delivered = 0
    /// Reasons the server gave for refusing changes.
    public var rejections: [String] = []
    /// Whether changes are left that have to be sent again later.
    public var needsRetry = false
    /// The parts of the app whose data changed while draining.
    public var areas: Set<RealtimeArea> = []
}

/// Sending the queued changes and taking over what the server answered.
extension OfflineStore {
    /// Sends the queued changes in order until the queue is empty or one has to wait.
    ///
    /// `deliver` sends one change, with the content of its upload, and reports what came back.
    public func drain(using deliver: @Sendable (OutboxEntry, Data?) async -> DeliveryResult) async -> DrainReport {
        var report = DrainReport()
        while let entry = outbox.first {
            let outcome = OutboxOutcome(await deliver(entry, upload(forKey: entry.key)))
            guard outbox.first?.key == entry.key else {
                continue
            }
            switch outcome {
            case .retry:
                report.needsRetry = true
                return report
            case let .delivered(body):
                report.delivered += 1
                report.areas.formUnion(settle(entry, answer: body))
            case .dropped:
                report.areas.formUnion(giveUp(entry))
            case let .rejected(message):
                report.rejections.append(message)
                report.areas.formUnion(giveUp(entry))
            }
            outbox.removeFirst()
            try? FileManager.default.removeItem(at: outboxFiles.uploadFile(forKey: entry.key))
            try? save()
        }
        return report
    }

    /// Takes over the real ids of created records and, where nothing else waits for them, the records themselves.
    func settle(_ entry: OutboxEntry, answer: Data) -> Set<RealtimeArea> {
        guard !entry.created.isEmpty, let root = try? JSONValue.object(from: answer) else {
            return []
        }
        let answered = (root["data"] as? [JSONObject]) ?? (root["data"] as? JSONObject).map { [$0] } ?? []
        for (temporary, record) in zip(entry.created, answered) {
            guard let real = record.recordID else {
                continue
            }
            replica.replaceID(temporary, with: real)
            let isAwaited = outbox.dropFirst().contains { $0.refers(to: temporary) }
            for index in outbox.indices.dropFirst() {
                outbox[index].replaceID(temporary, with: real)
            }
            if let kind = entry.createdKind, !isAwaited {
                replica.put(kind, (replica.record(kind, real) ?? [:]).merging(record) { _, answered in answered })
            }
            if entry.isShoppingChange {
                replica.itemIDsByCreationKey[entry.key] = real
            }
        }
        return Set(RealtimeArea.allCases)
    }

    /// Removes what a turned-away change created and notes what has to be read from the server again.
    func giveUp(_ entry: OutboxEntry) -> Set<RealtimeArea> {
        for temporary in entry.created {
            if let kind = entry.createdKind {
                replica.remove(kind, temporary)
            }
        }
        for repair in entry.repairs ?? [] where !replica.pendingRepairs.contains(repair) {
            replica.pendingRepairs.append(repair)
        }
        return Set(RealtimeArea.allCases)
    }
}
