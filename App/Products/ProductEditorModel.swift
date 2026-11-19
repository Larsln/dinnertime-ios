import DinnertimeKit
import Observation

/// Loads a product with its packages and conversions and applies the changes of its editor.
@MainActor
@Observable
final class ProductEditorModel: ErrorReporting {
    var errorMessage: String?
    var draft: ProductDraft
    /// The product as the server holds it.
    private(set) var product: Product
    private(set) var storeSections: [StoreSection] = []
    private(set) var units: [MeasureUnit] = []
    private(set) var isWorking = false

    let session: AppSession

    init(session: AppSession, product: Product) {
        self.session = session
        self.product = product
        draft = ProductDraft(product)
    }

    /// Whether the product, a package or a conversion still carries a suggested value.
    var hasSuggestions: Bool {
        product.status == .suggested
            || (product.packages ?? []).contains { $0.status == .suggested }
            || (product.conversions ?? []).contains { $0.status == .suggested }
    }

    /// Units the draft has no conversion for yet.
    var addableUnits: [MeasureUnit] {
        units.filter { unit in !draft.conversions.contains { $0.unit.id == unit.id } }
    }

    /// Loads the complete product and the lists to choose from.
    func load() async {
        await attempt {
            try await reloadProduct()
            storeSections = try await session.send(ReferenceEndpoints.storeSections)
            units = try await session.send(ReferenceEndpoints.units)
        }
    }

    /// Saves the draft and optionally confirms the product; returns whether the server accepted all of it.
    ///
    /// After a failure the editor shows what the server holds, because a part may have been saved.
    func save(confirming: Bool) async -> Bool {
        await work {
            do {
                try await ProductSaver(session: session, product: product, draft: draft).save(confirming: confirming)
            } catch {
                try? await reloadProduct()
                throw error
            }
        }
    }

    /// Moves the recipe lines of the product to `target` and deletes it; returns whether the server accepted it.
    func merge(into target: Product) async -> Bool {
        await work {
            _ = try await session.send(ProductEndpoints.merge(id: product.id, into: target.id))
        }
    }

    /// Deletes the product; the server refuses while a recipe uses it.
    func delete() async -> Bool {
        await work {
            try await session.send(ProductEndpoints.delete(id: product.id))
        }
    }

    private func reloadProduct() async throws {
        product = try await session.send(ProductEndpoints.detail(id: product.id))
        draft = ProductDraft(product)
    }

    private func work(_ operation: () async throws -> Void) async -> Bool {
        isWorking = true
        defer { isWorking = false }
        return await attempt(operation)
    }
}
