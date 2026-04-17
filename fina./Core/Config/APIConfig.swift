import Foundation

// MARK: - APIConfig
// ⚠️  En producción mover las claves a un backend proxy.
//     Nunca commitear claves reales en un repo público.

enum APIConfig {

    // Anthropic — Claude Haiku (sugerencia de categorías)
    // Obtén tu key en: https://console.anthropic.com
    static let anthropicKey: String = {
        // 1. Variable de entorno (CI / Xcode scheme) — preferida
        if let env = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"],
           !env.isEmpty { return env }
        // 2. Fallback: clave hardcodeada — reemplaza con tu key de console.anthropic.com
        return "TU_ANTHROPIC_API_KEY_AQUI"
    }()

    static var hasAnthropicKey: Bool {
        !anthropicKey.isEmpty && !anthropicKey.hasPrefix("TU_")
    }
}
