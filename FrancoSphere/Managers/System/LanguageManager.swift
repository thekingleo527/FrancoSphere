//
//  LanguageManager.swift
//  CyntientOps
//
//  Created by Shawn Magloire on 7/31/25.
//


import SwiftUI
import Combine

@MainActor
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: Language = .english {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "preferredLanguage")
            updateLanguage()
        }
    }
    
    enum Language: String, CaseIterable {
        case english = "en"
        case spanish = "es"
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .spanish: return "Español"
            }
        }
    }
    
    init() {
        if let saved = UserDefaults.standard.string(forKey: "preferredLanguage"),
           let language = Language(rawValue: saved) {
            self.currentLanguage = language
        } else {
            // Auto-detect based on device language
            let deviceLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            self.currentLanguage = deviceLanguage.hasPrefix("es") ? .spanish : .english
        }
    }
    
    private func updateLanguage() {
        // Force UI update
        Bundle.main.localizations.forEach { _ in
            UserDefaults.standard.set([currentLanguage.rawValue], forKey: "AppleLanguages")
        }
        
        // Show alert to restart app
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let alert = UIAlertController(
                title: NSLocalizedString("Language Changed", comment: ""),
                message: NSLocalizedString("Please restart the app for the language change to take effect", comment: ""),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    // Helper for SwiftUI views
    func localizedString(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}