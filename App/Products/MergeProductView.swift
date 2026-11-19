import DinnertimeKit
import SwiftUI

/// Asks for the product that a duplicate is merged into and warns about the consequences.
struct MergeProductView: View {
    let session: AppSession
    let product: Product
    let onMerge: (Product) async -> Bool

    @State private var target: Product?
    @State private var isMerging = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PaperForm {
                Section {
                    Label {
                        Text("“\(product.name)” will be deleted. Its recipe lines move to the chosen product and its name is kept as an alias.")
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.accentDeep)
                    }
                }
                Section {
                    NavigationLink {
                        ProductPickerView(session: session, allowsCreation: false) { chosen in
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
        target.map { $0.id != product.id } == true && !isMerging
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
