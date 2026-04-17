import SwiftUI

// MARK: - ProjectionReportTab
// Proyección del mes: balance estimado, barra real/proyect/meta, stats y nota de Monai.

struct ProjectionReportTab: View {
    let vm:       ReportsViewModel
    let currency: String

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {

                projectedBalanceCard
                barsCard
                statsRow
                monaiNote

            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Balance proyectado
    private var projectedBalanceCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("AL RITMO ACTUAL TERMINARÁS CON")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color.finaMutedForeground.opacity(0.6))
                .kerning(0.7)

            Text("$\(formatCompact(vm.projectedBalance, currency: currency))")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.063, green: 0.725, blue: 0.506))

            Text("en balance al \(vm.daysRemaining == 0 ? "fin de" : "30 de") \(vm.monthLabel.components(separatedBy: " ").first ?? "mes")")
                .font(.system(size: 12))
                .foregroundStyle(Color.finaMutedForeground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.finaCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.finaBorder, lineWidth: 1))
    }

    // MARK: - 3 barras: Real / Proyect. / Meta
    private var barsCard: some View {
        HStack(alignment: .bottom, spacing: 12) {
            barColumn(label: "Real",
                      fraction: vm.realFraction,
                      color: Color(red: 0.063, green: 0.725, blue: 0.506))
            barColumn(label: "Proyect.",
                      fraction: 0.75,
                      color: Color(red: 0.063, green: 0.725, blue: 0.506).opacity(0.5))
            barColumn(label: "Meta",
                      fraction: 0.60,
                      color: Color(red: 0.376, green: 0.376, blue: 0.780))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.finaCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.finaBorder, lineWidth: 1))
    }

    private func barColumn(label: String, fraction: Double, color: Color) -> some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(height: max(20, 80 * fraction))
                .frame(maxWidth: .infinity)

            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color.finaMutedForeground)
        }
        .frame(maxWidth: .infinity, alignment: .bottom)
    }

    // MARK: - Stats row
    private var statsRow: some View {
        HStack(spacing: 8) {
            statCard(
                label: "Gastos restantes",
                value: "−$\(formatCompact(vm.remainingExpenses, currency: currency))",
                sub:   "proyectados",
                valueColor: Color(red: 0.937, green: 0.267, blue: 0.267)
            )
            statCard(
                label: "Días restantes",
                value: "\(vm.daysRemaining)",
                sub:   "del mes",
                valueColor: Color.finaForeground
            )
        }
    }

    private func statCard(label: String, value: String, sub: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color.finaMutedForeground)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(valueColor)
            Text(sub)
                .font(.system(size: 10))
                .foregroundStyle(Color.finaMutedForeground.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.finaCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.finaBorder, lineWidth: 1))
    }

    // MARK: - Monai note
    private var monaiNote: some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0.984, green: 0.451, blue: 0.086))
                .frame(width: 3)
            Text(monaiText)
                .font(.system(size: 13))
                .foregroundStyle(Color.finaMutedForeground)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.finaCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.finaBorder, lineWidth: 1))
    }

    private var monaiText: String {
        let balance = vm.projectedBalance
        let days    = vm.daysRemaining
        if balance > 0 {
            return "fina: A este ritmo cerrarás \(vm.monthLabel.components(separatedBy: " ").first ?? "el mes") con $\(formatCompact(balance, currency: currency)) de balance. Te quedan \(days) días — cuida los gastos variables."
        } else {
            return "fina: Al ritmo actual, tus gastos superarán tus ingresos este mes. Revisa tus gastos variables de los próximos \(days) días."
        }
    }
}

private func formatCompact(_ amount: Double, currency: String) -> String {
    let divisor: Double; let suffix: String
    switch currency {
    case "COP", "CLP", "ARS":
        if amount >= 1_000_000 { divisor = 1_000_000; suffix = "M" }
        else                   { divisor = 1_000;     suffix = "k" }
    default:
        if amount >= 1_000     { divisor = 1_000;     suffix = "k" }
        else                   { divisor = 1;         suffix = "" }
    }
    let val = amount / divisor
    let fmt = val.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(val)) : String(format: "%.1f", val)
    return "\(fmt)\(suffix)"
}
