import SwiftUI

// MARK: - MiniStatsRow
// Fila de 3 mini tarjetas debajo del HeroBalanceCard.
// El contenido cambia según MonthContext.

struct MiniStat {
    let label: String
    let value: String
    let valueColor: Color
}

struct MiniStatsRow: View {
    let stats: [MiniStat]   // siempre 3 elementos

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                miniCard(stat)
            }
        }
    }

    private func miniCard(_ stat: MiniStat) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(stat.label.uppercased())
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.finaMutedForeground.opacity(0.6))
                .kerning(0.5)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(stat.value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(stat.valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(Color.finaCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.finaBorder, lineWidth: 1))
    }
}

// MARK: - Factory helpers
// Construyen los stats correctos según el contexto, sin lógica en la vista.

extension MiniStatsRow {

    static func forPast(savingsPct: Int, topCategory: String?, hormigaTotal: Double, currency: String) -> MiniStatsRow {
        MiniStatsRow(stats: [
            MiniStat(
                label: "Ahorro",
                value: "\(savingsPct)%",
                valueColor: colorForSavings(savingsPct)
            ),
            MiniStat(
                label: "Mayor gasto",
                value: topCategory?.capitalized ?? "—",
                valueColor: Color.finaForeground
            ),
            MiniStat(
                label: "Hormiga",
                value: hormigaTotal > 0 ? formatCompact(hormigaTotal, currency: currency) : "—",
                valueColor: hormigaTotal > 0 ? Color(red: 0.937, green: 0.620, blue: 0.153) : Color.finaMutedForeground
            ),
        ])
    }

    static func forCurrent(savingsPct: Int, budgetPct: Int?, todayExpenses: Double, currency: String) -> MiniStatsRow {
        MiniStatsRow(stats: [
            MiniStat(
                label: "Ahorro",
                value: "\(savingsPct)%",
                valueColor: colorForSavings(savingsPct)
            ),
            MiniStat(
                label: "Presupuesto",
                value: budgetPct.map { "\($0)%" } ?? "—",
                valueColor: colorForBudget(budgetPct ?? 0)
            ),
            MiniStat(
                label: "Hoy",
                value: todayExpenses > 0 ? "−\(formatCompact(todayExpenses, currency: currency))" : "$0",
                valueColor: todayExpenses > 0 ? Color(red: 0.937, green: 0.267, blue: 0.267) : Color.finaMutedForeground
            ),
        ])
    }

    static func forFuture(projection: ProjectionData, currency: String) -> MiniStatsRow {
        MiniStatsRow(stats: [
            MiniStat(
                label: "Ahorro est.",
                value: "~\(projection.estimatedSavingsPct)%",
                valueColor: colorForSavings(projection.estimatedSavingsPct)
            ),
            MiniStat(
                label: "Fijos progr.",
                value: projection.scheduledFixed > 0 ? formatCompact(projection.scheduledFixed, currency: currency) : "—",
                valueColor: Color.finaForeground
            ),
            MiniStat(
                label: "Variables est.",
                value: projection.estimatedVariable > 0 ? formatCompact(projection.estimatedVariable, currency: currency) : "—",
                valueColor: Color.finaMutedForeground
            ),
        ])
    }

    // MARK: - Color helpers
    private static func colorForSavings(_ pct: Int) -> Color {
        if pct >= 20 { return Color(red: 0.063, green: 0.725, blue: 0.506) }
        if pct > 0   { return Color(red: 0.937, green: 0.620, blue: 0.153) }
        return Color(red: 0.937, green: 0.267, blue: 0.267)
    }

    private static func colorForBudget(_ pct: Int) -> Color {
        if pct < 60  { return Color(red: 0.063, green: 0.725, blue: 0.506) }
        if pct < 85  { return Color(red: 0.937, green: 0.620, blue: 0.153) }
        return Color(red: 0.937, green: 0.267, blue: 0.267)
    }
}

// MARK: - Shared compact formatter (duplicado aquí para independencia del archivo)
private func formatCompact(_ amount: Double, currency: String) -> String {
    let divisor: Double
    let suffix: String
    switch currency {
    case "COP", "CLP", "ARS":
        if amount >= 1_000_000 { divisor = 1_000_000; suffix = "M" }
        else                   { divisor = 1_000;     suffix = "k" }
    default:
        if amount >= 1_000 { divisor = 1_000; suffix = "k" }
        else               { divisor = 1;     suffix = "" }
    }
    let val = amount / divisor
    let formatted = val.truncatingRemainder(dividingBy: 1) == 0
        ? String(Int(val))
        : String(format: "%.1f", val)
    return "\(formatted)\(suffix)"
}
