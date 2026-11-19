import DinnertimeKit
import SwiftUI

/// The form that starts an import: the link, how many dishes it shows and the button to import it.
struct ImportComposer: View {
    @Bindable var model: ImportsModel
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                linkField
                Text("TikTok, Instagram, YouTube or a web page")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
            }
            DishCountPicker(selection: $model.dishCount)
                .padding(.leading, 4)
            Button(action: onSubmit) {
                Text("Import")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(model.url == nil || model.isSubmitting)
        }
        .importCard()
    }

    private var linkField: some View {
        HStack(spacing: 10) {
            Image(systemName: "link")
                .foregroundStyle(.secondary)
            TextField("Link to a recipe or video", text: $model.link)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .onSubmit(onSubmit)
            PasteButton(payloadType: String.self) { texts in
                Task { @MainActor in
                    model.link = texts.first ?? ""
                }
            }
            .labelStyle(.iconOnly)
            .buttonBorderShape(.capsule)
            .controlSize(.small)
        }
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .frame(minHeight: 48)
        .background(Color(.tertiarySystemFill), in: .rect(cornerRadius: 12))
    }
}

extension View {
    /// The rounded surface the parts of the import screen sit on.
    func importCard() -> some View {
        padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
    }
}
