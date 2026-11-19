import DinnertimeKit
import SwiftUI

/// Edits a product with its offers, packages and conversions, confirms, merges or deletes it.
///
/// Offers are stored as they are entered; everything else is stored with the save button.
struct ProductEditorView: View {
    /// Called after the product changed on the server.
    let onChange: () async -> Void

    @State private var model: ProductEditorModel
    @State private var offers: ProductOffersModel
    @State private var showsMerge = false
    @State private var confirmsDeletion = false
    @State private var didMerge = false
    @Environment(\.dismiss) private var dismiss
    @Environment(OfflineCoordinator.self) private var offline

    init(session: AppSession, product: Product, onChange: @escaping () async -> Void) {
        self.onChange = onChange
        _model = State(initialValue: ProductEditorModel(session: session, product: product))
        _offers = State(initialValue: ProductOffersModel(session: session, product: product))
    }

    var body: some View {
        Form {
            ProductFactsSection(product: model.product)
            ProductDetailsSection(draft: $model.draft, storeSections: model.storeSections)
            ProductOffersSection(model: offers, unit: model.draft.baseUnit)
            Section("Note") {
                ProductNoteField(text: $model.draft.note)
            }
            ProductPackagesSection(draft: $model.draft)
            ProductConversionsSection(draft: $model.draft, addableUnits: model.addableUnits)
            actions
        }
        .disabled(model.isWorking)
        .navigationTitle(Text(verbatim: model.product.name))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    finish { await model.save(confirming: false) }
                }
                .disabled(!model.draft.isComplete || model.isWorking)
            }
        }
        .sheet(isPresented: $showsMerge, onDismiss: leaveAfterMerge) {
            MergeProductView(session: model.session, product: model.product) { target in
                didMerge = await model.merge(into: target)
                return didMerge
            }
        }
        .confirmationDialog("Delete product", isPresented: $confirmsDeletion, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                finish { await model.delete() }
            }
        } message: {
            Text("“\(model.product.name)” will be deleted unless a recipe uses it.")
        }
        .task {
            await model.load()
        }
        .errorAlert($model.errorMessage)
    }

    private var actions: some View {
        Section {
            if model.hasSuggestions {
                Button("Confirm", systemImage: "checkmark") {
                    finish { await model.save(confirming: true) }
                }
                .disabled(!model.draft.isComplete)
            }
            Button("Merge", systemImage: "arrow.triangle.merge") {
                showsMerge = true
            }
            .disabled(!offline.isOnline)
            if !offline.isOnline {
                ConnectionHint()
            }
            Button("Delete", systemImage: "trash", role: .destructive) {
                confirmsDeletion = true
            }
        }
    }

    private func leaveAfterMerge() {
        if didMerge {
            finish { true }
        }
    }

    /// Runs a change and leaves the editor once the server accepted it.
    private func finish(_ change: @escaping () async -> Bool) {
        Task {
            if await change() {
                await onChange()
                dismiss()
            }
        }
    }
}
