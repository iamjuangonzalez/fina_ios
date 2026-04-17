import SwiftUI

struct ApplePayView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("applePayStep") private var completedStep: Int = 0

    private let shortcutURL  = "https://www.icloud.com/shortcuts/878134ae9bf349c1a237ff81bde6c79c"
    private let shortcutName = "Fina.%20Apple%20Pay"

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color.finaForeground)
                                .frame(width: 72, height: 72)
                            Image(systemName: "wave.3.right")
                                .font(.system(size: 30, weight: .medium))
                                .foregroundStyle(Color.finaBackground)
                        }

                        Text("Apple Pay automático")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color.finaForeground)

                        Text("Cada pago con Apple Pay\nse registra solo en fina.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.finaMutedForeground)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                    .padding(.top, 28)
                    .padding(.bottom, 32)

                    // Pasos
                    VStack(spacing: 12) {

                        stepCard(
                            number: 1,
                            icon: "arrow.down.circle.fill",
                            title: "Instala el atajo",
                            description: "Descarga el atajo de fina. Toca \"Agregar shortcut\" cuando iOS te lo pida.",
                            buttonLabel: "Descargar atajo",
                            done: completedStep >= 1
                        ) {
                            if let url = URL(string: shortcutURL) {
                                UIApplication.shared.open(url)
                            }
                            if completedStep < 1 { completedStep = 1 }
                        }

                        stepCard(
                            number: 2,
                            icon: "hand.tap.fill",
                            title: "Permite el acceso",
                            description: "Ejecuta el atajo una vez. Verás un aviso de permiso — toca \"Permitir\" para que fina pueda guardar transacciones.",
                            buttonLabel: "Ejecutar atajo",
                            done: completedStep >= 2,
                            disabled: completedStep < 1
                        ) {
                            let runURL = "shortcuts://run-shortcut?name=\(shortcutName)"
                            if let url = URL(string: runURL) {
                                UIApplication.shared.open(url)
                            }
                            if completedStep < 2 { completedStep = 2 }
                        }

                        stepCard(
                            number: 3,
                            icon: "bolt.fill",
                            title: "Crea la automatización",
                            description: "En Atajos ve a Automatización → + → Transacción. Selecciona tus tarjetas, activa \"Ejecutar de inmediato\". Toca \"Nueva acción en blanco\", busca \"Ejecutar atajo\" y elige \"Fina. Apple Pay\".",
                            buttonLabel: "Abrir Atajos",
                            done: completedStep >= 3,
                            disabled: completedStep < 2
                        ) {
                            if let url = URL(string: "shortcuts://") {
                                UIApplication.shared.open(url)
                            }
                            if completedStep < 3 { completedStep = 3 }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Banner completado
                    if completedStep >= 3 {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(Color.finaSavingsGood)
                            Text("¡Todo listo!")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.finaForeground)
                            Text("Cada vez que pagues con Apple Pay\nfina registrará el gasto automáticamente.")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.finaMutedForeground)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                        }
                        .padding(.top, 28)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }

                    // Reset
                    if completedStep > 0 {
                        Button { completedStep = 0 } label: {
                            Text("Reiniciar configuración")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.finaMutedForeground)
                        }
                        .padding(.top, 24)
                    }

                    Spacer(minLength: 40)
                }
            }
            .background(Color.finaBackground)
            .animation(.easeInOut(duration: 0.3), value: completedStep)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.finaForeground)
                            .frame(width: 32, height: 32)
                            .background(Color.finaMuted)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    // MARK: - Step card
    private func stepCard(
        number: Int,
        icon: String,
        title: String,
        description: String,
        buttonLabel: String,
        done: Bool,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: 16) {

            ZStack {
                Circle()
                    .fill(done ? Color.finaPrimary : (disabled ? Color.finaMuted : Color.finaPrimary.opacity(0.12)))
                    .frame(width: 36, height: 36)
                if done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.finaPrimaryForeground)
                } else {
                    Text("\(number)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(disabled ? Color.finaMutedForeground : Color.finaPrimary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(disabled ? Color.finaMutedForeground : Color.finaForeground)
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(disabled ? Color.finaMutedForeground : Color.finaForeground)
                }

                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.finaMutedForeground)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                if !done {
                    Button(action: action) {
                        Text(buttonLabel)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(disabled ? Color.finaMutedForeground : Color.finaPrimaryForeground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(disabled ? Color.finaMuted : Color.finaPrimary)
                            .cornerRadius(10)
                    }
                    .disabled(disabled)
                    .padding(.top, 2)
                } else {
                    Text("Completado")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.finaSavingsGood)
                        .padding(.top, 2)
                }
            }
        }
        .padding(16)
        .background(Color.finaCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(done ? Color.finaSavingsGood.opacity(0.4) : Color.finaBorder, lineWidth: 1)
        )
        .opacity(disabled ? 0.5 : 1)
    }
}

#Preview {
    ApplePayView()
}
