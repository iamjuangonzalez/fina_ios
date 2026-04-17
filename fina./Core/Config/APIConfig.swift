import Foundation

// MARK: - APIConfig
// ⚠️  En producción mover las claves a un backend proxy.
//     Nunca commitear claves reales en un repo público.

enum APIConfig {

    // Anthropic — Claude Haiku (sugerencia de categorías)
    // Obtén tu key en: https://console.anthropic.com
    static let anthropicKey: String = {
        if let env = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"],
           !env.isEmpty { return env }
        return Secrets.anthropicAPIKey
    }()

    static var hasAnthropicKey: Bool {
        !anthropicKey.isEmpty && !anthropicKey.hasPrefix("TU_")
    }
}
