import DinnertimeKit
import SwiftUI

/// The failures the app noted, newest first, to share as a text file when something goes wrong, or to clear.
///
/// The entries name calls and answers, never the server, the account or what was sent.
struct ErrorLogView: View {
    @State private var entries: [ErrorLogEntry] = []

    var body: some View {
        PaperList {
            ForEach(entries) { entry in
                VStack(alignment: .leading, spacing: 3) {
                    Text(verbatim: entry.message)
                        .font(.subheadline)
                    Text(verbatim: "\(entry.date.formatted(date: .abbreviated, time: .standard)) · \(entry.context)")
                        .font(.caption)
                        .foregroundStyle(.inkMuted)
                }
                .textSelection(.enabled)
            }
        }
        .overlay {
            if entries.isEmpty {
                ContentUnavailableView("No errors noted", systemImage: "checkmark.seal")
            }
        }
        .navigationTitle("Error log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ShareLink(item: ErrorLogFile(text: ErrorLog.shared.exportText(header: DeviceFacts.lines)), preview: SharePreview("Error log"))
                    .disabled(entries.isEmpty)
                Button("Clear log", systemImage: "trash", role: .destructive) {
                    ErrorLog.shared.clear()
                    entries = []
                }
                .disabled(entries.isEmpty)
            }
        }
        .onAppear {
            entries = ErrorLog.shared.entries
        }
    }
}
