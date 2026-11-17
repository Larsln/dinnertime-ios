import MealplannerKit
import SwiftUI

/// Products whose suggested values wait for confirmation.
struct ReviewView: View {
    let session: AppSession

    @State private var model: ReviewModel

    init(session: AppSession) {
        self.session = session
        _model = State(initialValue: ReviewModel(session: session))
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(model.products) { product in
                    Section {
                        ReviewProductDetails(product: product)
                        Button("Confirm", systemImage: "checkmark") {
                            Task {
                                await model.confirm(product)
                            }
                        }
                        .disabled(model.confirmingIDs.contains(product.id))
                    } header: {
                        Text(verbatim: product.name)
                    }
                }
                if model.hasMore {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .task {
                            await model.loadMore()
                        }
                }
            }
            .overlay {
                if model.hasLoaded, model.products.isEmpty {
                    ContentUnavailableView("Nothing to review", systemImage: "checkmark.seal", description: Text("New products from imports appear here with suggested values."))
                }
            }
            .navigationTitle("Review")
            .settingsToolbar(session: session)
            .refreshable {
                await model.reload()
            }
            .task {
                await model.reload()
            }
            .errorAlert($model.errorMessage)
        }
    }
}
