import Foundation
import SwiftUI

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    struct Language: Identifiable {
        let id: String   // code: "en", "es", etc.
        let name: String // native name: "English", "Español", etc.
    }

    static let supportedLanguages: [Language] = [
        Language(id: "az", name: "Azərbaycan"),
        Language(id: "en", name: "English"),
        Language(id: "es", name: "Español"),
        Language(id: "fr", name: "Français"),
        Language(id: "it", name: "Italiano"),
        Language(id: "de", name: "Deutsch"),
        Language(id: "ru", name: "Русский"),
        Language(id: "zh-Hans", name: "简体中文"),
        Language(id: "ja", name: "日本語"),
    ]

    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "app_language")
            reloadBundle()
        }
    }

    /// Bundle pointing to the selected .lproj (or .main for "system")
    private(set) var bundle: Bundle = .main

    /// Locale matching the selected language (or .current for "system")
    var locale: Locale {
        currentLanguage == "system" ? .current : Locale(identifier: currentLanguage)
    }

    private init() {
        let stored = UserDefaults.standard.string(forKey: "app_language") ?? "system"
        self.currentLanguage = stored
        reloadBundle()
    }

    private func reloadBundle() {
        if currentLanguage == "system" {
            bundle = .main
        } else if let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
                  let b = Bundle(path: path) {
            bundle = b
        } else {
            bundle = .main
        }
    }

    /// Localized string from the currently selected language bundle.
    func string(_ key: String) -> String {
        NSLocalizedString(key, bundle: bundle, comment: "")
    }
}

/// Short helper — localized string respecting the in-app language override.
func L(_ key: String) -> String {
    LanguageManager.shared.string(key)
}
