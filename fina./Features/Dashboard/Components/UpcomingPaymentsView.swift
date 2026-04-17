import SwiftUI

// MARK: - UpcomingPaymentsView
// Próximos pagos recurrentes en los siguientes 7 días.
// Siempre visible en MonthContext.current — muestra empty state si no hay pagos.

struct UpcomingPaymentsView: View {
    let payments:       [TxRecord]
    let categoryColors: [String: String]   // categoryId → hex color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text("PRÓXIMOS PAGOS")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.finaMutedForeground.opacity(0.6))
                .kerning(0.8)

            if payments.isEmpty {
                emptyState
            } else {
                ForEach(payments) { tx in
                    paymentRow(tx)
                }
            }
        }
    }

    // MARK: - Empty state
    private var emptyState: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 18))
                .foregroundStyle(Color(red: 0.063, green: 0.725, blue: 0.506))

            Text("No tienes pagos pendientes en los próximos días.")
                .font(.system(size: 13))
                .foregroundStyle(Color.finaMutedForeground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color.finaCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.finaBorder, lineWidth: 1))
    }

    // MARK: - Payment row
    private func paymentRow(_ tx: TxRecord) -> some View {
        let accentHex = tx.customColor ?? categoryColors[tx.categoryId] ?? "#888888"
        let accent    = Color(hex: accentHex)
        let daysAway  = daysUntil(tx.date)

        return HStack(spacing: 12) {
            // Fecha
            VStack(spacing: 1) {
                Text(dayString(tx.date))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.finaForeground)
                Text(monthAbbr(tx.date).uppercased())
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color.finaMutedForeground)
            }
            .frame(width: 32)

            // Nombre + tiempo relativo
            VStack(alignment: .leading, spacing: 2) {
                Text(tx.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.finaForeground)
                    .lineLimit(1)
                Text(relativeLabel(daysAway))
                    .font(.system(size: 11))
                    .foregroundStyle(labelColor(daysAway))
            }

            Spacer()

            // Monto
            Text("−\(formatAmount(tx.amount, currency: tx.currency))")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(amountColor(daysAway))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.finaCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(accent)
                .frame(width: 3)
                .padding(.vertical, 8)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.finaBorder, lineWidth: 1))
    }

    // MARK: - Helpers
    private func daysUntil(_ dateStr: String) -> Int {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        guard let date = df.date(from: dateStr) else { return 99 }
        return Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: date
        ).day ?? 99
    }

    private func relativeLabel(_ days: Int) -> String {
        switch days {
        case 0:  return "Hoy"
        case 1:  return "Mañana"
        default: return "En \(days) días"
        }
    }

    private func labelColor(_ days: Int) -> Color {
        switch days {
        case 0:  return Color(red: 0.937, green: 0.267, blue: 0.267)
        case 1:  return Color(red: 0.984, green: 0.451, blue: 0.086)
        default: return Color.finaMutedForeground
        }
    }

    private func amountColor(_ days: Int) -> Color {
        switch days {
        case 0:  return Color(red: 0.937, green: 0.267, blue: 0.267)
        case 1:  return Color(red: 0.984, green: 0.451, blue: 0.086)
        default: return Color.finaMutedForeground
        }
    }

    private func dayString(_ dateStr: String) -> String {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        guard let date = df.date(from: dateStr) else { return "—" }
        return "\(Calendar.current.component(.day, from: date))"
    }

    private func monthAbbr(_ dateStr: String) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "es_CO")
        guard let date = df.date(from: dateStr) else { return "" }
        let mf = DateFormatter()
        mf.locale = Locale(identifier: "es_CO")
        mf.dateFormat = "MMM"
        return String(mf.string(from: date).prefix(3))
    }
}
