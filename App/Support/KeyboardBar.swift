import UIKit

/// Gives every keyboard of the app a bar with a button that hides it.
///
/// Number pads have no key for that and multi-line fields start a new line on return, so the button is added in
/// one place for all of them: whenever a field starts being edited, the bar becomes its input accessory.
@MainActor
final class KeyboardBar: NSObject {
    static let shared = KeyboardBar()

    private static let height: CGFloat = 44

    private lazy var bar: UIToolbar = {
        let bar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: Self.height))
        let hide = UIBarButtonItem(
            image: UIImage(systemName: "keyboard.chevron.compact.down"),
            style: .plain,
            target: self,
            action: #selector(hideKeyboard)
        )
        hide.accessibilityLabel = String(localized: "Hide keyboard")
        hide.accessibilityIdentifier = "hide-keyboard"
        bar.items = [UIBarButtonItem(systemItem: .flexibleSpace), hide]
        bar.autoresizingMask = .flexibleWidth
        return bar
    }()

    /// Starts adding the bar to every field that is edited from now on.
    func install() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(editingBegan), name: UITextField.textDidBeginEditingNotification, object: nil)
        center.addObserver(self, selector: #selector(editingBegan), name: UITextView.textDidBeginEditingNotification, object: nil)
    }

    @objc private func editingBegan(_ notification: Notification) {
        if let field = notification.object as? UITextField, field.inputAccessoryView !== bar {
            field.inputAccessoryView = bar
            field.reloadInputViews()
        } else if let view = notification.object as? UITextView, view.inputAccessoryView !== bar {
            view.inputAccessoryView = bar
            view.reloadInputViews()
        }
    }

    @objc private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
