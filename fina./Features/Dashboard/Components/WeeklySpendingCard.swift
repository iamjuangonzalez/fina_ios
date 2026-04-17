import SwiftUI

// MARK: - WeeklySpendingCard
// Barras verticales agrupadas por semana del mes.
// Cada columna tiene altura fija — la barra crece desde la base hacia arriba.

struct WeeklySpendingCard: View {
    let transactions: [TxRecord]
    let currentDate:  Date
    let currency:     String

    private let BAR_AREA: CGFloat = 100   // altura fija del área de barras
    private let LABEL_H:  CGFloat = 14    // altura fija del monto encima
    private let DATE_H:   CGFloat = 20    // altura fija del rango de fechas

    // MARK: - Semanas del mes
    private struct WeekBucket: Identifiable {
        let id:    Int
        let start: Int
        let end:   Int
        var total: Double = 0
    }

    private var daysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: currentDate)?.count ?? 30
    }

    private var buckets: [WeekBucket] {
        let days = daysInMonth
        var raw: [(Int, Int)] = [(1,7),(8,14),(15,21),(22,28)]
        if days > 28 { raw.append((29, days)) }

        var result = raw.enumerated().map { i, r in WeekBucket(id: i, start: r.0, end: r.1) }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        for tx in transactions where tx.type == "expense" {
            guard let date = df.date(from: tx.date) else { continue }
            let day = Calendar.current.component(.day, from: date)
            for i in result.indices where day >= result[i].start && day <= result[i].end {
                result[i].total += tx.amount
                break
            }
        }
        return result
    }

    private var totalSpent: Double {
        transactions.filter { $0.type == "expense" }.reduce(0) { $0 + $1.amount }
    }

    private var maxTotal: Double {
        buckets.map(\.total).max().flatMap { $0 > 0 ? $0 : nil } ?? 1
    }

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ───────────────────────────────────────────
            VStack(alignment: .leading, spacing: 4) {
                Text("Gastado este mes")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.finaMutedForeground)

                Text(formatAmount(totalSpent, currency: currency))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.finaForeground)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 20)

            // ── Barras — se distribuyen equitativamente sin scroll ──
            HStack(alignment: .top, spacing: 0) {
                ForEach(buckets) { bucket in
                    barColumn(bucket)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.finaCard)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.finaBorder, lineWidth: 1))
    }

    // MARK: - Columna individual (altura siempre fija)
    private func barColumn(_ bucket: WeekBucket) -> some View {
        let fraction  = CGFloat(bucket.total / maxTotal)
        let barHeight = bucket.total > 0 ? max(6, fraction * BAR_AREA) : 0
        let isActive  = bucket.total > 0

        return GeometryReader { geo in
            let colW = geo.size.width
            let barW = max(colW * 0.55, 20)

            VStack(spacing: 0) {

                // ① Monto encima — altura fija
                Text(isActive ? compactAmount(bucket.total) : "")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.finaPrimary)
                    .frame(height: LABEL_H)

                // ② Área de barra — altura fija, barra crece desde la base
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isActive ? Color.finaPrimary.opacity(0.35) : Color.clear)
                        .frame(width: barW, height: barHeight)
                        .animation(.spring(duration: 0.5), value: barHeight)
                }
                .frame(height: BAR_AREA)

                // ③ Etiqueta de rango — altura fija
                Text("\(bucket.start)-\(bucket.end)")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.finaMutedForeground)
                    .frame(height: DATE_H)
                    .padding(.top, 4)
            }
            .frame(width: colW)
        }
        .frame(height: LABEL_H + BAR_AREA + DATE_H + 4)
    }

    // MARK: - Helpers
    private func compactAmount(_ v: Double) -> String {
        if v >= 1_000_000 { return String(format: "%.1fM", v / 1_000_000) }
        if v >= 1_000     { return String(format: "%.0fK", v / 1_000) }
        return "\(Int(v))"
    }
}
