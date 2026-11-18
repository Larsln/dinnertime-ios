import SwiftUI

extension View {
    /// Runs `search` when the view appears and, after a short pause, whenever `text` changes.
    func debouncedSearch(_ text: String, isFirst: Bool, search: @escaping () async -> Void) -> some View {
        task(id: text) {
            if !isFirst {
                try? await Task.sleep(for: .milliseconds(300))
            }
            if !Task.isCancelled {
                await search()
            }
        }
    }
}
