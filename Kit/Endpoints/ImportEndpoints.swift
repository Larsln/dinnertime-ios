import Foundation

/// Imports of recipes from links.
public enum ImportEndpoints {
    private struct CreateBody: Encodable {
        let url: String
    }

    /// `POST /imports`: queues the import of a link.
    public static func create(url: URL) -> Endpoint<RecipeImport> {
        .resource(.post, "imports", body: CreateBody(url: url.absoluteString))
    }

    /// `GET /imports`: the most recent imports.
    public static var list: Endpoint<[RecipeImport]> {
        .resource(.get, "imports")
    }

    /// `GET /imports/{id}`: the current state of one import.
    public static func detail(id: Int) -> Endpoint<RecipeImport> {
        .resource(.get, "imports/\(id)")
    }

    /// `POST /imports/{id}/retry`: queues a failed import again.
    public static func retry(id: Int) -> Endpoint<RecipeImport> {
        .resource(.post, "imports/\(id)/retry")
    }
}
