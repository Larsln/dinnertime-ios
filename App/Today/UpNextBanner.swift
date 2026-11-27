import DinnertimeKit
import SwiftUI

/// The next meal to cook as a wide card: the cover of the recipe, when and for which meal it is planned, its title and the servings.
struct UpNextBanner: View {
    private static let coverRatio: CGFloat = 16 / 9

    let entry: MealPlanEntry
    /// The day the banner is shown on.
    let today: DayDate

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.accentSoft
                .aspectRatio(Self.coverRatio, contentMode: .fit)
                .overlay {
                    CoverImage(url: entry.recipe.coverURL ?? entry.recipe.coverThumbURL)
                }
                .clipped()
            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: "\(dayText) · \(entry.meal.label)")
                    .overlineStyle(.accentDeep)
                Text(verbatim: entry.recipe.title)
                    .brandFont(size: 24, relativeTo: .title2)
                    .foregroundStyle(.ink)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                Label {
                    PortionsText(entry: entry)
                } icon: {
                    Image(systemName: "person.2.fill")
                }
                .font(.footnote)
                .foregroundStyle(.inkMuted)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.sunken, in: .capsule)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.surface)
        .clipShape(.card)
        .overlay {
            RoundedRectangle.card.strokeBorder(.line)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }

    /// "Today", "Tomorrow", or weekday and date for later days.
    private var dayText: String {
        switch entry.date.days(since: today) {
        case 0: String(localized: "Today")
        case 1: String(localized: "Tomorrow")
        default: entry.date.longText
        }
    }
}
