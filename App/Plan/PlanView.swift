import MealplannerKit
import SwiftUI

/// The meal plan of one week: a strip of its days above one section of cards per day.
struct PlanView: View {
    let session: AppSession
    /// Switches to the shopping list after one was created from the plan.
    let onShowShopping: () -> Void

    @Bindable var selection: WeekSelection
    @State private var model: PlanModel
    @State private var draft: PlanEntryDraft?
    @State private var showsWizard = false

    init(session: AppSession, selection: WeekSelection, onShowShopping: @escaping () -> Void) {
        self.session = session
        self.onShowShopping = onShowShopping
        self.selection = selection
        _model = State(initialValue: PlanModel(session: session))
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    ForEach(selection.week.days, id: \.self) { day in
                        PlanDaySection(day: day, model: model) {
                            draft = PlanEntryDraft(day: day)
                        }
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
                    .background(.bar)
                }
            }
            .navigationTitle("Plan")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: RecipeSummary.self) { recipe in
                RecipeDetailView(session: session, summary: recipe)
            }
            .settingsToolbar(session: session)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Plan week", systemImage: "wand.and.stars") {
                        showsWizard = true
                    }
                    Button("Plan a meal", systemImage: "plus") {
                        draft = PlanEntryDraft(day: defaultDay)
                    }
                }
            }
            .sheet(item: $draft) { draft in
                AddEntryView(session: session, draft: draft, onAdd: model.add)
            }
            .sheet(isPresented: $showsWizard) {
                PlanWizardView(session: session, weeks: selection, plan: model, onFinish: finishPlanning)
            }
            .refreshable {
                await model.load(selection.week)
            }
            .task(id: selection.week) {
                await model.load(selection.week)
            }
            .errorAlert($model.errorMessage)
        }
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
