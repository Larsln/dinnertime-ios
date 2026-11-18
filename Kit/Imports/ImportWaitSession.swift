import Foundation

/// The background transfers that wait for the outcome of imports beyond the life of the process that started them.
///
/// Only one process may use a background session at a time, so the share extension and the
/// app each have their own. The system hands the events of both to the app.
public struct ImportWaitSession: Sendable {
    /// The process a session belongs to.
    public enum Owner: String, CaseIterable, Sendable {
        case app, shareExtension
    }

    private static let timeout: TimeInterval = 300

    public let owner: Owner
    private let bundleIdentifier: String
    private let appGroup: String?

    /// Describes the session of `owner`; by default with the identifiers of ``AppConfiguration``.
    public init(owner: Owner, bundleIdentifier: String = AppConfiguration.appBundleIdentifier, appGroup: String? = AppConfiguration.appGroup) {
        self.owner = owner
        self.bundleIdentifier = bundleIdentifier
        self.appGroup = appGroup
    }

    /// Identifier under which the system knows the session.
    public var identifier: String {
        "\(bundleIdentifier).import-wait.\(owner.rawValue)"
    }

    /// Whether `identifier` names this session.
    public func owns(_ identifier: String) -> Bool {
        identifier == self.identifier
    }

    /// Configuration of the session; its files go to the shared container so that the app can read what the extension started.
    public var configuration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        configuration.sharedContainerIdentifier = appGroup
        configuration.sessionSendsLaunchEvents = true
        configuration.timeoutIntervalForRequest = Self.timeout
        return configuration
    }

    /// The request that waits for the outcome of an import as the owner of `credentials`.
    public static func request(importID: Int, credentials: Credentials) throws -> URLRequest {
        let client = APIClient(serverURL: credentials.serverURL, token: credentials.token)
        var request = try client.urlRequest(for: ImportEndpoints.wait(id: importID))
        request.timeoutInterval = timeout
        return request
    }

    /// Starts waiting for an import on `session`; the task is named after the import.
    public static func start(importID: Int, credentials: Credentials, on session: URLSession) throws {
        let task = session.downloadTask(with: try request(importID: importID, credentials: credentials))
        task.taskDescription = String(importID)
        task.resume()
    }

    /// Stops waiting for an import on `session`.
    public static func cancel(importID: Int, on session: URLSession) async {
        for task in await session.allTasks where task.taskDescription == String(importID) {
            task.cancel()
        }
    }
}
