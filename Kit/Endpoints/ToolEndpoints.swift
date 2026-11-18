import Foundation

/// The catalog of tools.
public enum ToolEndpoints {
    private struct CreateBody: Encodable {
        let name: String
    }

    private struct UpdateBody: Encodable {
        let name: String?
        let isOwned: Bool?
    }

    private struct MergeBody: Encodable {
        let into: Int
    }

    /// `GET /tools`: all tools whose name contains `search`.
    public static func search(_ search: String) -> Endpoint<[Tool]> {
        .resource(.get, "tools", query: [URLQueryItem(name: "search", value: search)])
    }

    /// `POST /tools`: adds a tool the household owns.
    public static func create(name: String) -> Endpoint<Tool> {
        .resource(.post, "tools", body: CreateBody(name: name))
    }

    /// `PATCH /tools/{id}`: renames a tool.
    public static func rename(id: Int, to name: String) -> Endpoint<Tool> {
        .resource(.patch, "tools/\(id)", body: UpdateBody(name: name, isOwned: nil))
    }

    /// `PATCH /tools/{id}`: states whether the household has a tool.
    public static func setOwned(_ isOwned: Bool, id: Int) -> Endpoint<Tool> {
        .resource(.patch, "tools/\(id)", body: UpdateBody(name: nil, isOwned: isOwned))
    }

    /// `DELETE /tools/{id}`: deletes a tool; answers `409` while a recipe uses it.
    public static func delete(id: Int) -> Endpoint<Void> {
        .empty(.delete, "tools/\(id)")
    }

    /// `POST /tools/{id}/merge`: moves the recipes of a tool to `targetID` and deletes it.
    public static func merge(id: Int, into targetID: Int) -> Endpoint<Tool> {
        .resource(.post, "tools/\(id)/merge", body: MergeBody(into: targetID))
    }
}
