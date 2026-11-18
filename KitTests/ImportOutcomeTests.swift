import Foundation
import Testing
@testable import MealplannerKit

/// Progress of imports, the background wait for their outcome and the notifications about it.
struct ImportOutcomeTests {
    private let credentials = Credentials(serverURL: URL(string: "https://meals.example.org")!, token: "secret")

    private func answer(status: String, stage: String? = nil, message: String? = nil, title: String? = nil) -> Data {
        let recipe = title.map { #"{"id": 3, "title": "\#($0)", "slug": "x", "tags": []}"# } ?? "null"
        let text = #"""
        {"data": {"id": 12, "url": "https://www.tiktok.com/@cook/video/1", "status": "\#(status)",
        "stage": \#(stage.map { "\"\($0)\"" } ?? "null"), "error": null,
        "error_message": \#(message.map { "\"\($0)\"" } ?? "null"),
        "created_at": "2026-11-18T02:00:00.000000Z", "recipe": \#(recipe)}}
        """#
        return Data(text.utf8)
    }

    private func item(status: String, stage: String? = nil) throws -> RecipeImport {
        try ImportEndpoints.detail(id: 12).decode(answer(status: status, stage: stage))
    }

    private func shown() -> ShownImportOutcomes {
        let suiteName = "ImportOutcomeTests-\(UUID().uuidString)"
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        return ShownImportOutcomes(suiteName: suiteName)
    }

    @Test func decodesStage() throws {
        #expect(try item(status: "processing", stage: "analyzing").stage == .analyzing)
        #expect(try item(status: "pending").stage == nil)
    }

    @Test func stepsFollowTheStage() throws {
        let analyzing = try item(status: "processing", stage: "analyzing")
        let waiting = try item(status: "pending")
        let completed = try item(status: "completed")
        let stages = RecipeImport.Stage.allCases

        #expect(stages.map { ImportProgress.state(of: $0, in: analyzing) } == [.done, .active, .upcoming])
        #expect(stages.map { ImportProgress.state(of: $0, in: waiting) } == [.active, .upcoming, .upcoming])
        #expect(stages.map { ImportProgress.state(of: $0, in: completed) } == [.done, .done, .done])
    }

    @Test func waitRequestCarriesTheToken() throws {
        let request = try ImportWaitSession.request(importID: 12, credentials: credentials)

        #expect(request.httpMethod == "GET")
        #expect(request.url?.absoluteString == "https://meals.example.org/api/v1/imports/12/wait")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer secret")
        #expect(request.timeoutInterval == 300)
    }

    @Test func appAndExtensionUseSeparateSessionsInTheSharedContainer() {
        let app = ImportWaitSession(owner: .app, bundleIdentifier: "org.example.meals", appGroup: "group.org.example.meals")
        let share = ImportWaitSession(owner: .shareExtension, bundleIdentifier: "org.example.meals", appGroup: "group.org.example.meals")

        #expect(app.identifier == "org.example.meals.import-wait.app")
        #expect(share.identifier == "org.example.meals.import-wait.shareExtension")
        #expect(share.owns(share.identifier))
        #expect(!app.owns(share.identifier))
        #expect(share.configuration.sharedContainerIdentifier == "group.org.example.meals")
        #expect(share.configuration.identifier == share.identifier)
    }

    @Test func completedImportNotifiesWithTheRecipeTitle() throws {
        let outcome = try #require(ImportOutcome(waitAnswer: answer(status: "completed", title: "Zwiebelkuchen")))
        let notice = try #require(outcome.notice)

        #expect(outcome == .imported(importID: 12, titles: ["Zwiebelkuchen"]))
        #expect(notice.body == "Zwiebelkuchen")
        #expect(notice.opensRecipe)
        #expect(ImportNotice.destination(for: notice.userInfo) == .recipe(importID: 12))
    }

    @Test func failedImportNotifiesWithTheMessageOfTheServer() throws {
        let outcome = try #require(ImportOutcome(waitAnswer: answer(status: "failed", message: "Im Video wurde kein Rezept gefunden.")))
        let notice = try #require(outcome.notice)

        #expect(outcome == .failed(importID: 12, message: "Im Video wurde kein Rezept gefunden."))
        #expect(notice.body == "Im Video wurde kein Rezept gefunden.")
        #expect(!notice.opensRecipe)
        #expect(ImportNotice.destination(for: notice.userInfo) == .imports)
    }

    @Test func failureWithoutMessageStillHasABody() throws {
        let notice = try #require(ImportOutcome.failed(importID: 12, message: nil).notice)

        #expect(!notice.body.isEmpty)
    }

    @Test func timedOutWaitIsUnfinishedAndSilent() throws {
        let outcome = try #require(ImportOutcome(waitAnswer: answer(status: "processing", stage: "downloading")))

        #expect(outcome == .unfinished(importID: 12))
        #expect(outcome.notice == nil)
        #expect(!shown().shouldNotify(about: outcome))
    }

    @Test func errorAnswersAreNoOutcome() {
        #expect(ImportOutcome(waitAnswer: Data(#"{"message": "Unauthenticated."}"#.utf8)) == nil)
        #expect(ImportNotice.destination(for: ["other": 1]) == nil)
    }

    @Test func outcomesTheExtensionShowedAreNotNotifiedAgain() {
        let shown = shown()
        let outcome = ImportOutcome.failed(importID: 12, message: "x")

        #expect(shown.shouldNotify(about: outcome))
        shown.insert(12)
        #expect(shown.contains(12))
        #expect(!shown.shouldNotify(about: outcome))
        #expect(shown.shouldNotify(about: .imported(importID: 13, titles: ["y"])))
    }

    @Test func retriedImportsNotifyAgain() {
        let shown = shown()

        shown.insert(12)
        shown.remove(12)

        #expect(shown.shouldNotify(about: .failed(importID: 12, message: nil)))
    }

    @Test func onlyRecentOutcomesAreRemembered() {
        let shown = shown()

        for importID in 1...60 {
            shown.insert(importID)
        }

        #expect(!shown.contains(10))
        #expect(shown.contains(11))
        #expect(shown.contains(60))
    }
}
