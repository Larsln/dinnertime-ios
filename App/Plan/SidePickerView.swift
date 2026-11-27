import DinnertimeKit
import SwiftUI

/// Lets the user choose a side for a dish from the recipes of the kinds it is served with, those served with it
/// most recently first.
struct SidePickerView: View {
    let session: AppSession
    let dish: RecipeSummary
    /// Recipes that are sides of the meal already.
    var excludedIDs: Set<Int> = []
    let onSelect: (RecipeSummary) -> Void

    /// The sides to choose from; `nil` until they were read.
    @State private var recipes: [RecipeSummary]?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            if let recipes, recipes.isEmpty {
                Text("There is no recipe of a fitting kind of side yet. Give a recipe a kind of side when you edit it.")
                    .font(.subheadline)
                    .foregroundStyle(.inkMuted)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            ForEach(recipes ?? []) { recipe in
                Button {
                    onSelect(recipe)
                    dismiss()
                } label: {
                    RecipeRow(recipe: recipe)
                }
                .tint(.ink)
                .cardRow()
            }
        }
        .listStyle(.plain)
        .paperBackground()
        .navigationTitle("Choose side")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let found = (try? await session.send(RecipeEndpoints.sides(of: dish.id))) ?? []
            recipes = found.filter { !excludedIDs.contains($0.id) }
        }
    }
}

/// The side picker as a sheet of its own, for a meal that is planned already.
struct SidePickerSheet: View {
    let session: AppSession
    let dish: RecipeSummary
    let excludedIDs: Set<Int>
    let onSelect: (RecipeSummary) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            SidePickerView(session: session, dish: dish, excludedIDs: excludedIDs, onSelect: onSelect)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
    }
}
