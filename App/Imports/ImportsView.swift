import MealplannerKit
import SwiftUI

/// Imports a recipe from a pasted link and lists the recent imports.
struct ImportsView: View {
    let session: AppSession

    @State private var model: ImportsModel
    @Environment(\.dismiss) private var dismiss

    init(session: AppSession) {
        self.session = session
        _model = State(initialValue: ImportsModel(session: session))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Link to a recipe or video", text: $model.link)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    HStack {
                        PasteButton(payloadType: String.self) { texts in
                            paste(texts)
                        }
                        .labelStyle(.titleAndIcon)
                        Spacer()
                        Button("Import", action: submit)
                            .buttonStyle(.borderedProminent)
                            .disabled(model.url == nil || model.isSubmitting)
                    }
                }
                Section("Recent imports") {
                    ForEach(model.imports) { item in
                        ImportRow(item: item) {
                            retry(item)
                        }
                    }
                }
            }
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: RecipeSummary.self) { recipe in
                RecipeDetailView(session: session, summary: recipe)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await model.load()
                await model.poll()
            }
            .errorAlert($model.errorMessage)
        }
    }

    private func paste(_ texts: [String]) {
        Task { @MainActor in
            model.link = texts.first ?? ""
        }
    }

    private func submit() {
        Task {
            await model.submit()
        }
    }

    private func retry(_ item: RecipeImport) {
        Task {
            await model.retry(item)
        }
    }
}
