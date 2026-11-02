import Foundation

// MARK: - LocalizationBridge
//
// The app ships two kinds of strings:
//   1. New surfaces call `loc.t("…")` directly.
//   2. Legacy surfaces use SwiftUI's `Text("…")`, which resolves through
//      `Bundle.main.localizedString(forKey:value:table:)`.
//
// To make the *whole* app follow the in-app language switch — not just the
// screens written after the redesign — the bundle lookup is intercepted once at
// launch and answered from the same in-process dictionary. Unknown keys fall
// through to the original implementation, so a missing translation can only
// ever render the English source, never an empty string.
//
// This is deliberately narrow: only `Bundle.main`, only table-less lookups, and
// only keys that actually have a translation. Framework bundles are untouched.

enum LocalizationBridge {
    private static var installed = false

    static func install() {
        guard !installed else { return }
        installed = true

        swizzle(
            original: NSSelectorFromString("localizedStringForKey:value:table:"),
            replacement: #selector(Bundle.sanad_localizedString(forKey:value:table:))
        )
        // iOS 16+ variant used by string catalogs. Present on the runtime in
        // every supported OS; if it is ever absent the lookup simply returns
        // nil and we keep the three-argument path.
        swizzle(
            original: NSSelectorFromString("localizedStringForKey:value:table:localizations:"),
            replacement: #selector(Bundle.sanad_localizedString(forKey:value:table:localizations:))
        )
    }

    private static func swizzle(original: Selector, replacement: Selector) {
        guard let originalMethod = class_getInstanceMethod(Bundle.self, original),
              let replacementMethod = class_getInstanceMethod(Bundle.self, replacement)
        else { return }
        method_exchangeImplementations(originalMethod, replacementMethod)
    }
}

extension Bundle {
    @objc func sanad_localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if self == Bundle.main, tableName == nil,
           let translated = LocalizationService.shared.translationIfAvailable(key) {
            return translated
        }
        // After the exchange this call reaches the original implementation.
        return sanad_localizedString(forKey: key, value: value, table: tableName)
    }

    @objc func sanad_localizedString(forKey key: String,
                                     value: String?,
                                     table tableName: String?,
                                     localizations: [String]?) -> String {
        if self == Bundle.main, tableName == nil,
           let translated = LocalizationService.shared.translationIfAvailable(key) {
            return translated
        }
        return sanad_localizedString(forKey: key,
                                     value: value,
                                     table: tableName,
                                     localizations: localizations)
    }
}
