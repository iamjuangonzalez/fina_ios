import SwiftUI
import AppIntents
import SwiftData

// Datos pre-cargados que llegan desde un Intent o URL scheme
struct TransactionPrefill: Identifiable {
    let id = UUID()
    let amount: Double
    let merchant: String
}

@main
struct FinaApp: App {
    @State private var auth = AuthManager()
    @State private var txPrefill: TransactionPrefill? = nil
    @State private var languageID = UUID()           // fuerza re-render al cambiar idioma
    @AppStorage("appColorScheme") private var storedScheme: String = "system"

    init() {
        // Instala el Bundle proxy para cambio de idioma sin reinicio
        LanguageManager.shared.bootstrap()
        // Registra categorías de notificaciones locales
        FinaNotifications.registerCategories()
    }

    private var preferredScheme: ColorScheme? {
        switch storedScheme {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(txPrefill: $txPrefill)
                .id(languageID)                      // recrea toda la UI al cambiar idioma
                .environment(auth)
                .modelContainer(FinaDatabase.container)
                .preferredColorScheme(preferredScheme)
                .onOpenURL { url in handleURL(url) }
                .onReceive(NotificationCenter.default.publisher(
                    for: UIApplication.willEnterForegroundNotification)) { _ in
                    checkIntentPrefill()
                }
                .onReceive(NotificationCenter.default.publisher(
                    for: .appLanguageDidChange)) { _ in
                    languageID = UUID()               // dispara la re-renderización
                }
        }
    }

    // MARK: - URL scheme handler
    private func handleURL(_ url: URL) {
        guard
            url.scheme == "fina",
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let params = components.queryItems
        else { return }

        let amountStr = params.first(where: { $0.name == "amount" })?.value ?? ""
        let merchant  = params.first(where: { $0.name == "merchant" })?.value ?? ""

        if let amount = Double(amountStr), !merchant.isEmpty {
            txPrefill = TransactionPrefill(amount: amount, merchant: merchant)
        }
    }

    // MARK: - App Intent prefill (NewTransactionIntent / TransactionFromMessageIntent)
    private func checkIntentPrefill() {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: "intent_prefill_pending") else { return }

        let amount   = defaults.double(forKey: "intent_prefill_amount")
        let merchant = defaults.string(forKey: "intent_prefill_merchant") ?? ""

        if amount > 0 || !merchant.isEmpty {
            txPrefill = TransactionPrefill(amount: amount, merchant: merchant)
        }

        // Limpiar para no volver a leerlos
        defaults.removeObject(forKey: "intent_prefill_pending")
        defaults.removeObject(forKey: "intent_prefill_amount")
        defaults.removeObject(forKey: "intent_prefill_merchant")
    }
}
