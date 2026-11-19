import XCTest

/// Walks through the app against a real server and records a screenshot of every main screen.
///
/// The server and account come from the environment of the test runner:
/// `DINNERTIME_SERVER`, `DINNERTIME_USERNAME` and `DINNERTIME_PASSWORD`.
/// With `xcodebuild` they are passed with the prefix `TEST_RUNNER_`.
/// The test is skipped when they are missing.
@MainActor
final class WalkthroughTests: XCTestCase {
    private static let tabs = ["Recipes", "Plan", "Shopping", "Pantry", "Products"]
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

        XCTAssertTrue(app.collectionViews.cells.firstMatch.waitForExistence(timeout: Self.timeout), "The recipe list is empty")
        waitUntilLoaded()
        let firstRecipe = try XCTUnwrap(
            app.collectionViews.cells.allElementsBoundByIndex.first { $0.frame.height > 60 && $0.isHittable },
            "The recipe list shows no recipe"
        )
        firstRecipe.tap()

        let ingredients = app.buttons["Ingredients"]
        for _ in 0..<4 where !ingredients.waitForExistence(timeout: 3) {
            app.swipeUp()
        }
        XCTAssertTrue(ingredients.exists, "The recipe did not open")
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

    func testOpenImports() throws {
        let account = try Account.fromEnvironment()

        signInIfNeeded(with: account)
        app.tabBars.buttons["Recipes"].tap()
        app.buttons["Import"].firstMatch.tap()

        XCTAssertTrue(app.textFields.firstMatch.waitForExistence(timeout: Self.timeout), "The import screen did not open")
        waitUntilLoaded()
        record("Imports")
        app.buttons["Done"].tap()
    }

    func testSwitchProductLists() throws {
        let account = try Account.fromEnvironment()

        signInIfNeeded(with: account)
        app.tabBars.buttons["Products"].tap()

        for list in ["All", "Tools", "Stores"] {
            app.buttons[list].tap()
            XCTAssertTrue(app.textFields.firstMatch.waitForExistence(timeout: Self.timeout), "\(list) cannot be searched")
            waitUntilLoaded()
            record(list)
        }
    }

    func testOpenShoppingItemDetails() throws {
        let account = try Account.fromEnvironment()

        signInIfNeeded(with: account)
        app.tabBars.buttons["Shopping"].tap()
        waitUntilLoaded()

        let tile = app.scrollViews.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Käse")).firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: Self.timeout), "The shopping list has no tile to press")
        app.swipeUp()
        app.swipeDown()
        XCTAssertTrue(tile.isHittable, "Scrolling the list moved or checked the tile")
        tile.press(forDuration: 0.4)
        sleep(1)
        record("Shopping item details")

        let note = app.staticTexts["Note"]
        for _ in 0..<4 where !note.exists {
            app.swipeUp()
        }
        XCTAssertTrue(note.waitForExistence(timeout: Self.timeout), "The details offer no note")

        guard let shop = ProcessInfo.processInfo.environment["DINNERTIME_TEST_SHOP"] else {
            return
        }
        let newShop = app.buttons["New shop"].firstMatch
        if newShop.waitForExistence(timeout: 2) {
            newShop.tap()
        }
        app.textFields["Shop"].tap()
        app.typeText("\(shop)\n150")
        let price = app.textFields.matching(NSPredicate(format: "placeholderValue == %@", "Price")).firstMatch
        sleep(2)
        price.tap()
        price.typeText("1.99")
        app.buttons.matching(NSPredicate(format: "label == %@", "Add")).allElementsBoundByIndex.last?.tap()

        let line = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "\(shop) ·")).firstMatch
        XCTAssertTrue(line.waitForExistence(timeout: Self.timeout), "The offer was not added")
        record("Offer added")
    }

    func testOpenProductEditor() throws {
        let account = try Account.fromEnvironment()

        signInIfNeeded(with: account)
        app.tabBars.buttons["Products"].tap()
        waitUntilLoaded()

        let reviewEntry = app.buttons["Edit"].firstMatch
        if reviewEntry.waitForExistence(timeout: 5) {
            reviewEntry.tap()
        } else {
            app.buttons["All"].tap()
            let firstProduct = app.collectionViews.cells.firstMatch
            XCTAssertTrue(firstProduct.waitForExistence(timeout: Self.timeout), "The product catalog is empty")
            firstProduct.tap()
        }

        XCTAssertTrue(app.buttons["Save"].waitForExistence(timeout: Self.timeout), "The product editor did not open")
        waitUntilLoaded()
        record("Product editor")

        let everywhere = app.buttons["Everywhere"].firstMatch
        for _ in 0..<4 where !everywhere.exists {
            app.swipeUp()
        }
        XCTAssertTrue(everywhere.waitForExistence(timeout: Self.timeout), "The editor offers no entry for package sizes")
        XCTAssertTrue(app.buttons["Add"].firstMatch.exists, "The entry for package sizes has no button to add one")
        let size = app.textFields.matching(NSPredicate(format: "placeholderValue == %@", "Size")).firstMatch
        size.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: Self.timeout), "The number pad did not open")
        record("Package size")
        app.toolbars.buttons["Done"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: Self.timeout), "The number pad cannot be closed")
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
            let server = environment["DINNERTIME_SERVER"],
            let username = environment["DINNERTIME_USERNAME"],
            let password = environment["DINNERTIME_PASSWORD"]
        else {
            throw XCTSkip("Set DINNERTIME_SERVER, DINNERTIME_USERNAME and DINNERTIME_PASSWORD to run the walkthrough.")
        }

        return Account(server: server, username: username, password: password)
    }
}
