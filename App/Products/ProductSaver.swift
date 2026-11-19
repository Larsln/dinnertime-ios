import DinnertimeKit

/// Sends the difference between a product and its edited draft to the server.
@MainActor
struct ProductSaver {
    let session: AppSession
    let product: Product
    let draft: ProductDraft

    /// Updates the product, its packages and conversions, and confirms all of it if asked to.
    func save(confirming: Bool) async throws {
        _ = try await session.send(ProductEndpoints.update(id: product.id, draft.input))
        try await savePackages()
        try await saveConversions()
        if confirming {
            _ = try await session.send(ProductEndpoints.confirm(id: product.id))
        }
    }

    /// Removes the packages that left the draft, then adds the new and corrects the changed ones.
    private func savePackages() async throws {
        let original = product.packages ?? []
        let kept = Set(draft.packages.compactMap(\.packageID))
        for package in original where !kept.contains(package.id) {
            try await session.send(ProductValueEndpoints.deletePackage(id: package.id))
        }
        for row in draft.packages {
            guard let label = row.label.nilIfBlank, let amount = row.amount, amount > 0 else {
                continue
            }
            guard let id = row.packageID else {
                _ = try await session.send(ProductValueEndpoints.addPackage(productID: product.id, label: label, amountInBase: amount))
                continue
            }
            let before = original.first { $0.id == id }
            if before?.label != label || before?.amountInBase != amount {
                _ = try await session.send(ProductValueEndpoints.updatePackage(id: id, label: label, amountInBase: amount))
            }
        }
    }

    /// Removes the conversions that left the draft, then sets the new and changed ones.
    private func saveConversions() async throws {
        let original = product.conversions ?? []
        let kept = Set(draft.conversions.map(\.unit.id))
        for conversion in original where !kept.contains(conversion.unit.id) {
            try await session.send(ProductValueEndpoints.deleteConversion(productID: product.id, unitID: conversion.unit.id))
        }
        for row in draft.conversions where row.isComplete {
            let before = original.first { $0.unit.id == row.unit.id }
            if before == nil || before?.amountInBase != row.savedAmount {
                _ = try await session.send(ProductValueEndpoints.setConversion(productID: product.id, unitID: row.unit.id, amountInBase: row.savedAmount))
            }
        }
    }
}
