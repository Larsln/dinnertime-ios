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
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ImportComposer(model: model, onSubmit: submit)
                    if !session.offline.pendingLinks.isEmpty {
                        heading("Waiting for a connection")
                        ForEach(session.offline.pendingLinks, id: \.self) { link in
                            ImportStatusLine(symbol: "clock", tint: .secondary, title: link.url.host() ?? link.url.absoluteString, detail: nil)
                                .importCard()
                        }
                    }
                    if !model.imports.isEmpty {
                        heading("Recent imports")
                        ForEach(model.imports) { item in
                            ImportRow(item: item) {
                                retry(item)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .scrollDismissesKeyboard(.interactively)
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

    private func heading(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.title3.bold())
            .padding(.top, 12)
            .padding(.leading, 4)
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
