import SwiftUI

// MARK: - ProFeature model
private struct ProFeature {
    let icon: String
    let title: String
    let subtitle: String
}

private let PRO_FEATURES: [ProFeature] = [
    .init(icon: "square.grid.2x2",    title: "Categorías ilimitadas",    subtitle: "Sin límite en tus categorías de gasto."),
    .init(icon: "chart.bar.xaxis",    title: "Análisis histórico",       subtitle: "Ve todas tus estadísticas sin límite de tiempo."),
    .init(icon: "arrow.down.doc",     title: "Exportar datos",           subtitle: "Descarga tus transacciones en CSV o Excel."),
    .init(icon: "bell.badge",         title: "Alertas de presupuesto",   subtitle: "Recibe avisos al acercarte a tu límite."),
]

// MARK: - ProUpgradeView
struct ProUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasPro")   private var hasPro: Bool = false

    @State private var selectedPlan = "lifetime"

    private let planLifetime: (label: String, price: String, badge: String?) = (
        "Lifetime",
        "$129.900",
        "Founding member price"
    )
    private let planMonthly: (label: String, price: String, badge: String?) = (
        "Mensual",
        "$9.900 / mes",
        nil
    )

    var body: some View {
        ZStack {
            // Fondo oscuro
            Color(red: 0.06, green: 0.05, blue: 0.05).ignoresSafeArea()

            // Aurora sutil
            auroraBackground.ignoresSafeArea().allowsHitTesting(false)

            VStack(spacing: 0) {
                // ── Top bar ──────────────────────────────────────────
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.10))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Button { restorePurchases() } label: {
                        Text("Restaurar")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(.white.opacity(0.10))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 28)

                        // ── Logo + título ────────────────────────────
                        VStack(spacing: 12) {
                            // Icono app
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.980, green: 0.451, blue: 0.086))
                                    .frame(width: 72, height: 72)
                                Text("f")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                            .shadow(color: Color(red: 0.980, green: 0.451, blue: 0.086).opacity(0.5),
                                    radius: 16, y: 6)

                            // Nombre + PRO badge
                            HStack(spacing: 8) {
                                Text("fina.")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(.white)

                                Text("PRO")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Color(red: 0.980, green: 0.451, blue: 0.086))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }

                            Text("Controla tus finanzas sin límites.")
                                .font(.system(size: 15))
                                .foregroundStyle(.white.opacity(0.65))
                                .multilineTextAlignment(.center)
                        }

                        Spacer(minLength: 32)

                        // ── Feature list ─────────────────────────────
                        VStack(spacing: 0) {
                            ForEach(Array(PRO_FEATURES.enumerated()), id: \.offset) { idx, feat in
                                featureRow(feat)
                                if idx < PRO_FEATURES.count - 1 {
                                    Divider()
                                        .background(.white.opacity(0.08))
                                        .padding(.leading, 56)
                                }
                            }
                        }
                        .background(.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.10), lineWidth: 1))
                        .padding(.horizontal, 20)

                        Spacer(minLength: 24)

                        // ── Opciones de plan ─────────────────────────
                        VStack(spacing: 10) {
                            planOption(
                                id: "lifetime",
                                label: planLifetime.label,
                                price: planLifetime.price,
                                badge: planLifetime.badge
                            )
                            planOption(
                                id: "monthly",
                                label: planMonthly.label,
                                price: planMonthly.price,
                                badge: planMonthly.badge
                            )
                        }
                        .padding(.horizontal, 20)

                        // "Mostrar más planes"
                        Button {} label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 11))
                                Text("Ver más planes")
                                    .font(.system(size: 13))
                            }
                            .foregroundStyle(.white.opacity(0.45))
                        }
                        .padding(.top, 10)

                        Spacer(minLength: 24)
                    }
                }

                // ── Footer fijo ──────────────────────────────────────
                VStack(spacing: 12) {
                    // CTA
                    Button { subscribe() } label: {
                        Text("Continuar")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(.white)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 20)

                    // Legal
                    HStack(spacing: 20) {
                        Button("Términos") {}
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.35))
                        Button("Política de Privacidad") {}
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Feature row
    private func featureRow(_ feat: ProFeature) -> some View {
        HStack(spacing: 14) {
            Image(systemName: feat.icon)
                .font(.system(size: 18))
                .foregroundStyle(Color(red: 0.980, green: 0.451, blue: 0.086))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(feat.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(feat.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.50))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Plan option
    private func planOption(id: String, label: String, price: String, badge: String?) -> some View {
        let selected = selectedPlan == id
        return Button { withAnimation(.spring(duration: 0.2)) { selectedPlan = id } } label: {
            HStack(spacing: 12) {
                // Radio
                ZStack {
                    Circle()
                        .stroke(.white.opacity(selected ? 1 : 0.25), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    if selected {
                        Circle()
                            .fill(Color(red: 0.980, green: 0.451, blue: 0.086))
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    if let badge {
                        Text(badge)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }

                Spacer()

                Text(price)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(selected
                                     ? Color(red: 0.980, green: 0.451, blue: 0.086)
                                     : .white.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(selected ? .white.opacity(0.08) : .white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(selected
                        ? Color(red: 0.980, green: 0.451, blue: 0.086).opacity(0.6)
                        : .white.opacity(0.10),
                        lineWidth: selected ? 1.5 : 1))
        }
    }

    // MARK: - Aurora
    @State private var anim = false
    private var auroraBackground: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Circle()
                    .fill(Color(red: 0.980, green: 0.451, blue: 0.086))
                    .frame(width: w * 0.8)
                    .offset(x: anim ? -w * 0.2 : w * 0.1, y: anim ? -h * 0.3 : -h * 0.1)
                    .opacity(0.25)
                    .blur(radius: 80)
                Circle()
                    .fill(Color(red: 0.800, green: 0.200, blue: 0.100))
                    .frame(width: w * 0.6)
                    .offset(x: anim ? w * 0.2 : -w * 0.1, y: anim ? h * 0.1 : h * 0.3)
                    .opacity(0.20)
                    .blur(radius: 80)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                anim = true
            }
        }
    }

    // MARK: - Actions
    private func subscribe() {
        // TODO: conectar StoreKit
        hasPro = true
        dismiss()
    }

    private func restorePurchases() {
        // TODO: StoreKit restore
    }
}

#Preview {
    ProUpgradeView()
}
