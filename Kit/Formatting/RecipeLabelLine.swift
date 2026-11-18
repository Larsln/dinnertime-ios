extension RecipeSummary {
    /// The course followed by the tag names on one line, each name once.
    ///
    /// A recipe can carry the same name as course and as meal, for example "Dessert".
    public var labelLine: String {
        var seen = Set<String>()
        let names = (courseName.map { [$0] } ?? []) + tags.map(\.name)
        return names.filter { seen.insert($0).inserted }.joined(separator: " · ")
    }
}
