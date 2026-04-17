import SwiftUI

// MARK: - ProjectionBreakdownView
// Tabla de desglose del mes futuro: ingresos estimados, fijos programados,
// variables estimadas y balance proyectado.
// Solo se muestra en MonthContext.future.

struct ProjectionBreakdownView: View {
    let projection: ProjectionData
    let currency:   String

    var body: some View {
        VStack(spacing: 0) {
            // Línea de ingreso
            row(label: "Ingreso esperado",
                value: "+\(formatAmount(projection.estimatedIncome, currency: currency))",
                valueColor: Color(red: 0.063, green: 0.725, blue: 0.506))

            // Líneas de fijos por categoría
            ForEach(projection.fixedLines, id: \.label) { line in
                divider()
                row(label: line.label.capitalized,
                    value: "−\(formatAmount(line.amount, currency: currency))",
                    valueColor: Color(red: 0.937, green: 0.267, blue: 0.267))
            }

            // Variables estimadas
            divider()
            row(label: "Variables (est.)",
                value: "−\(formatAmount(projection.estimatedVariable, currency: currency))",
                valueColor: Color.finaMutedForeground)

            // Total proyectado
            Divider()
                .padding(.vertical, 6)

            HStack {
                Text("Proyección")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.finaMutedForeground)
                Spacer()
                Text("≈\(formatAmount(projection.estimatedBalance, currency: currency))")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.063, green: 0.725, blue: 0.506))
            }
        }
        .padding(12)
        .background(Color.finaCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.finaBorder, lineWidth: 1))
    }

    private func row(label: String, value: String, valueColor: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color.finaMutedForeground)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(valueColor)
        }
        .padding(.vertical, 5)
    }

    private func divider() -> some View {
        Divider().opacity(0.4)
    }
}
