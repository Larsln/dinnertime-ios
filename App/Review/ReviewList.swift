import MealplannerKit
import SwiftUI

/// Products whose suggested values wait for confirmation, each with the way to its editor.
struct ReviewList: View {
    let model: ReviewModel

    var body: some View {
        List {
            if !model.products.isEmpty {
                Text("These values were estimated by the AI. Confirm or correct them so the shopping list and conversions are right.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }
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
                ContentUnavailableView("All reviewed", systemImage: "checkmark.circle", description: Text("New products from imports appear here with suggested values."))
            }
        }
        .refreshesFromServer {
            await model.reload()
        }
    }
}
