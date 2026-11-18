import SwiftUI

/// Asks for the name of something new in an alert.
private struct NameAlert: ViewModifier {
    let title: LocalizedStringKey
    @Binding var isPresented: Bool
    let onCreate: (String) -> Void

    @State private var name = ""

    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: $isPresented) {
                TextField("Name", text: $name)
                Button("Cancel", role: .cancel) {}
                Button("Create") {
                    if let name = name.nilIfBlank {
                        onCreate(name)
                    }
                }
            }
            .onChange(of: isPresented) { _, isPresented in
                if isPresented {
                    name = ""
                }
            }
    }
}

extension View {
    /// Presents an alert that asks for a name and hands it to `onCreate` unless it is blank.
    func nameAlert(_ title: LocalizedStringKey, isPresented: Binding<Bool>, onCreate: @escaping (String) -> Void) -> some View {
        modifier(NameAlert(title: title, isPresented: isPresented, onCreate: onCreate))
    }
}
