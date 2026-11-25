import DinnertimeKit
import SwiftUI

/// A field of several lines for the note of a product, held to the length the server stores.
struct ProductNoteField: View {
    @Binding var text: String

    var body: some View {
        TextField("Note", text: $text, axis: .vertical)
            .lineLimit(1...6)
            .onChange(of: text) {
                if text.count > Product.noteLimit {
                    text = String(text.prefix(Product.noteLimit))
                }
            }
    }
}
