import Foundation
import DinnertimeKit

/// Finds the web link in the content another app shared.
@MainActor
enum SharedLinkLoader {
    /// The first link among the shared URLs, texts and captions.
    static func link(in items: [NSExtensionItem]) async -> URL? {
        let providers = items.flatMap { $0.attachments ?? [] }
        for provider in providers where provider.canLoadObject(ofClass: URL.self) {
            if let url = await loadURL(from: provider), let link = LinkExtractor.firstURL(in: url.absoluteString) {
                return link
            }
        }
        for provider in providers where provider.canLoadObject(ofClass: String.self) {
            if let text = await loadText(from: provider), let link = LinkExtractor.firstURL(in: text) {
                return link
            }
        }
        return items
            .compactMap { $0.attributedContentText?.string }
            .compactMap(LinkExtractor.firstURL(in:))
            .first
    }

    private static func loadURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                continuation.resume(returning: url)
            }
        }
    }

    private static func loadText(from provider: NSItemProvider) async -> String? {
        await withCheckedContinuation { continuation in
            _ = provider.loadObject(ofClass: String.self) { text, _ in
                continuation.resume(returning: text)
            }
        }
    }
}
