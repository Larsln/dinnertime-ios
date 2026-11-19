import DinnertimeKit
import SwiftUI

/// Asks for the tool that a duplicate is merged into and warns about the consequences.
struct MergeToolView: View {
    let session: AppSession
    let tool: Tool
    let onMerge: (Tool) async -> Bool

    @State private var target: Tool?
    @State private var isMerging = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PaperForm {
                Section {
                    Label {
                        Text("“\(tool.name)” will be deleted. Its recipes use the chosen tool instead.")
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.accentDeep)
                    }
                }
                Section {
                    NavigationLink {
                        ToolPickerView(session: session, allowsCreation: false) { chosen in
                            target = chosen
                        }
                    } label: {
                        LabeledContent("Merge into", value: target?.name ?? String(localized: "Choose"))
                    }
                }
            }
            .navigationTitle("Merge")
            .navigationBarTitleDisplayMode(.inline)
            .sheetToolbar(confirm: "Merge", isEnabled: canMerge, onCancel: { dismiss() }, onConfirm: merge)
        }
    }

    private var canMerge: Bool {
        target.map { $0.id != tool.id } == true && !isMerging
    }

    private func merge() {
        guard let target else {
            return
        }
        isMerging = true
        Task {
            if await onMerge(target) {
                dismiss()
            }
            isMerging = false
        }
    }
}
