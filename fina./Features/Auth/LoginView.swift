import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) private var auth

    @State private var email = ""
    @State private var password = ""
@State private var localError = ""
    @State private var showSignup = false

    var body: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    VStack(spacing: 32) {
                        // MARK: Card
                        VStack(spacing: 20) {

                            // Header
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Bienvenido de nuevo")
                                    .font(.poppins(.bold, size: 24))
                                    .foregroundStyle(Color.finaForeground)

                                Text("Ingresa tu correo y contraseña para continuar.")
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
                                Text("o continua con")
                                    .font(.poppins(.regular, size: 12))
                                    .foregroundStyle(Color.finaMutedForeground)
                                    .fixedSize()
                                Rectangle().fill(Color.finaBorder).frame(height: 1)
                            }

                            // Email
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
                                .onChange(of: email) { _, _ in localError = ""; auth.clearError() }
                            }

                            // Password
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Contraseña")
                                        .font(.poppins(.medium, size: 14))
                                        .foregroundStyle(Color.finaForeground)
                                    Spacer()
                                    Button("Olvidé mi contraseña") {}
                                        .font(.poppins(.regular, size: 12))
                                        .foregroundStyle(Color.finaMutedForeground)
                                }
                                FinaSecureField(placeholder: "••••••••", text: $password)
                                    .onChange(of: password) { _, _ in localError = ""; auth.clearError() }
                            }

                            // Error box
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

                            // Submit
                            Button {
                                guard !email.isEmpty, !password.isEmpty else {
                                    withAnimation { localError = "Falta el correo o la contraseña." }
                                    return
                                }
                                Task { await auth.signIn(email: email, password: password) }
                            } label: {
                                ZStack {
                                    if auth.isLoading {
                                        HStack(spacing: 8) {
                                            ProgressView().tint(Color.finaPrimaryForeground)
                                            Text("Iniciando sesión...")
                                                .font(.poppins(.medium, size: 14))
                                                .foregroundStyle(Color.finaPrimaryForeground)
                                        }
                                    } else {
                                        Text("Iniciar sesión")
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
                            .disabled(auth.isLoading)

                            // Register link
                            HStack(spacing: 4) {
                                Text("¿No tienes cuenta?")
                                    .font(.poppins(.regular, size: 14))
                                    .foregroundStyle(Color.finaMutedForeground)
                                Button {
                                    showSignup = true
                                } label: {
                                    Text("Regístrate gratis")
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
        .fullScreenCover(isPresented: $showSignup) {
            SignupView()
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthManager())
}
