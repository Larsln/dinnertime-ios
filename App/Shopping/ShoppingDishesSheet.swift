import DinnertimeKit
import SwiftUI

/// The meals a shopping list was made for, each with the products the list holds for it.
///
/// The meals come from the plan of the period, so the sheet also works without a connection.
struct ShoppingDishesSheet: View {
    let session: AppSession
    let list: ShoppingList

    @State private var entries: [MealPlanEntry]?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Meals of this list")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                .task {
                    entries = (try? await session.send(MealPlanEndpoints.entries(from: list.startsOn, to: list.endsOn))) ?? []
                }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private var content: some View {
        if let entries {
            let dishes = list.dishes(from: entries)
            if dishes.isEmpty {
                ContentUnavailableView("No meals planned", systemImage: "fork.knife", description: Text("Nothing is planned for the days of this list."))
            } else {
                List(dishes) { dish in
                    ShoppingDishRow(dish: dish)
                }
            }
        } else {
            ProgressView()
        }
    }
}

/// One meal of a shopping list: day, title and servings, and below in small type what the list holds for it.
private struct ShoppingDishRow: View {
    let dish: ShoppingDish

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: "\(dish.entry.date.weekdayDayText) · \(dish.entry.meal.label)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(verbatim: dish.entry.recipe.title)
                .font(.headline)
            Text("\(dish.entry.servings) servings")
                .font(.caption)
                .foregroundStyle(.secondary)
            if !dish.ingredients.isEmpty {
                ingredients
                    .font(.footnote)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 2)
    }

    private var ingredients: Text {
        dish.ingredients.enumerated().reduce(Text(verbatim: "")) { text, element in
            text + Text(verbatim: element.offset == 0 ? "" : " · ").foregroundStyle(.secondary) + self.text(of: element.element)
        }
    }

    private func text(of ingredient: ShoppingDish.Ingredient) -> Text {
        switch ingredient.source {
        case .open:
            Text(verbatim: ingredient.text())
        case .settled, .skipped:
            Text(verbatim: ingredient.text()).strikethrough().foregroundStyle(.secondary)
        case .stock:
            Text("\(ingredient.text()) (in stock)").foregroundStyle(.secondary)
        }
    }
}
