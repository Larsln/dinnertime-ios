import MealplannerKit
import SwiftUI

/// All tools of the household with search and the ways to mark, rename, merge and delete them.
struct ToolCatalogList: View {
    let session: AppSession
    @Bindable var model: ToolCatalogModel

    @Environment(OfflineCoordinator.self) private var offline
    @State private var renamedTool: Tool?
    @State private var mergedTool: Tool?
    @State private var deletedTool: Tool?

    var body: some View {
        List(model.tools) { tool in
            ToolRow(tool: tool) { isOwned in
                Task {
                    await model.setOwned(isOwned, for: tool)
                }
            }
            .swipeActions {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    deletedTool = tool
                }
                if offline.isOnline {
                    Button("Merge", systemImage: "arrow.triangle.merge") {
                        mergedTool = tool
                    }
                }
                Button("Rename", systemImage: "pencil") {
                    renamedTool = tool
                }
                .tint(.blue)
            }
        }
        .overlay {
            if model.hasLoaded, model.tools.isEmpty {
                ContentUnavailableView("No tools", systemImage: "frying.pan", description: Text("Tools are added in the recipe editor or by imports."))
            }
        }
        .refreshesFromServer {
            await model.search()
        }
        .debouncedSearch(model.searchText, isFirst: !model.hasLoaded, search: model.search)
        .renameToolAlert($renamedTool) { tool, name in
            Task {
                await model.rename(tool, to: name)
            }
        }
        .sheet(item: $mergedTool) { tool in
            MergeToolView(session: session, tool: tool) { target in
                await model.merge(tool, into: target)
            }
        }
        .confirmationDialog("Delete tool", isPresented: deletionIsPresented, titleVisibility: .visible, presenting: deletedTool) { tool in
            Button("Delete", role: .destructive) {
                Task {
                    await model.delete(tool)
                }
            }
        } message: { tool in
            Text("“\(tool.name)” will be deleted unless a recipe uses it.")
        }
        .errorAlert($model.errorMessage)
    }

    private var deletionIsPresented: Binding<Bool> {
        Binding(
            get: { deletedTool != nil },
            set: { if !$0 { deletedTool = nil } }
        )
    }
}
