import DinnertimeKit
import SwiftUI

/// The recipes on wide screens: the list with what matters today at the left, the chosen recipe at the right.
struct RecipeBrowser: View {
    private static let listWidth: CGFloat = 400
    private static let narrowListWidth: CGFloat = 320
    /// Width of the screen from which the list takes its full width.
    private static let wideScreen: CGFloat = 1000

    let session: AppSession
    let model: RecipeListModel
    let today: TodayModel
    let permission: NotificationPermission
    @Binding var selection: RecipeSelection?
    /// Opens the dinner round, or the start of one.
    let onDecide: () -> Void

    @State private var width: CGFloat = 0

    var body: some View {
        HStack(spacing: 0) {
            RecipeSearchList(model: model, selectedID: selection?.recipe.id, searchesInline: true) {
                TodayPanel(model: today) { planned in
                    selection = RecipeSelection(planned)
                } onDecide: {
                    onDecide()
                }
            } row: { recipe in
                Button {
                    selection = RecipeSelection(recipe: recipe)
                } label: {
                    RecipeRow(recipe: recipe)
                }
                .tint(.ink)
                .accessibilityAddTraits(recipe.id == selection?.recipe.id ? .isSelected : [])
            }
            .notificationOffer(permission)
            .frame(width: width < Self.wideScreen ? Self.narrowListWidth : Self.listWidth)
            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(.paper)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            self.width = width
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let selection {
            RecipeDetailView(
                session: session,
                summary: selection.recipe,
                plannedServings: selection.servings,
                isEmbedded: true,
                onUpdate: model.replace
            ) {
                model.remove(id: selection.recipe.id)
                self.selection = nil
            }
            .id(selection.id)
        } else {
            ContentUnavailableView("No recipe chosen", systemImage: "book", description: Text("Choose a recipe from the list to see its ingredients and method."))
        }
    }
}
