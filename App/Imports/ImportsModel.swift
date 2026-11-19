import Foundation
import DinnertimeKit
import Observation

/// Queues imports and follows them until they are completed or failed.
@MainActor
@Observable
final class ImportsModel: ErrorReporting {
    private static let pollInterval: Duration = .seconds(3)

    /// Text of the input field, a link or text that contains one.
    var link = ""
    /// Number of dishes the user says the video shows; `nil` lets the server find out.
    var dishCount: Int?
    var errorMessage: String?
    private(set) var imports: [RecipeImport] = []
    private(set) var isSubmitting = false

    private let session: AppSession

    init(session: AppSession) {
        self.session = session
    }

    /// The link found in the input, if any.
    var url: URL? {
        LinkExtractor.firstURL(in: link)
    }

    /// Loads the recent imports.
    func load() async {
        await attempt {
            imports = try await session.send(ImportEndpoints.list)
        }
    }

    /// Queues the entered link; without a connection it is kept and submitted later.
    func submit() async {
        guard let url else {
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }
        guard session.offline.isOnline else {
            session.offline.keep(url, dishCount: dishCount)
            clearInput()
            return
        }
        await attempt {
            do {
                let created = try await session.send(ImportEndpoints.create(url: url, dishCount: dishCount))
                imports.removeAll { $0.id == created.id }
                imports.insert(created, at: 0)
            } catch APIError.unreachable {
                session.offline.keep(url, dishCount: dishCount)
            }
            clearInput()
        }
    }

    private func clearInput() {
        link = ""
        dishCount = nil
    }

    /// Queues a failed import again.
    func retry(_ failed: RecipeImport) async {
        await attempt {
            replace(try await session.send(ImportEndpoints.retry(id: failed.id)))
        }
    }

    /// Refreshes unfinished imports at a fixed interval until the surrounding task is cancelled.
    func poll() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: Self.pollInterval)
            for active in imports where active.isActive {
                if let current = try? await session.send(ImportEndpoints.detail(id: active.id)) {
                    replace(current)
                }
            }
        }
    }

    private func replace(_ updated: RecipeImport) {
        if let index = imports.firstIndex(where: { $0.id == updated.id }) {
            imports[index] = updated
        }
    }
}
