import CoreTransferable
import UIKit
import UniformTypeIdentifiers

/// The error log as a text file to share.
struct ErrorLogFile: Transferable {
    let text: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .plainText) { file in
            Data(file.text.utf8)
        }
        .suggestedFileName("dinnertime-errors.txt")
    }
}

/// What tells builds and devices apart when a log is read: the version of the app and of the system, and the model.
@MainActor
enum DeviceFacts {
    /// One line per fact, as the head of an exported log.
    static var lines: [String] {
        let info = Bundle.main.infoDictionary ?? [:]
        let version = info["CFBundleShortVersionString"] as? String ?? "?"
        let build = info["CFBundleVersion"] as? String ?? "?"
        return [
            "Dinnertime \(version) (\(build))",
            "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)",
            "Device \(model)",
        ]
    }

    /// The hardware identifier of the device, such as "iPhone18,1".
    private static var model: String {
        var system = utsname()
        uname(&system)
        return withUnsafeBytes(of: &system.machine) { bytes in
            String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
        }
    }
}
