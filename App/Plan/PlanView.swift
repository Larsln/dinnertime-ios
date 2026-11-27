import DinnertimeKit
import SwiftUI

/// The meal plan of one week: on narrow screens a strip of its days above one section of cards per day,
/// on wide screens the days as columns side by side.
struct PlanView: View {
    let session: AppSession
    /// Switches to the shopping list after one was created from the plan.
    let onShowShopping: () -> Void

    @Bindable var selection: WeekSelection
    @State private var model: PlanModel
    @Environment(HouseholdStore.self) private var household
    @State private var draft: PlanEntryDraft?
    @State private var showsWizard = false
    @Environment(\.horizontalSizeClass) private var sizeClass

    init(session: AppSession, selection: WeekSelection, onShowShopping: @escaping () -> Void) {
        self.session = session
        self.onShowShopping = onShowShopping
        self.selection = selection
        _model = State(initialValue: PlanModel(session: session))
    }

    var body: some View {
        NavigationStack {
            Group {
                if sizeClass == .regular {
                    PlanBoard(session: session, week: $selection.week, model: model, onAdd: plan, onEdit: edit, onShowShopping: onShowShopping)
                } else {
                    days
                }
            }
            .navigationTitle("Plan")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: RecipeSummary.self) { recipe in
                RecipeDetailView(session: session, summary: recipe)
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Plan week", systemImage: "wand.and.stars") {
                        showsWizard = true
                    }
                    Button("Plan a meal", systemImage: "plus") {
                        plan(on: defaultDay)
                    }
                }
            }
            .sheet(item: $draft) { draft in
                PlanEntryForm(session: session, draft: draft, onSave: model.save)
            }
            .sheet(isPresented: $showsWizard) {
                PlanWizardView(session: session, weeks: selection, plan: model, servings: household.defaultServings, onFinish: finishPlanning)
            }
            .refreshesFromServer {
                await model.load(selection.week)
            }
            .task(id: selection.week) {
                await model.load(selection.week)
            }
            .reloadsOnChange(of: .plan) {
                await model.load(selection.week)
            }
            .errorAlert($model.errorMessage)
        }
    }

    /// The days below each other, each with its meals as rows.
    private var days: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(selection.week.days, id: \.self) { day in
                    PlanDaySection(day: day, model: model, onAdd: { plan(on: day) }, onEdit: edit)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 8) {
                    PlanWeekHeader(week: $selection.week)
                    WeekStrip(week: selection.week, plannedDays: model.plannedDays) { day in
                        withAnimation {
                            proxy.scrollTo(day, anchor: .top)
                        }
                    }
                }
                .padding(.vertical, 8)
                .background(.paper)
            }
            .listStyle(.plain)
            .paperBackground()
        }
    }

    /// Starts planning a meal on `day` with the usual servings of the household.
    private func plan(on day: DayDate) {
        draft = PlanEntryDraft(day: day, servings: household.defaultServings, members: household.members)
    }

    /// Opens a planned meal for changes.
    private func edit(_ entry: MealPlanEntry) {
        draft = PlanEntryDraft(entry: entry)
    }

    /// Reloads the plan after proposals were saved and, if asked to, creates the shopping list and shows it.
    private func finishPlanning(createsShoppingList: Bool) {
        Task {
            await model.load(selection.week)
            if createsShoppingList, await model.createShoppingList() {
                onShowShopping()
            }
        }
    }

    /// The day a meal added from the toolbar starts on: today, or the first day of another week.
    private var defaultDay: DayDate {
        selection.week.isCurrent ? DayDate(.now) : selection.week.start
    }
}
