import SwiftUI

extension View {
    /// Uses a number pad. It has no return key; the bar ``KeyboardBar`` puts above every keyboard hides it.
    func numericKeyboard(_ type: UIKeyboardType) -> some View {
        keyboardType(type)
    }
}
