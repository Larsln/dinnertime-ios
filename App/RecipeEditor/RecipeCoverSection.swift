import PhotosUI
import SwiftUI

/// Chooses a photo from the library as the cover image of a recipe.
struct RecipeCoverSection: View {
    private static let previewHeight: CGFloat = 160

    let model: RecipeEditorModel

    @State private var selection: PhotosPickerItem?

    var body: some View {
        Section {
            if let cover = model.cover, let image = UIImage(data: cover) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: Self.previewHeight)
                    .clipped()
                    .listRowInsets(EdgeInsets())
            }
            PhotosPicker(selection: $selection, matching: .images) {
                Label("Choose cover image", systemImage: "photo")
            }
        }
        .onChange(of: selection) { _, item in
            Task {
                await model.chooseCover(item)
            }
        }
    }
}
