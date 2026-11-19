import Foundation
import Testing
@testable import DinnertimeKit

/// Writes that are applied locally, queued and delivered later.
struct OutboxTests {
    private let acted = Date(timeIntervalSince1970: 1_795_000_000)

    /// Answers every change with the given results in order and records what was sent.
    private actor Server {
        private var results: [DeliveryResult]
        private(set) var sent: [OutboxEntry] = []
        private(set) var uploads: [Data?] = []

        init(_ results: [DeliveryResult]) {
            self.results = results
        }

        func deliver(_ entry: OutboxEntry, _ upload: Data?) -> DeliveryResult {
            sent.append(entry)
            uploads.append(upload)
            return results.isEmpty ? .response(status: 200, body: Data("{}".utf8)) : results.removeFirst()
        }
    }

    private func drain(_ store: OfflineStore, _ server: Server) async -> DrainReport {
        await store.drain { entry, upload in
            await server.deliver(entry, upload)
        }
    }

    private func body(_ entry: OutboxEntry) throws -> [String: Any] {
        let data = try #require(entry.body)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    @Test func aWriteShowsAtOnceAndIsQueuedWithKeyAndTime() async throws {
        let store = try await OfflineSupport.syncedStore()
        let answer = try #require(await store.answer(ShoppingEndpoints.setChecked(true, itemID: 39), now: acted))
        let entry = try #require(await store.pendingChanges.first)
        let list = try #require(await store.answer(ShoppingEndpoints.current)).response

        #expect(answer.response.isChecked)
        #expect(answer.areas == [.shopping])
        #expect(answer.shoppingChange == entry)
        #expect(list.items.first { $0.id == 39 }?.isChecked == true)
        #expect(entry.method == .patch)
        #expect(entry.path == "shopping-list-items/39")
        #expect(entry.clientTime == acted)
        #expect(UUID(uuidString: entry.key) != nil)
        #expect(try body(entry)["checked"] as? Bool == true)
    }

    @Test func queuedChangesSurviveARestartInOrder() async throws {
        let directory = OfflineSupport.directory()
        let store = try await OfflineSupport.syncedStore(in: directory)
        _ = try await store.answer(ShoppingEndpoints.setChecked(true, itemID: 39))
        _ = try await store.answer(PantryEndpoints.setAmount(7, id: 16))
        _ = try await store.answer(MealPlanEndpoints.delete(id: 21))
        let reopened = OfflineStore(directory: directory)

        #expect(await reopened.pendingChanges.map(\.path) == ["shopping-list-items/39", "pantry/16", "meal-plan/21"])
        #expect(try #require(await reopened.answer(PantryEndpoints.list)).response.first { $0.id == 16 }?.amount == 7)
    }

    @Test func requestCarriesKeyClientTimeAndBody() throws {
        let entry = OutboxEntry(key: "k-1", clientTime: acted, method: .patch, path: "pantry/16", body: Data(#"{"amount":7}"#.utf8), upload: nil, created: [], createdKind: nil, isShoppingChange: false)
        let request = entry.urlRequest(serverURL: try #require(URL(string: "https://meals.example.org")), token: "secret")

        #expect(request.url?.absoluteString == "https://meals.example.org/api/v1/pantry/16")
        #expect(request.httpMethod == "PATCH")
        #expect(request.value(forHTTPHeaderField: "Idempotency-Key") == "k-1")
        #expect(request.value(forHTTPHeaderField: "X-Client-Time") == "2026-11-18T11:06:40.000Z")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer secret")
        #expect(request.httpBody == Data(#"{"amount":7}"#.utf8))
    }

    @Test(arguments: [
        (200, #"{"data":{}}"#, OutboxOutcome.delivered(body: Data(#"{"data":{}}"#.utf8))),
        (204, "", OutboxOutcome.delivered(body: Data())),
        (409, #"{"message":"Newer change","code":"stale"}"#, OutboxOutcome.dropped),
        (404, #"{"message":"Not found"}"#, OutboxOutcome.dropped),
        (409, #"{"message":"In use"}"#, OutboxOutcome.rejected(message: "In use")),
        (422, #"{"message":"The title is required.","errors":{}}"#, OutboxOutcome.rejected(message: "The title is required.")),
        (500, "", OutboxOutcome.retry),
        (503, "", OutboxOutcome.retry),
        (401, "", OutboxOutcome.retry),
        (429, "", OutboxOutcome.retry),
    ])
    func classifiesAnswers(status: Int, body: String, expected: OutboxOutcome) {
        #expect(OutboxOutcome(.response(status: status, body: Data(body.utf8))) == expected)
    }

    @Test func noAnswerKeepsTheChange() {
        #expect(OutboxOutcome(.unreachable) == .retry)
    }

    @Test func drainsInOrderAndStopsAtTheFirstThatHasToWait() async throws {
        let store = try await OfflineSupport.syncedStore()
        _ = try await store.answer(ShoppingEndpoints.setChecked(true, itemID: 39))
        _ = try await store.answer(PantryEndpoints.setAmount(7, id: 16))
        _ = try await store.answer(MealPlanEndpoints.delete(id: 21))
        let server = Server([.response(status: 200, body: Data("{}".utf8)), .unreachable])
        let report = await drain(store, server)

        #expect(report.delivered == 1)
        #expect(report.needsRetry)
        #expect(await server.sent.map(\.path) == ["shopping-list-items/39", "pantry/16"])
        #expect(await store.pendingChanges.map(\.path) == ["pantry/16", "meal-plan/21"])

        let later = await drain(store, Server([]))

        #expect(later == DrainReport(delivered: 2, rejections: [], needsRetry: false, areas: []))
        #expect(await store.pendingCount == 0)
    }

    @Test func serverErrorsKeepTheChange() async throws {
        let store = try await OfflineSupport.syncedStore()
        _ = try await store.answer(PantryEndpoints.setAmount(7, id: 16))
        let report = await drain(store, Server([.response(status: 502, body: Data())]))

        #expect(report.needsRetry)
        #expect(await store.pendingCount == 1)
        #expect(await store.syncVersion == 126)
    }

    @Test func staleAndMissingChangesAreDroppedAndOnlyWhatTheyTouchedIsReadAgain() async throws {
        let store = try await OfflineSupport.syncedStore()
        _ = try await store.answer(PantryEndpoints.setAmount(7, id: 16))
        _ = try await store.answer(MealPlanEndpoints.delete(id: 21))
        _ = try await store.answer(ShoppingEndpoints.setChecked(true, itemID: 39))
        let stale = DeliveryResult.response(status: 409, body: Data(#"{"message":"x","code":"stale"}"#.utf8))
        let report = await drain(store, Server([stale, .response(status: 404, body: Data())]))

        #expect(report.delivered == 1)
        #expect(report.rejections.isEmpty)
        #expect(!report.needsRetry)
        #expect(await store.pendingCount == 0)
        #expect(await store.syncVersion == 126)
        #expect(await store.pendingRepairs == [.kind(.pantryItems), .kind(.mealPlanEntries)])
    }

    @Test func aKindIsReplacedByTheAnswerForThatKindWithoutMovingTheVersion() async throws {
        let directory = OfflineSupport.directory()
        let store = try await OfflineSupport.syncedStore(in: directory)
        _ = try await store.answer(PantryEndpoints.setAmount(7, id: 16))
        _ = await drain(store, Server([.response(status: 409, body: Data(#"{"code":"stale"}"#.utf8))]))
        let waiting = try #require(await store.answer(PantryEndpoints.create(productID: 95, amount: 1, openedOn: nil, expiresOn: nil))).response
        let kept: [String: Any] = ["id": 16, "amount": 4, "opened_on": NSNull(), "expires_on": NSNull(), "product": ["id": 77, "name": "Koriander", "base_unit": "piece", "status": "confirmed"]]
        let first = try OfflineSupport.page(version: 400, hasMore: true, changed: ["pantry_items": [kept]])
        let second = try OfflineSupport.page(version: 900, changed: ["pantry_items": []])
        let areas = try await store.finish(.kind(.pantryItems), withPages: [first, second])
        let pantry = try #require(await OfflineStore(directory: directory).answer(PantryEndpoints.list)).response

        #expect(areas == [.pantry])
        #expect(pantry.map(\.id).sorted() == [waiting.id, 16])
        #expect(pantry.first { $0.id == 16 }?.amount == 4)
        #expect(await store.syncVersion == 126)
        #expect(await store.pendingRepairs.isEmpty)
        #expect(try #require(await store.answer(RecipeEndpoints.list())).response.total == 4)
    }

    @Test func aRefusedRecipeChangeReadsOnlyThatRecipeAgain() async throws {
        let store = try await OfflineSupport.syncedStore()
        _ = try await store.answer(RecipeEndpoints.update(id: 95, RecipeInput(title: "")))
        let refusal = DeliveryResult.response(status: 422, body: Data(#"{"message":"The title is required."}"#.utf8))
        let report = await drain(store, Server([refusal]))
        let repair = RecordRepair.record(kind: .recipes, id: 95)

        #expect(report.rejections == ["The title is required."])
        #expect(await store.pendingRepairs == [repair])
        #expect(repair.detailPath == "recipes/95")
        #expect(RecordRepair.kind(.tools).detailPath == nil)

        let answer = try JSONSerialization.data(withJSONObject: ["data": OfflineSupport.recipe(id: 95, title: "Crispy Chicken Tacos")])
        _ = try await store.finish(repair, withRecord: answer)

        #expect(try #require(await store.answer(RecipeEndpoints.detail(id: 95))).response.summary.title == "Crispy Chicken Tacos")
        #expect(await store.pendingRepairs.isEmpty)
        #expect(await store.syncVersion == 126)
    }

    @Test func aRecordTheServerNoLongerHasIsRemoved() async throws {
        let store = try await OfflineSupport.syncedStore()
        let input = ProductInput(name: "Käse", icon: nil, storeSectionID: nil, baseUnit: .gram, isPantryStaple: false, shelfLifeOpenedDays: nil)
        _ = try await store.answer(ProductEndpoints.update(id: 94, input))
        _ = await drain(store, Server([.response(status: 404, body: Data())]))

        #expect(await store.pendingRepairs == [.record(kind: .products, id: 94)])

        _ = try await store.finish(.record(kind: .products, id: 94), withRecord: nil)

        await #expect(throws: APIError.server(status: 404, message: nil)) {
            _ = try await store.answer(ProductEndpoints.detail(id: 94))
        }
        #expect(await store.pendingRepairs.isEmpty)
    }

    @Test func whatARefusedCreationMadeIsRemovedWithoutARepair() async throws {
        let store = try await OfflineSupport.syncedStore()
        let created = try #require(await store.answer(RecipeEndpoints.create(RecipeInput(title: "")))).response
        let report = await drain(store, Server([.response(status: 422, body: Data(#"{"message":"The title is required."}"#.utf8))]))

        #expect(created.id < 0)
        #expect(report.rejections == ["The title is required."])
        #expect(try #require(await store.answer(RecipeEndpoints.list())).response.total == 4)
        #expect(await store.pendingRepairs.isEmpty)
        #expect(await store.syncVersion == 126)
    }

    @Test func repairsNameWhatAChangeTouched() async throws {
        let store = try await OfflineSupport.syncedStore()
        _ = try await store.answer(RecipeEndpoints.delete(id: 98))
        _ = try await store.answer(ProductValueEndpoints.deletePackage(id: 91))
        _ = try await store.answer(ToolEndpoints.rename(id: 21, to: "Bratpfanne"))
        _ = try await store.answer(ShoppingEndpoints.addItem(label: "Kerzen", listID: 11))
        _ = try await store.answer(HouseholdSettingsEndpoints.setDefaultServings(3))
        let repairs = await store.pendingChanges.map { $0.repairs ?? [] }

        #expect(repairs == [
            [.record(kind: .recipes, id: 98), .kind(.mealPlanEntries)],
            [.record(kind: .products, id: 94)],
            [.kind(.tools)],
            [.kind(.shoppingLists)],
            [],
        ])
    }

    @Test func repairsOfRecordsCreatedOfflineFollowTheRealId() async throws {
        let store = try await OfflineSupport.syncedStore()
        let recipe = try #require(await store.answer(RecipeEndpoints.create(RecipeInput(title: "Offline-Kuchen")))).response
        _ = try await store.answer(RecipeMarkEndpoints.rate(8, id: recipe.id))
        let server = Server([OfflineSupport.created(id: 700), .response(status: 422, body: Data(#"{"message":"no"}"#.utf8))])
        _ = await drain(store, server)

        #expect(await store.pendingRepairs == [.record(kind: .recipes, id: 700)])
    }

    @Test func kindRequestsNameTheKindAndKeepPaging() throws {
        let builder = RequestBuilder(baseURL: ServerAddress.apiBaseURL(for: try #require(URL(string: "https://meals.example.org"))), token: "t", languages: ["en"])
        let request = try builder.request(for: SyncEndpoints.records(of: .mealPlanEntries, since: 40))
        let items = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)?.queryItems
        let position = try SyncPosition(page: OfflineSupport.page(version: 12, hasMore: true))

        #expect(items == [
            URLQueryItem(name: "since", value: "40"),
            URLQueryItem(name: "limit", value: "200"),
            URLQueryItem(name: "kinds[]", value: "meal_plan_entries"),
        ])
        #expect(position == SyncPosition(version: 12, hasMore: true))
        #expect(try builder.request(for: SyncEndpoints.record(at: "recipes/95")).url?.path() == "/api/v1/recipes/95")
    }

    @Test func recordsCreatedOfflineGetTheirRealIdInLaterChanges() async throws {
        let store = try await OfflineSupport.syncedStore()
        let recipe = try #require(await store.answer(RecipeEndpoints.create(RecipeInput(title: "Offline-Kuchen", servings: 4)))).response
        let day = DayDate(year: 2026, month: 11, day: 22)
        let entry = try #require(await store.answer(MealPlanEndpoints.create(date: day, meal: .dinner, recipeID: recipe.id, servings: 2))).response
        _ = try await store.answer(MealPlanEndpoints.setCooked(true, id: entry.id))
        _ = try await store.answer(RecipeMarkEndpoints.rate(8, id: recipe.id))
        let server = Server([
            OfflineSupport.created(id: 700, extra: OfflineSupport.recipe(id: 700, title: "Offline-Kuchen")),
            OfflineSupport.created(id: 800),
        ])
        let report = await drain(store, server)
        let sent = await server.sent
        let planned = try #require(await store.answer(MealPlanEndpoints.entries(from: day, to: day))).response

        #expect(recipe.id < 0 && entry.id < 0 && recipe.id != entry.id)
        #expect(report.delivered == 4)
        #expect(sent.map(\.path) == ["recipes", "meal-plan", "meal-plan/800", "recipes/700/rating"])
        #expect(try body(sent[1])["recipe_id"] as? Int == 700)
        #expect(planned.map(\.id) == [800])
        #expect(planned.first?.recipe.id == 700)
        #expect(planned.first?.isCooked == true)
        #expect(try #require(await store.answer(RecipeEndpoints.detail(id: 700))).response.summary.rating == 8)
    }

    @Test func batchCreationsMapAnswersToTemporaryIdsInOrder() async throws {
        let store = try await OfflineSupport.syncedStore()
        let day = DayDate(year: 2026, month: 11, day: 23)
        let entries = [
            MealPlanBatchEntry(date: day, meal: .lunch, recipeID: 95, servings: 2),
            MealPlanBatchEntry(date: day, meal: .dinner, recipeID: 96, servings: 2),
        ]
        let created = try #require(await store.answer(MealPlanEndpoints.save(entries))).response
        _ = try await store.answer(MealPlanEndpoints.delete(id: created[1].id))
        let answer = try JSONSerialization.data(withJSONObject: ["data": [["id": 901], ["id": 902]]])
        let server = Server([.response(status: 201, body: answer)])
        _ = await drain(store, server)

        #expect(await server.sent.map(\.path) == ["meal-plan/batch", "meal-plan/902"])
        #expect(try #require(await store.answer(MealPlanEndpoints.entries(from: day, to: day))).response.map(\.id) == [901])
    }

    @Test func aCoverChosenOfflineIsKeptAndUploadedLater() async throws {
        let directory = OfflineSupport.directory()
        let store = try await OfflineSupport.syncedStore(in: directory)
        let image = Data([0xFF, 0xD8, 0xFF, 0xD9])
        let recipe = try #require(await store.answer(RecipeEndpoints.uploadCover(id: 98, jpeg: image))).response
        let cover = try #require(recipe.summary.coverURL)
        let reopened = OfflineStore(directory: directory)
        let entry = try #require(await reopened.pendingChanges.first)
        let server = Server([])
        _ = await drain(reopened, server)

        #expect(PendingCover.isPending(cover))
        #expect(entry.body == nil)
        #expect(entry.upload == OutboxEntry.Upload(field: "image", fileName: "cover.jpg", mimeType: "image/jpeg"))
        #expect(await server.uploads == [image])
        #expect(await reopened.upload(forKey: entry.key) == nil)

        let request = entry.urlRequest(serverURL: try #require(URL(string: "https://meals.example.org")), token: "t", upload: image)

        #expect(request.value(forHTTPHeaderField: "Content-Type")?.hasPrefix("multipart/form-data") == true)
        #expect(request.httpBody?.range(of: image) != nil)
    }
}
