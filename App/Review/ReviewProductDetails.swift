import MealplannerKit
import SwiftUI

/// The values the server suggests for a product.
struct ReviewProductDetails: View {
    let product: Product

    private let formatter = AmountFormatter()

    var body: some View {
        LabeledContent("Store section", value: product.storeSection?.name ?? Self.missing)
        LabeledContent("Base unit", value: product.baseUnit.label)
        if let days = product.shelfLifeOpenedDays {
            LabeledContent("Shelf life once opened (days)", value: days, format: .number)
        } else {
            LabeledContent("Shelf life once opened (days)", value: Self.missing)
        }
        if let isStaple = product.isPantryStaple {
            LabeledContent("Pantry staple") {
                Text(isStaple ? "Yes" : "No")
            }
        }
        ForEach(product.packages ?? []) { package in
            LabeledContent {
                value(formatter.string(package.amountInBase, unit: product.baseUnit), status: package.status)
            } label: {
                Text("Package: \(package.label)")
            }
        }
        ForEach(product.conversions ?? []) { conversion in
            LabeledContent {
                value(formatter.string(conversion.amountInBase, unit: product.baseUnit), status: conversion.status)
            } label: {
                Text(verbatim: "1 \(conversion.unit.code ?? conversion.unit.name)")
            }
        }
        if let count = product.recipeCount {
            LabeledContent("Used in recipes", value: count, format: .number)
        }
    }

    private static let missing = "–"

    private func value(_ text: String, status: ReviewStatus) -> some View {
        HStack(spacing: 4) {
            if status == .suggested {
                Label("Suggested", systemImage: "sparkles")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.orange)
            }
            Text(verbatim: text)
        }
    }
}
