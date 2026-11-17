import SwiftUI
import UIKit

/// Entry point of the share extension: queues the shared link and closes itself.
final class ShareViewController: UIViewController {
    private static let confirmationDuration: Duration = .seconds(1.5)

    private let model = ShareModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        embed(ShareView(model: model) { [weak self] in
            self?.close()
        })
        Task {
            await model.share(extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem } ?? [])
            if model.didSucceed {
                try? await Task.sleep(for: Self.confirmationDuration)
                close()
            }
        }
    }

    private func embed(_ content: some View) {
        let host = UIHostingController(rootView: content)
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.view.backgroundColor = .clear
        view.addSubview(host.view)
        host.didMove(toParent: self)
    }

    private func close() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
