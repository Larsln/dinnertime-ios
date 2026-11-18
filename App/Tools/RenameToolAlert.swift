import MealplannerKit
import SwiftUI

/// Asks for the new name of a tool in an alert.
private struct RenameToolAlert: ViewModifier {
    @Binding var tool: Tool?
    let onRename: (Tool, String) -> Void

    @State private var name = ""

    func body(content: Content) -> some View {
        content
            .alert("Rename tool", isPresented: isPresented, presenting: tool) { tool in
                TextField("Name", text: $name)
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    if let name = name.nilIfBlank {
                        onRename(tool, name)
                    }
                }
            }
            .onChange(of: tool) { _, tool in
                name = tool?.name ?? name
            }
    }

    private var isPresented: Binding<Bool> {
        Binding(
            get: { tool != nil },
            set: { if !$0 { tool = nil } }
        )
    }
}

extension View {
    /// Presents an alert that renames `tool` and clears it when the alert is dismissed.
    func renameToolAlert(_ tool: Binding<Tool?>, onRename: @escaping (Tool, String) -> Void) -> some View {
        modifier(RenameToolAlert(tool: tool, onRename: onRename))
    }
}
