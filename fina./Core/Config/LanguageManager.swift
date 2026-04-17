import Foundation

// MARK: - LanguageBundleProxy
// Intercepta localizedString en tiempo real para cambio de idioma sin reinicio.
// Se "swizzlea" Bundle.main UNA SOLA VEZ en el arranque de la app con object_setClass.

private final class LanguageBundleProxy: Bundle, @unchecked Sendable {
    override func localizedString(
        forKey key: String,
        value: String?,
        table tableName: String?
    ) -> String {
        guard let override = LanguageManager.shared.activeBundle else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return override.localizedString(forKey: key, value: value, table: tableName)
    }
}

// MARK: - LanguageManager

final class LanguageManager {
    static let shared = LanguageManager()
    private(set) var activeBundle: Bundle?

    private init() {}

    // Llamar UNA SOLA VEZ desde FinaApp.init()
    func bootstrap() {
        object_setClass(Bundle.main, LanguageBundleProxy.self)

        // Aplica el idioma guardado (si difiere del sistema)
        if let saved = UserDefaults.standard.stringArray(forKey: "AppleLanguages")?.first {
            applyBundle(for: saved)
        }
    }

    // Cambia el idioma en tiempo real y notifica a la UI
    func setLanguage(_ code: String) {
        UserDefaults.standard.set([code], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        applyBundle(for: code)
        NotificationCenter.default.post(name: .appLanguageDidChange, object: nil)
    }

    private func applyBundle(for code: String) {
        // Busca el .lproj del idioma dentro del bundle principal
        guard let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            // Si no hay traducción para ese código, vuelve al comportamiento normal
            activeBundle = nil
            return
        }
        activeBundle = bundle
    }
}

extension Notification.Name {
    static let appLanguageDidChange = Notification.Name("fina.appLanguageDidChange")
}
