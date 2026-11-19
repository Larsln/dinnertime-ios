import SwiftUI

/// A chip that switches one filter on and off.
struct FilterChip: View {
    private static let minHeight: CGFloat = 38

    let name: String
    let isOn: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            Text(verbatim: name)
                .font(.subheadline)
                .fontWeight(isOn ? .semibold : .regular)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .frame(minHeight: Self.minHeight)
                .foregroundStyle(isOn ? Color.onAccent : Color.ink)
                .background(isOn ? Color.accent : Color.surface, in: .capsule)
                .overlay {
                    if !isOn {
                        Capsule()
                            .strokeBorder(.line)
                    }
                }
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// A chip that names a filter that is switched on and switches it off when tapped.
struct RemovableChip: View {
    private static let height: CGFloat = 32

    let name: Text
    let onRemove: () -> Void

    var body: some View {
        Button(action: onRemove) {
            HStack(spacing: 4) {
                name
                    .lineLimit(1)
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
            }
            .font(.subheadline.weight(.medium))
            .padding(.leading, 12)
            .padding(.trailing, 10)
            .frame(height: Self.height)
            .foregroundStyle(.accentDeep)
            .background(.accentSoft, in: .capsule)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Remove \(name)"))
    }
}
