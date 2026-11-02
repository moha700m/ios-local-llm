import XCTest
@testable import IOSLocalLLM

/// Verifies the bundle-level interception that makes legacy `Text("…")` call
/// sites follow the in-app language switch. If this regresses, the app still
/// builds and runs — it just quietly falls back to English on old screens,
/// which is exactly the kind of failure a UI screenshot cannot catch.
final class LocalizationBridgeTests: XCTestCase {

    func testBundleLookupReturnsSelectedLanguage() {
        let previous = LocalizationService.shared.language
        defer { LocalizationService.shared.setLanguage(previous) }

        LocalizationService.shared.setLanguage(.arabic)
        LocalizationBridge.install()

        XCTAssertEqual(
            Bundle.main.localizedString(forKey: "Done", value: nil, table: nil),
            "تم",
            "Bundle lookup did not route through the Arabic dictionary"
        )
    }

    func testUnknownKeyFallsBackToSource() {
        LocalizationService.shared.setLanguage(.arabic)
        LocalizationBridge.install()

        let key = "A string that is not in the dictionary"
        XCTAssertEqual(
            Bundle.main.localizedString(forKey: key, value: nil, table: nil),
            key
        )
    }

    func testEnglishModeLeavesSourceUntouched() {
        let previous = LocalizationService.shared.language
        defer { LocalizationService.shared.setLanguage(previous) }

        LocalizationService.shared.setLanguage(.english)
        LocalizationBridge.install()

        XCTAssertEqual(
            Bundle.main.localizedString(forKey: "Done", value: nil, table: nil),
            "Done"
        )
    }
}
