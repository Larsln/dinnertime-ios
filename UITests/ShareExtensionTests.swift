import XCTest

/// Shares a web page from Safari to the app's share extension.
///
/// Needs the same environment as ``WalkthroughTests`` plus `MEALPLANNER_SHARE_URL`,
/// the page to share. The test is skipped when it is missing.
@MainActor
final class ShareExtensionTests: XCTestCase {
    private static let timeout: TimeInterval = 20
    private static let appName = "Mealplanner"
    private static let maximumSwipes = 4
    private static let swipeDistance: CGFloat = 180

    private let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")

    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testShareLinkFromSafari() throws {
        guard let address = ProcessInfo.processInfo.environment["MEALPLANNER_SHARE_URL"], let url = URL(string: address) else {
            throw XCTSkip("Set MEALPLANNER_SHARE_URL to run the share test.")
        }

        XCUIDevice.shared.system.open(url)
        XCTAssertTrue(safari.wait(for: .runningForeground, timeout: Self.timeout), "Safari did not open")

        openShareSheet()

        let target = shareTarget()
        scrollShareTargets(until: target)
        XCTAssertTrue(target.exists, "The share sheet does not offer the app")
        target.tap()

        record("Share offered")
        let start = safari.buttons["startImport"]
        XCTAssertTrue(start.waitForExistence(timeout: Self.timeout), "The extension does not offer to start the import")
        start.tap()

        record("Share started")
        sleep(4)
        record("Share outcome")
    }

    /// Opens the share sheet from the toolbar, or from the page menu on systems that keep it there.
    private func openShareSheet() {
        let share = safari.buttons["ShareButton"]

        if !share.waitForExistence(timeout: 5) {
            safari.buttons["PageFormatMenuButton"].firstMatch.tap()
        }

        XCTAssertTrue(share.waitForExistence(timeout: Self.timeout), "Safari shows no share button\n\(safari.debugDescription)")
        share.tap()
    }

    /// Scrolls the row of share targets until the element shows up, then falls back to the complete list.
    private func scrollShareTargets(until target: XCUIElement) {
        let anchor = safari.cells.matching(identifier: "shareCell").element(boundBy: 2)
        XCTAssertTrue(anchor.waitForExistence(timeout: Self.timeout), "The share sheet did not open")
        sleep(1)

        let start = anchor.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = start.withOffset(CGVector(dx: -Self.swipeDistance, dy: 0))

        for _ in 0..<Self.maximumSwipes where !target.exists {
            start.press(forDuration: 0.05, thenDragTo: end)
        }

        if !target.exists {
            openFullTargetList()
        }
    }

    /// Opens the complete list of share targets behind the last entry of the row.
    ///
    /// Newly installed extensions are only listed there until the user adds them to the row.
    private func openFullTargetList() {
        let entries = safari.cells.matching(identifier: "shareCell")

        entries.element(boundBy: entries.count - 1).tap()
        sleep(1)
    }

    /// The app's entry among the share targets.
    private func shareTarget() -> XCUIElement {
        let named = NSPredicate(format: "label == %@", Self.appName)

        return safari.descendants(matching: .any).matching(named).firstMatch
    }

    private func record(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
