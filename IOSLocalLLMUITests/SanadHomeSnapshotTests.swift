import XCTest

/// Visual smoke tests for the Sanad shell. They do not assert pixels: they
/// launch the app in a fixed state, wait for the custom tab bar, and attach a
/// full-screen screenshot to the result bundle. CI exports those attachments
/// so a redesign can be reviewed without a Mac.
final class SanadHomeSnapshotTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch(language: String, appearance: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-UITesting",
            // Satisfy every first-run gate so the screenshot is the product,
            // not a consent sheet.
            "-legalAcceptedVersion", "999",
            "-aiDisclaimerAccepted", "YES",
            "-deviceSafetyAccepted", "YES",
            "-hasSeenOnboarding", "YES",
            "-uiLanguage", language,
            "-appearance", appearance
        ]
        app.launch()
        return app
    }

    private func captureHome(_ app: XCUIApplication,
                             homeLabel: String,
                             name: String) {
        let home = app.buttons[homeLabel]
        XCTAssertTrue(home.waitForExistence(timeout: 60), "Custom tab bar did not appear")
        // Let the splash hand off and the hero card settle.
        Thread.sleep(forTimeInterval: 3.0)

        XCTAssertTrue(home.isHittable, "Home tab is not tappable")

        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testHomeArabicLight() {
        let app = launch(language: "ar", appearance: "light")
        captureHome(app, homeLabel: "الرئيسية", name: "home-ar-light")
    }

    func testHomeArabicDark() {
        let app = launch(language: "ar", appearance: "dark")
        captureHome(app, homeLabel: "الرئيسية", name: "home-ar-dark")
    }

    func testHomeEnglishDark() {
        let app = launch(language: "en", appearance: "dark")
        captureHome(app, homeLabel: "Home", name: "home-en-dark")
    }
}
