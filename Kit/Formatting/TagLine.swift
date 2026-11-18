extension Sequence where Element == Tag {
    /// The tag names on one line, each name once.
    ///
    /// A recipe can carry the same name as meal and as category, for example "Dinner".
    public var displayLine: String {
        var seen = Set<String>()
        return map(\.name).filter { seen.insert($0).inserted }.joined(separator: " · ")
    }
}
