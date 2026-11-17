import SwiftUI

extension View {
    /// Adds a cancel button and a confirming button to a sheet.
    func sheetToolbar(
        confirm title: LocalizedStringKey,
        isEnabled: Bool,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping () -> Void
    ) -> some View {
        toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: onCancel)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(title, action: onConfirm)
                    .disabled(!isEnabled)
            }
        }
    }
}
