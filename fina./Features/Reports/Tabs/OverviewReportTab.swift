import SwiftUI

// MARK: - OverviewReportTab
// Vista principal de reportes: 4 stats, gráfico de barras, categorías.

struct OverviewReportTab: View {
    let vm:       ReportsViewModel
    let currency: String

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {

                statsGrid
                MonthBarChart(data: vm.last6MonthsData, currency: currency)
                categoryBreakdown

            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
    }

    // MARK: - 4 stat cards
    private var statsGrid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                statCard(
                    label:   "INGRESOS",
                    value:   formatCompact(vm.totalIncome, currency: currency),
                    change:  vm.incomePctChange,
                    color:   Color(red: 0.063, green: 0.725, blue: 0.506)
                )
                statCard(
                    label:   "GASTOS",
                    value:   formatCompact(vm.totalExpenses, currency: currency),
                    change:  vm.expensePctChange,
                    color:   Color(red: 0.937, green: 0.267, blue: 0.267)
                )
            }
            HStack(spacing: 8) {
                statCard(
                    label:   "AHORRO NETO",
                    value:   formatCompact(vm.netSavings, currency: currency),
                    sub:     "\(vm.savingsPct)%",
                    color:   Color.finaForeground
                )
                statCard(
                    label:   "GASTO/DÍA",
                    value:   formatCompact(vm.dailyAvgExpense, currency: currency),
                    sub:     "promedio",
                    color:   Color(red: 0.984, green: 0.451, blue: 0.086)
                )
            }
        }
    }

    private func statCard(
        label:  String,
        value:  String,
        change: Double? = nil,
        sub:    String? = nil,
        color:  Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color.finaMutedForeground.opacity(0.6))
                .kerning(0.6)

            Text("$\(value)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            if let change {
                let sign   = change >= 0 ? "+" : ""
                let chgColor: Color = change >= 0
                    ? Color(red: 0.937, green: 0.267, blue: 0.267)
                    : Color(red: 0.063, green: 0.725, blue: 0.506)
                Text("\(sign)\(Int(change))% vs \(vm.prevMonthShortLabel)")
                    .font(.system(size: 10))
                    .foregroundStyle(chgColor)
            } else if let sub {
                Text(sub)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.finaMutedForeground)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.finaCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.finaBorder, lineWidth: 1))
    }

    // MARK: - Category breakdown
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("POR CATEGORÍA")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color.finaMutedForeground.opacity(0.6))
                .kerning(0.7)

            if vm.categoryStats.isEmpty {
                Text("Sin gastos registrados este mes.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.finaMutedForeground)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(vm.categoryStats) { stat in
                        CategoryBarRow(stat: stat)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.finaCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.finaBorder, lineWidth: 1))
    }
}

// MARK: - Compact formatter
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
