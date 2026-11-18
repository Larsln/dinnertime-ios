import SwiftUI

/// A switch with a title and a one-line explanation.
struct PreferenceToggle: View {
    let title: LocalizedStringKey
    let explanation: LocalizedStringKey
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
