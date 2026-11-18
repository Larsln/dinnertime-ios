import MealplannerKit
import Observation

/// Searches the tools of the household and applies changes to them.
@MainActor
@Observable
final class ToolCatalogModel: ErrorReporting {
    var searchText = ""
    var errorMessage: String?
    private(set) var tools: [Tool] = []
    private(set) var hasLoaded = false

    private let session: AppSession

    init(session: AppSession) {
        self.session = session
    }

    /// The typed name, if it is not empty and no listed tool carries it.
    var creatableName: String? {
        guard let name = searchText.nilIfBlank, hasLoaded else {
            return nil
        }
        let isKnown = tools.contains { $0.name.caseInsensitiveCompare(name) == .orderedSame }
        return isKnown ? nil : name
    }

    /// Loads the tools that match the search text.
    func search() async {
        await attempt {
            tools = try await session.send(ToolEndpoints.search(searchText))
            hasLoaded = true
        }
    }

    /// Creates a tool from the typed name.
    func create() async -> Tool? {
        guard let name = creatableName else {
            return nil
        }
        var created: Tool?
        await attempt {
            let tool = try await session.send(ToolEndpoints.create(name: name))
            tools.append(tool)
            created = tool
        }
        return created
    }

    /// States whether the household has a tool; the change shows at once and is undone if the server rejects it.
    func setOwned(_ isOwned: Bool, for tool: Tool) async {
        var optimistic = tool
        optimistic.isOwned = isOwned
        replace(optimistic)
        do {
            replace(try await session.send(ToolEndpoints.setOwned(isOwned, id: tool.id)))
        } catch {
            replace(tool)
            report(error)
        }
    }

    /// Renames a tool; returns whether the server accepted it.
    func rename(_ tool: Tool, to name: String) async -> Bool {
        await attempt {
            replace(try await session.send(ToolEndpoints.rename(id: tool.id, to: name)))
        }
    }

    /// Moves the recipes of a tool to `target` and deletes it; returns whether the server accepted it.
    func merge(_ tool: Tool, into target: Tool) async -> Bool {
        await attempt {
            _ = try await session.send(ToolEndpoints.merge(id: tool.id, into: target.id))
            tools = try await session.send(ToolEndpoints.search(searchText))
        }
    }

    /// Deletes a tool that no recipe uses.
    func delete(_ tool: Tool) async {
        await attempt {
            try await session.send(ToolEndpoints.delete(id: tool.id))
            tools.removeAll { $0.id == tool.id }
        }
    }

    private func replace(_ tool: Tool) {
        if let index = tools.firstIndex(where: { $0.id == tool.id }) {
            tools[index] = tool
        }
    }
}
