import Foundation

/// Builds the `Accept-Language` header from the languages preferred on the device.
enum AcceptLanguage {
    private static let maximumCount = 5

    /// Lists the languages in order of preference with descending quality values.
    static func header(for languages: [String]) -> String {
        languages.prefix(maximumCount).enumerated().map { index, language in
            index == 0 ? language : "\(language);q=\(quality(at: index))"
        }.joined(separator: ", ")
    }

    private static func quality(at index: Int) -> String {
        String(format: "%.1f", 1 - Double(index) / 10)
    }
}
