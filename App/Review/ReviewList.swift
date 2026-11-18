import MealplannerKit
import SwiftUI

/// Products whose suggested values wait for confirmation, each with the way to its editor.
struct ReviewList: View {
    let model: ReviewModel

    var body: some View {
        List {
            ForEach(model.products) { product in
                Section {
                    ReviewProductDetails(product: product)
                    NavigationLink(value: product) {
                        Label("Edit", systemImage: "pencil")
                    }
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
        .refreshable {
            await model.reload()
        }
    }
}
