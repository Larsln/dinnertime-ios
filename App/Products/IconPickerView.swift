import DinnertimeKit
import SwiftUI

/// Sheet that searches the product icons by name and chooses one, or returns to the icon of the store section.
struct IconPickerView: View {
    private static let columns = [GridItem(.adaptive(minimum: 76), spacing: 10)]

    @Binding var selection: String?
    /// Key of the store section whose icon is shown without a choice.
    let sectionKey: String?

    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Button {
                        choose(nil)
                    } label: {
                        Label {
                            Text("Use the icon of the section")
                        } icon: {
                            ProductIcon(key: nil, sectionKey: sectionKey)
                                .frame(width: 24, height: 24)
                        }
                    }
                    .buttonStyle(.bordered)
                    LazyVGrid(columns: Self.columns, spacing: 10) {
                        ForEach(icons) { icon in
                            cell(for: icon)
                        }
                    }
                }
                .padding()
            }
            .overlay {
                if icons.isEmpty {
                    ContentUnavailableView("No matching icon.", systemImage: "magnifyingglass")
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("Icon on the shopping list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var icons: [ProductIconCatalog.Entry] {
        ProductIconCatalog.bundled?.productIcons(matching: searchText, languageCode: ProductIconCatalog.languageCode) ?? []
    }

    private func cell(for icon: ProductIconCatalog.Entry) -> some View {
        let isChosen = icon.key == selection
        return Button {
            choose(icon.key)
        } label: {
            VStack(spacing: 4) {
                ProductIcon(key: icon.key, sectionKey: nil)
                    .frame(width: 32, height: 32)
                Text(verbatim: icon.name(languageCode: ProductIconCatalog.languageCode))
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .foregroundStyle(isChosen ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .background(isChosen ? AnyShapeStyle(.tint) : AnyShapeStyle(Color.secondary.opacity(0.12)), in: .rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }

    private func choose(_ key: String?) {
        selection = key
        dismiss()
    }
}
