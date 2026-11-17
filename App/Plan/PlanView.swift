import MealplannerKit
import SwiftUI

/// The meal plan of one week.
struct PlanView: View {
    let session: AppSession

    @Bindable var selection: WeekSelection
    @State private var model: PlanModel
    @State private var draft: PlanEntryDraft?
    @State private var showsGenerator = false

    init(session: AppSession, selection: WeekSelection) {
        self.session = session
        self.selection = selection
        _model = State(initialValue: PlanModel(session: session))
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(selection.week.days, id: \.self) { day in
                    Section {
                        rows(for: day)
                    } header: {
                        header(for: day)
                    }
                }
            }
            .navigationTitle("Plan")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: RecipeSummary.self) { recipe in
                RecipeDetailView(session: session, summary: recipe)
            }
            .safeAreaInset(edge: .top) {
                WeekSwitcher(week: $selection.week)
            }
            .settingsToolbar(session: session)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Generate", systemImage: "wand.and.stars") {
                        showsGenerator = true
                    }
                }
            }
            .sheet(item: $draft) { draft in
                AddEntryView(session: session, draft: draft, onAdd: model.add)
            }
            .sheet(isPresented: $showsGenerator) {
                GeneratePlanView(week: selection.week, onGenerate: model.generate)
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

    @ViewBuilder
    private func rows(for day: DayDate) -> some View {
        let entries = model.entries(on: day)
        if entries.isEmpty {
            Text("Nothing planned")
                .foregroundStyle(.secondary)
        }
        ForEach(entries) { entry in
            NavigationLink(value: entry.recipe) {
                PlanEntryRow(entry: entry)
            }
            .swipeActions(edge: .trailing) {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    Task {
                        await model.delete(entry)
                    }
                }
            }
            .swipeActions(edge: .leading) {
                Button(entry.isCooked ? "Not cooked" : "Cooked", systemImage: entry.isCooked ? "arrow.uturn.backward" : "checkmark") {
                    Task {
                        await model.toggleCooked(entry)
                    }
                }
                .tint(.green)
            }
        }
    }

    private func header(for day: DayDate) -> some View {
        HStack {
            Text(verbatim: day.longText)
            Spacer()
            Button("Plan a meal", systemImage: "plus") {
                draft = PlanEntryDraft(day: day)
            }
            .labelStyle(.iconOnly)
        }
    }
}
