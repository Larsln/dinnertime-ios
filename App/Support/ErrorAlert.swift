import SwiftUI

extension View {
    /// Presents `message` in an alert and clears it when the alert is dismissed.
    func errorAlert(_ message: Binding<String?>) -> some View {
        let isPresented = Binding(
            get: { message.wrappedValue != nil },
            set: { if !$0 { message.wrappedValue = nil } }
        )
        return alert("Something went wrong", isPresented: isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(verbatim: message.wrappedValue ?? "")
        }
    }
}
