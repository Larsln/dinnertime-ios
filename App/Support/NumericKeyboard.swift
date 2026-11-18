import SwiftUI

/// Adds a button above the keyboard that closes it, for fields whose keyboard has no key for that.
private struct KeyboardDoneButton: ViewModifier {
    @FocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    if isFocused {
                        Spacer()
                        Button("Done") {
                            isFocused = false
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
    }
}

extension View {
    /// Lets the keyboard of a multi-line field, where return starts a new line, be closed with a button above it.
    func keyboardDoneButton() -> some View {
        modifier(KeyboardDoneButton())
    }

    /// Uses a number pad, which has no return key, that can be closed with a button above it.
    func numericKeyboard(_ type: UIKeyboardType) -> some View {
        keyboardType(type).keyboardDoneButton()
    }
}
