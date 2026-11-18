import SwiftUI

/// A labeled input for an optional whole number.
struct NumberField: View {
    let title: LocalizedStringKey
    @Binding var value: Int?

    var body: some View {
        LabeledContent(title) {
            TextField(title, value: $value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .labelsHidden()
        }
    }
}
