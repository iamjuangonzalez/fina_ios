import SwiftUI

// MARK: - MonthBarChart
// Gráfico de barras apiladas: Ingresos (verde) + Gastos (naranja) — últimos 6 meses.

struct MonthBarChart: View {
    let data:     [MonthBarData]
    let currency: String

    private let incomeColor  = Color(red: 0.063, green: 0.725, blue: 0.506)
    private let expenseColor = Color(red: 0.737, green: 0.349, blue: 0.220)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("INGRESOS VS GASTOS — ÚLTIMOS 6 MESES")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color.finaMutedForeground.opacity(0.6))
                .kerning(0.7)

            GeometryReader { geo in
                let maxVal = data.map { max($0.income, $0.expenses) }.max() ?? 1
                let barW   = (geo.size.width - CGFloat(data.count - 1) * 6) / CGFloat(data.count)

                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(data) { item in
                        barColumn(item: item, maxVal: maxVal,
                                  barW: barW, height: geo.size.height - 24)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 24)

                // Labels del eje X
                HStack(spacing: 6) {
                    ForEach(data) { item in
                        Text(item.label)
                            .font(.system(size: 9))
                            .foregroundStyle(item.isCurrent
                                ? Color.finaForeground
                                : Color.finaMutedForeground.opacity(0.5))
                            .frame(width: barW)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .bottom)
                .offset(y: geo.size.height - 16)
            }
            .frame(height: 130)

            // Leyenda
            HStack(spacing: 14) {
                legendDot(color: incomeColor,  label: "Ingresos")
                legendDot(color: expenseColor, label: "Gastos")
            }
        }
        .padding(14)
        .background(Color.finaCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.finaBorder, lineWidth: 1))
    }

    private func barColumn(item: MonthBarData, maxVal: Double,
                           barW: CGFloat, height: CGFloat) -> some View {
        let incH = maxVal > 0 ? CGFloat(item.income   / maxVal) * height : 0
        let expH = maxVal > 0 ? CGFloat(item.expenses / maxVal) * height : 0

        return ZStack(alignment: .bottom) {
            // Barra de gastos (fondo)
            RoundedRectangle(cornerRadius: 4)
                .fill(expenseColor.opacity(0.85))
                .frame(width: barW, height: max(2, expH))

            // Barra de ingresos (superpuesta, más estrecha)
            RoundedRectangle(cornerRadius: 4)
                .fill(incomeColor.opacity(0.85))
                .frame(width: barW * 0.55, height: max(2, incH))
                .frame(width: barW, alignment: .leading)
                .padding(.leading, 4)
        }
        .frame(width: barW, alignment: .bottom)
        .overlay(
            // Borde del mes actual
            RoundedRectangle(cornerRadius: 4)
                .stroke(item.isCurrent
                    ? Color(red: 0.984, green: 0.451, blue: 0.086)
                    : Color.clear,
                    lineWidth: 1.5)
                .frame(width: barW, height: max(expH, incH))
        )
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color.finaMutedForeground)
        }
    }
}
