import Foundation
import DinnertimeKit
import Observation
import PhotosUI
import SwiftUI

/// Holds the draft of a recipe, the lists to choose from and saves the draft.
@MainActor
@Observable
final class RecipeEditorModel: ErrorReporting {
    var errorMessage: String?
    var draft: RecipeDraft
    /// The newly chosen cover image as JPEG; `nil` keeps the stored one.
    private(set) var cover: Data?
    private(set) var courses: [Course] = []
    /// What a side can be based on; empty while the server does not tell.
    private(set) var sideKinds: [SideKind] = []
    private(set) var units: [MeasureUnit] = []
    private(set) var tags: [Tag] = []
    private(set) var isSaving = false
    /// The recipe on the server; `nil` until a new recipe was saved for the first time.
    private(set) var recipeID: Int?

    let session: AppSession

    init(session: AppSession, recipe: Recipe?) {
        self.session = session
        recipeID = recipe?.id
        draft = recipe.map(RecipeDraft.init) ?? RecipeDraft()
    }

    /// Tags of one group that the recipe can carry.
    func tags(of kind: Tag.Kind) -> [Tag] {
        tags.filter { $0.type == kind }
    }

    /// Loads the courses, units, tags and kinds of side to choose from.
    func loadReferences() async {
        sideKinds = (try? await session.send(ReferenceEndpoints.sideKinds)) ?? []
        await attempt {
            courses = try await session.send(ReferenceEndpoints.courses)
            units = try await session.send(ReferenceEndpoints.units)
            tags = try await session.send(ReferenceEndpoints.tags)
        }
    }

    /// Takes over a photo from the library as the new cover image.
    func chooseCover(_ item: PhotosPickerItem?) async {
        guard let item else {
            return
        }
        guard let data = try? await item.loadTransferable(type: Data.self), let jpeg = CoverEncoder.jpeg(from: data) else {
            errorMessage = String(localized: "The image could not be read.")
            return
        }
        cover = jpeg
    }

    /// Creates or updates the recipe and uploads a newly chosen cover image.
    ///
    /// Returns the saved recipe, or `nil` if a quantity cannot be read or the server rejected a part. A recipe that was created
    /// before its cover failed is updated by the next attempt instead of created again.
    func save() async -> Recipe? {
        guard !draft.hasUnreadableQuantity else {
            errorMessage = String(localized: "Quantity not readable. Allowed are e.g. 2, 1.5, 1/2 or 1 1/2.")
            return nil
        }
        isSaving = true
        defer { isSaving = false }
        var saved: Recipe?
        await attempt {
            let input = draft.input
            var recipe = try await session.send(recipeID.map { RecipeEndpoints.update(id: $0, input) } ?? RecipeEndpoints.create(input))
            recipeID = recipe.id
            if let cover {
                recipe = try await session.send(RecipeEndpoints.uploadCover(id: recipe.id, jpeg: cover))
                self.cover = nil
            }
            saved = recipe
        }
        return saved
    }
}
