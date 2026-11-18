import XCTest

/// Walks through the app against a real server and records a screenshot of every main screen.
///
/// The server and account come from the environment of the test runner:
/// `MEALPLANNER_SERVER`, `MEALPLANNER_USERNAME` and `MEALPLANNER_PASSWORD`.
/// With `xcodebuild` they are passed with the prefix `TEST_RUNNER_`.
/// The test is skipped when they are missing.
@MainActor
final class WalkthroughTests: XCTestCase {
    private static let tabs = ["Recipes", "Plan", "Shopping", "Pantry", "Review"]
    private static let timeout: TimeInterval = 20

    private let app = XCUIApplication()

    override func setUp() async throws {
        continueAfterFailure = false
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
    }

    func testSignInAndVisitEveryTab() throws {
        let account = try Account.fromEnvironment()

        signInIfNeeded(with: account)
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: Self.timeout), "Tab bar did not appear after sign-in")

        for tab in Self.tabs {
            app.tabBars.buttons[tab].tap()
            waitUntilLoaded()
            record(tab)
        }
    }

    func testOpenFirstRecipe() throws {
        let account = try Account.fromEnvironment()

        signInIfNeeded(with: account)
        app.tabBars.buttons["Recipes"].tap()

        let firstRecipe = app.collectionViews.cells.firstMatch
        XCTAssertTrue(firstRecipe.waitForExistence(timeout: Self.timeout), "The recipe list is empty")
        firstRecipe.staticTexts.firstMatch.tap()

        XCTAssertTrue(app.buttons["Ingredients"].waitForExistence(timeout: Self.timeout), "The recipe did not open")
        waitUntilLoaded()
        record("Recipe detail")

        app.buttons["Method"].tap()
        record("Recipe method")

        app.buttons["Actions"].tap()
        XCTAssertTrue(app.buttons["Edit"].waitForExistence(timeout: Self.timeout), "The recipe offers no editing")
        app.buttons["Edit"].tap()
        XCTAssertTrue(app.navigationBars["Edit recipe"].waitForExistence(timeout: Self.timeout), "The recipe editor did not open")
        waitUntilLoaded()
        record("Recipe editor")
        app.buttons["Cancel"].tap()
    }

    func testOpenProductEditor() throws {
        let account = try Account.fromEnvironment()

        signInIfNeeded(with: account)
        app.tabBars.buttons["Review"].tap()
        waitUntilLoaded()

        let reviewEntry = app.buttons["Edit"].firstMatch
        if reviewEntry.waitForExistence(timeout: 5) {
            reviewEntry.tap()
        } else {
            app.buttons["All products"].tap()
            let firstProduct = app.collectionViews.cells.firstMatch
            XCTAssertTrue(firstProduct.waitForExistence(timeout: Self.timeout), "The product catalog is empty")
            firstProduct.tap()
        }

        XCTAssertTrue(app.buttons["Save"].waitForExistence(timeout: Self.timeout), "The product editor did not open")
        waitUntilLoaded()
        record("Product editor")
        app.navigationBars.buttons.firstMatch.tap()
    }

    private func signInIfNeeded(with account: Account) {
        let address = app.textFields["server-address"]
        let username = app.textFields["username"]

        if address.waitForExistence(timeout: 5) {
            address.tap()
            address.typeText(account.server)
            app.buttons["Connect"].tap()
            allowLocalNetworkAccess()
            record("Server setup")
        }

        if username.waitForExistence(timeout: Self.timeout) {
            username.tap()
            username.typeText(account.username)
            app.secureTextFields["password"].tap()
            app.secureTextFields["password"].typeText(account.password)
            record("Sign in")
            app.buttons["Sign in"].tap()
        }
    }

    /// Confirms the system prompt that appears on the first request to a server in the home network.
    private func allowLocalNetworkAccess() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allow = springboard.alerts.buttons["Allow"]

        if allow.waitForExistence(timeout: 5) {
            allow.tap()
        }
    }

    private func waitUntilLoaded() {
        let spinner = app.activityIndicators.firstMatch
        let finished = NSPredicate(format: "exists == false")

        _ = XCTWaiter().wait(for: [expectation(for: finished, evaluatedWith: spinner)], timeout: Self.timeout)
    }

    private func record(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

/// Server and credentials the walkthrough signs in with.
private struct Account {
    let server: String
    let username: String
    let password: String

    /// Reads the account from the environment and skips the test when it is incomplete.
    static func fromEnvironment() throws -> Account {
        let environment = ProcessInfo.processInfo.environment

        guard
            let server = environment["MEALPLANNER_SERVER"],
            let username = environment["MEALPLANNER_USERNAME"],
            let password = environment["MEALPLANNER_PASSWORD"]
        else {
            throw XCTSkip("Set MEALPLANNER_SERVER, MEALPLANNER_USERNAME and MEALPLANNER_PASSWORD to run the walkthrough.")
        }

        return Account(server: server, username: username, password: password)
    }
}
