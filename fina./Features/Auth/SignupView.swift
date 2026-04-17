import SwiftUI

struct SignupView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss)        private var dismiss

    @State private var name       = ""
    @State private var email      = ""
    @State private var password   = ""
    @State private var localError = ""

    var body: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    VStack(spacing: 32) {

                        if auth.signUpNeedsConfirmation {
                            confirmationCard
                        } else {
                            formCard
                        }

                        // Footer
                        Group {
                            Text("Al continuar, aceptas nuestros ")
                            + Text("Términos").underline()
                            + Text(" y ")
                            + Text("Política de Privacidad").underline()
                        }
                        .font(.poppins(.regular, size: 12))
                        .foregroundStyle(Color.finaMutedForeground)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    }

                    Spacer(minLength: 0)
                }
                .frame(minHeight: geo.size.height)
                .padding(.vertical, 24)
            }
        }
        .background(Color.finaBackground)
        .animation(.spring(duration: 0.4), value: auth.signUpNeedsConfirmation)
        .onDisappear { auth.resetSignUp() }
    }

    // MARK: – Formulario de registro
    private var formCard: some View {
        VStack(spacing: 20) {

            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Crea tu cuenta")
                    .font(.poppins(.bold, size: 24))
                    .foregroundStyle(Color.finaForeground)
                Text("Empieza a controlar tus gastos gratis.")
                    .font(.poppins(.regular, size: 14))
                    .foregroundStyle(Color.finaMutedForeground)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Google
            Button {} label: {
                HStack(spacing: 10) {
                    GoogleIcon(size: 18)
                    Text("Continuar con Google")
                        .font(.poppins(.medium, size: 14))
                        .foregroundStyle(Color.finaForeground)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.finaCard)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.finaBorder, lineWidth: 1))
            }

            // Divider
            HStack(spacing: 12) {
                Rectangle().fill(Color.finaBorder).frame(height: 1)
                Text("o regístrate con")
                    .font(.poppins(.regular, size: 12))
                    .foregroundStyle(Color.finaMutedForeground)
                    .fixedSize()
                Rectangle().fill(Color.finaBorder).frame(height: 1)
            }

            // Nombre
            VStack(alignment: .leading, spacing: 6) {
                Text("Nombre")
                    .font(.poppins(.medium, size: 14))
                    .foregroundStyle(Color.finaForeground)
                FinaTextField(
                    placeholder: "Juan González",
                    text: $name,
                    autocapitalization: .words
                )
                .onChange(of: name) { _, _ in clearErrors() }
            }

            // Correo
            VStack(alignment: .leading, spacing: 6) {
                Text("Correo electrónico")
                    .font(.poppins(.medium, size: 14))
                    .foregroundStyle(Color.finaForeground)
                FinaTextField(
                    placeholder: "tu@correo.com",
                    text: $email,
                    keyboardType: .emailAddress,
                    autocapitalization: .never
                )
                .onChange(of: email) { _, _ in clearErrors() }
            }

            // Contraseña
            VStack(alignment: .leading, spacing: 6) {
                Text("Contraseña")
                    .font(.poppins(.medium, size: 14))
                    .foregroundStyle(Color.finaForeground)
                FinaSecureField(placeholder: "Mínimo 6 caracteres", text: $password)
                    .onChange(of: password) { _, _ in clearErrors() }
            }

            // Error
            errorBox

            // Botón
            Button {
                submit()
            } label: {
                submitLabel(title: "Crear cuenta", loading: "Creando cuenta...")
            }
            .disabled(auth.isLoading)

            // Login link
            HStack(spacing: 4) {
                Text("¿Ya tienes cuenta?")
                    .font(.poppins(.regular, size: 14))
                    .foregroundStyle(Color.finaMutedForeground)
                Button { dismiss() } label: {
                    Text("Inicia sesión")
                        .font(.poppins(.semiBold, size: 14))
                        .foregroundStyle(Color.finaForeground)
                }
            }
        }
        .padding(24)
        .background(Color.finaCard)
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.finaBorder, lineWidth: 1))
        .padding(.horizontal, 20)
    }

    // MARK: – Pantalla de confirmación de email
    private var confirmationCard: some View {
        VStack(spacing: 24) {

            // Ícono
            ZStack {
                Circle()
                    .fill(Color(red: 0.063, green: 0.725, blue: 0.506).opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(red: 0.063, green: 0.725, blue: 0.506))
            }

            // Texto
            VStack(spacing: 8) {
                Text("¡Revisa tu correo!")
                    .font(.poppins(.bold, size: 22))
                    .foregroundStyle(Color.finaForeground)

                VStack(spacing: 4) {
                    Text("Enviamos un enlace de confirmación a")
                        .font(.poppins(.regular, size: 14))
                        .foregroundStyle(Color.finaMutedForeground)
                    Text(auth.signUpConfirmationEmail)
                        .font(.poppins(.semiBold, size: 14))
                        .foregroundStyle(Color.finaForeground)
                }
                .multilineTextAlignment(.center)

                Text("Haz clic en el enlace para activar tu cuenta. Puede tardar unos segundos.")
                    .font(.poppins(.regular, size: 13))
                    .foregroundStyle(Color.finaMutedForeground)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.top, 4)
            }

            // Reenviar
            Button {
                Task { await auth.resendConfirmation(email: auth.signUpConfirmationEmail) }
            } label: {
                Text("Reenviar correo")
                    .font(.poppins(.medium, size: 14))
                    .foregroundStyle(Color.finaForeground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.finaCard)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.finaBorder, lineWidth: 1))
            }

            // Volver al login
            Button {
                auth.resetSignUp()
                dismiss()
            } label: {
                Text("Ir al inicio de sesión")
                    .font(.poppins(.semiBold, size: 14))
                    .foregroundStyle(Color.finaPrimaryForeground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.finaPrimary)
                    .cornerRadius(12)
            }
        }
        .padding(28)
        .background(Color.finaCard)
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.finaBorder, lineWidth: 1))
        .padding(.horizontal, 20)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal:   .move(edge: .leading).combined(with: .opacity)
        ))
    }

    // MARK: – Helpers
    @ViewBuilder
    private var errorBox: some View {
        let errorText = localError.isEmpty ? (auth.errorMessage ?? "") : localError
        if !errorText.isEmpty {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(red: 0.94, green: 0.29, blue: 0.29))
                Text(errorText)
                    .font(.poppins(.regular, size: 12))
                    .foregroundStyle(Color(red: 0.94, green: 0.29, blue: 0.29))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(red: 1, green: 0.94, blue: 0.94))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                Color(red: 0.97, green: 0.87, blue: 0.87), lineWidth: 1))
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func submitLabel(title: String, loading: String) -> some View {
        ZStack {
            if auth.isLoading {
                HStack(spacing: 8) {
                    ProgressView().tint(Color.finaPrimaryForeground)
                    Text(loading)
                        .font(.poppins(.medium, size: 14))
                        .foregroundStyle(Color.finaPrimaryForeground)
                }
            } else {
                Text(title)
                    .font(.poppins(.medium, size: 14))
                    .foregroundStyle(Color.finaPrimaryForeground)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(Color.finaPrimary.opacity(auth.isLoading ? 0.6 : 1))
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.2), value: auth.isLoading)
    }

    private func clearErrors() {
        localError = ""
        auth.clearError()
    }

    private func submit() {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            withAnimation { localError = "Completa todos los campos." }
            return
        }
        guard password.count >= 6 else {
            withAnimation { localError = "La contraseña es muy débil. Usa al menos 6 caracteres." }
            return
        }
        Task { await auth.signUp(email: email, password: password, name: name) }
    }
}

#Preview {
    SignupView()
        .environment(AuthManager())
}
