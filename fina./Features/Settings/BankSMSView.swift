import SwiftUI

struct BankSMSView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("bankSMSStep") private var completedStep: Int = 0

    private let shortcutURL = "https://www.icloud.com/shortcuts/fa19a0835f1a471ba99c78f73931a726"

    private let banks: [(emoji: String, name: String)] = [
        ("🏦", "Bancolombia"),
        ("💚", "Nequi"),
        ("🔵", "Davivienda"),
        ("🟠", "Daviplata"),
        ("🟣", "BBVA"),
        ("🔷", "Itaú"),
        ("🟡", "Scotiabank"),
        ("💳", "Cualquier banco que envíe SMS"),
    ]

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
                            Image(systemName: "message.fill")
                                .font(.system(size: 30, weight: .medium))
                                .foregroundStyle(Color.finaBackground)
                        }

                        Text("SMS Bancario automático")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color.finaForeground)

                        Text("Cada mensaje de tu banco se convierte\nautomáticamente en una transacción en fina.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.finaMutedForeground)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                    .padding(.top, 28)
                    .padding(.bottom, 24)

                    // Bancos compatibles
                    VStack(alignment: .leading, spacing: 10) {
                        Text("BANCOS COMPATIBLES")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.finaMutedForeground.opacity(0.6))
                            .kerning(0.8)
                            .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(banks, id: \.name) { bank in
                                    HStack(spacing: 6) {
                                        Text(bank.emoji)
                                            .font(.system(size: 14))
                                        Text(bank.name)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(Color.finaForeground)
                                    }
                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                    .background(Color.finaCard)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Color.finaBorder, lineWidth: 1))
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 24)

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
                            description: "Ejecuta el atajo una vez. Aparecerá un aviso de permiso — toca \"Permitir\" para que fina pueda guardar transacciones.",
                            buttonLabel: "Ejecutar atajo",
                            done: completedStep >= 2,
                            disabled: completedStep < 1
                        ) {
                            let name = "Fina.%20SMS%20Bancario"
                            let runURL = "shortcuts://run-shortcut?name=\(name)"
                            if let url = URL(string: runURL) {
                                UIApplication.shared.open(url)
                            }
                            if completedStep < 2 { completedStep = 2 }
                        }

                        stepCard(
                            number: 3,
                            icon: "bolt.fill",
                            title: "Crea la automatización",
                            description: "En Atajos ve a Automatización → + → Mensaje. Filtra por el remitente de tu banco (ej. \"Bancolombia\", \"Nequi\", \"Davivienda\"). Activa \"Ejecutar de inmediato\". Toca \"Nueva acción en blanco\", busca \"Ejecutar atajo\" y elige \"Fina. SMS Bancario\".\n\nRepite para cada banco que quieras rastrear.",
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
                            Text("Cada mensaje de tu banco registrará\nla transacción automáticamente en fina.")
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

    // MARK: - Step card (igual que ApplePayView)
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
    BankSMSView()
}
