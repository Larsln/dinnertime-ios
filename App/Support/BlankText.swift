extension String {
    /// The text without surrounding whitespace, or `nil` if nothing else is left.
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
