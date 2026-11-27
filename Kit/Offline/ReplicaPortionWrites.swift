import Foundation

/// Who eats a planned meal and what they said about their portion, applied to the local copy.
extension Replica {
    /// Sets who eats an entry the way the server does, as far as the copy can tell.
    ///
    /// Members and guests set the servings. A member keeps the share of a standard portion the entry held for
    /// them and starts with a whole one otherwise; the server corrects that with the next sync. Servings alone
    /// name nobody, so every serving is a standard portion.
    func seat(_ entry: inout JSONObject, as body: JSONObject) {
        if let ids = body["eater_ids"] as? [Int] {
            let guests = (body["guests"] as? NSNumber)?.intValue ?? 0
            let known = entry["eaters"] as? [JSONObject] ?? []
            let names = Dictionary((household["members"] as? [JSONObject] ?? []).compactMap { member in member.recordID.map { ($0, member["name"] ?? NSNull()) } }) { first, _ in first }
            let eaters: [JSONObject] = ids.map { id in
                let factor = (known.first { $0["user_id"] as? Int == id }?["factor"] as? NSNumber)?.doubleValue ?? 1
                return ["user_id": id, "name": names[id] ?? NSNull(), "factor": factor]
            }
            entry["eaters"] = eaters
            entry["guests"] = guests
            entry["servings"] = ids.count + guests
            entry["portions"] = eaters.reduce(Double(guests)) { $0 + ($1["factor"] as? Double ?? 1) }
        } else if let servings = (body["servings"] as? NSNumber)?.intValue, servings != (entry["servings"] as? NSNumber)?.intValue || entry["portions"] == nil {
            entry["servings"] = servings
            entry["eaters"] = NSNull()
            entry["guests"] = 0
            entry["portions"] = servings
        }
    }

    /// Notes or withdraws the verdict of the user the body names on the portion of an entry.
    func notePortionVerdict(in entry: inout JSONObject, from body: JSONObject) {
        guard let userID = (body["user_id"] as? NSNumber)?.intValue else {
            return
        }
        var feedback = (entry["portion_feedback"] as? [JSONObject] ?? []).filter { ($0["user_id"] as? NSNumber)?.intValue != userID }
        if let verdict = body["verdict"] as? String {
            feedback.append(["user_id": userID, "verdict": verdict])
        }
        entry["portion_feedback"] = feedback
    }
}
