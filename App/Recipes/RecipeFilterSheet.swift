import DinnertimeKit
import SwiftUI

/// The filters of the recipe list: courses and meals, of which one has to fit, properties, which all have to fit,
/// and the favorites. Every change applies at once.
struct RecipeFilterSheet: View {
    @Bindable var model: RecipeListModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if !model.courses.isEmpty {
                        RecipeFilterGroup(title: "Category", hint: "one of them") {
                            ForEach(model.courses) { course in
                                FilterChip(name: course.name, isOn: model.query.courses.contains(course.key)) {
                                    model.query.toggle(course: course.key)
                                }
                            }
                        }
                    }
                    tagGroup("Meal", hint: "one of them", kind: .meal)
                    tagGroup("Properties", hint: "all of them", kind: .tag)
                    Toggle("Favorites only", isOn: $model.query.favoritesOnly)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 52)
                        .surface(in: .tile)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(.paper)
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") {
                        model.query.resetFilters()
                    }
                    .disabled(!model.query.isFiltered)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private func tagGroup(_ title: LocalizedStringKey, hint: LocalizedStringKey, kind: Tag.Kind) -> some View {
        let tags = model.tags(of: kind)
        if !tags.isEmpty {
            RecipeFilterGroup(title: title, hint: hint) {
                ForEach(tags) { tag in
                    FilterChip(name: tag.name, isOn: model.query.tagIDs.contains(tag.id)) {
                        model.query.toggle(tagID: tag.id)
                    }
                }
            }
        }
    }
}

/// A group of filter chips under its name and a hint that tells how the chosen ones combine.
private struct RecipeFilterGroup<Chips: View>: View {
    let title: LocalizedStringKey
    let hint: LocalizedStringKey
    @ViewBuilder let chips: Chips

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .sectionHeadingStyle()
                    .accessibilityAddTraits(.isHeader)
                Text(hint)
                    .font(.footnote)
                    .foregroundStyle(.inkMuted)
            }
            FlowLayout {
                chips
            }
        }
    }
}
