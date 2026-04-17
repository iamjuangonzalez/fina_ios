import SwiftUI

// MARK: - Color scheme modifier
private struct FinaColorSchemeModifier: ViewModifier {
    @AppStorage("appColorScheme") private var stored: String = "system"

    private var scheme: ColorScheme? {
        switch stored {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    func body(content: Content) -> some View {
        content.preferredColorScheme(scheme)
    }
}

// MARK: - Paleta achromática (espeja los tokens del sistema fina.)
// Light mode: blanco/negro. Dark mode: invertido.
extension Color {

    // Fondos
    static let finaBackground        = Color("Background")
    static let finaCard              = Color("Card")

    // Texto
    static let finaForeground        = Color("Foreground")
    static let finaMutedForeground   = Color("MutedForeground")

    // Superficies
    static let finaMuted             = Color("Muted")
    static let finaBorder            = Color("Border")

    // Acciones
    static let finaPrimary           = Color("Primary")
    static let finaPrimaryForeground = Color("PrimaryForeground")
    static let finaDestructive       = Color("Destructive")

    // Semánticos de ahorro / salud financiera
    static let finaSavingsGood    = Color(red: 0.063, green: 0.725, blue: 0.506)
    static let finaSavingsWarning = Color(red: 0.976, green: 0.451, blue: 0.086)
    static let finaSavingsBad     = Color(red: 0.937, green: 0.267, blue: 0.267)
}

// MARK: - Extensiones de View
extension View {
    /// Aplica el tema guardado en AppStorage a cualquier sheet/modal.
    /// Úsalo en el contenido de cada .sheet { } para que herede el tema.
    func finaColorScheme() -> some View {
        modifier(FinaColorSchemeModifier())
    }

    func finaCard() -> some View {
        self
            .background(Color.finaCard)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.finaBorder, lineWidth: 1)
            )
    }
}
