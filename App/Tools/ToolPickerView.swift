import DinnertimeKit
import SwiftUI

/// Lets the user search the tools and choose one, optionally creating it from the typed name.
struct ToolPickerView: View {
    let allowsCreation: Bool
    let onSelect: (Tool) -> Void

    @State private var model: ToolCatalogModel
    @Environment(\.dismiss) private var dismiss

    init(session: AppSession, allowsCreation: Bool, onSelect: @escaping (Tool) -> Void) {
        self.allowsCreation = allowsCreation
        self.onSelect = onSelect
        _model = State(initialValue: ToolCatalogModel(session: session))
    }

    var body: some View {
        List {
            ForEach(model.tools) { tool in
                Button {
                    choose(tool)
                } label: {
                    Text(verbatim: tool.name)
                }
                .tint(.primary)
            }
            if let name = creatableName {
                Button("Create “\(name)”", systemImage: "plus", action: create)
            }
        }
        .overlay {
            if model.hasLoaded, model.tools.isEmpty, creatableName == nil {
                ContentUnavailableView.search(text: model.searchText)
            }
        }
        .searchable(text: $model.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search tools")
        .navigationTitle("Choose tool")
        .navigationBarTitleDisplayMode(.inline)
        .debouncedSearch(model.searchText, isFirst: !model.hasLoaded, search: model.search)
        .errorAlert($model.errorMessage)
    }

    private var creatableName: String? {
        allowsCreation ? model.creatableName : nil
    }

    private func choose(_ tool: Tool) {
        onSelect(tool)
        dismiss()
    }

    private func create() {
        Task {
            if let tool = await model.create() {
                choose(tool)
            }
        }
    }
}
