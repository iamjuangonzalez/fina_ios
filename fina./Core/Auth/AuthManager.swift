import Supabase
import SwiftUI

@MainActor
@Observable
final class AuthManager {

    var session:                   Session?
    var isInitializing           = true   // true hasta que Supabase responde por primera vez
    var isLoading                = false
    var errorMessage:              String?
    var signUpNeedsConfirmation  = false
    var signUpConfirmationEmail  = ""

    var isAuthenticated: Bool { session != nil }
    var userId: String?    { session?.user.id.uuidString }
    var displayName: String {
        let meta = session?.user.userMetadata
        if let name = meta?["full_name"]?.stringValue { return name }
        return session?.user.email ?? ""
    }
    var avatarUrl: String? { session?.user.userMetadata["avatar_url"]?.stringValue }
    var initials: String {
        let parts = displayName.trimmingCharacters(in: .whitespaces).split(separator: " ")
        if parts.count >= 2 {
            return (String(parts[0].prefix(1)) + String(parts[1].prefix(1))).uppercased()
        }
        return String(displayName.prefix(2)).uppercased()
    }

    init() {
        Task { await listenToAuthChanges() }
    }

    // MARK: - Auth state
    private func listenToAuthChanges() async {
        for await (_, session) in await supabase.auth.authStateChanges {
            self.session       = session
            self.isInitializing = false   // primera respuesta recibida — ya sabemos el estado
            UserDefaults.standard.set(session?.user.id.uuidString, forKey: "fina_user_id")
        }
    }

    // MARK: - Login
    func signIn(email: String, password: String) async {
        isLoading    = true
        errorMessage = nil
        do {
            try await supabase.auth.signIn(email: email, password: password)
        } catch {
            errorMessage = mapError(error, context: .signIn)
        }
        isLoading = false
    }

    // MARK: - Registro
    func signUp(email: String, password: String, name: String) async {
        isLoading                 = true
        errorMessage              = nil
        signUpNeedsConfirmation   = false
        do {
            let response = try await supabase.auth.signUp(
                email:    email,
                password: password,
                data:     ["full_name": AnyJSON(stringLiteral: name)]
            )
            // Si session == nil Supabase requiere confirmación de email
            if response.session == nil {
                signUpConfirmationEmail = email
                signUpNeedsConfirmation = true
            }
            // Si session != nil el auth state listener lo maneja automáticamente
        } catch {
            errorMessage = mapError(error, context: .signUp)
        }
        isLoading = false
    }

    // MARK: - Reenviar confirmación
    func resendConfirmation(email: String) async {
        try? await supabase.auth.resend(email: email, type: .signup)
    }

    // MARK: - Logout
    func signOut() async {
        try? await supabase.auth.signOut()
        session                  = nil
        signUpNeedsConfirmation  = false
        signUpConfirmationEmail  = ""
    }

    func clearError() {
        errorMessage = nil
    }

    func resetSignUp() {
        signUpNeedsConfirmation = false
        signUpConfirmationEmail = ""
        errorMessage            = nil
    }

    // MARK: - Error mapping
    private enum AuthContext { case signIn, signUp }

    private func mapError(_ error: Error, context: AuthContext) -> String {
        let msg = error.localizedDescription.lowercased()

        if msg.contains("invalid login") || msg.contains("invalid credentials") || msg.contains("invalid_credentials") {
            return "Correo o contraseña incorrectos."
        }
        if msg.contains("not confirmed") || msg.contains("email_not_confirmed") {
            return "Confirma tu correo antes de iniciar sesión."
        }
        if msg.contains("too many") || msg.contains("rate limit") {
            return "Demasiados intentos. Espera unos minutos."
        }
        if msg.contains("network") || msg.contains("connection") || msg.contains("offline") {
            return "Sin conexión. Verifica tu internet."
        }
        if context == .signUp {
            if msg.contains("already") || msg.contains("exists") || msg.contains("already_registered") {
                return "Ya existe una cuenta con ese correo."
            }
            if msg.contains("weak") || msg.contains("password") {
                return "La contraseña es muy débil. Usa al menos 6 caracteres."
            }
        }
        return "Ocurrió un error inesperado. Intenta de nuevo."
    }
}
