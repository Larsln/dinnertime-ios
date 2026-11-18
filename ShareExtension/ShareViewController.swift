import SwiftUI
import UIKit

/// Entry point of the share extension: offers the shared link for import and shows the import until the user closes the sheet.
final class ShareViewController: UIViewController {
    private let model = ShareModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        embed(ShareView(model: model) { [weak self] in
            self?.close()
        })
        Task {
            await model.prepare(extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem } ?? [])
        }
    }

    private func embed(_ content: some View) {
        let host = UIHostingController(rootView: content)
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
    }

    private func close() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
