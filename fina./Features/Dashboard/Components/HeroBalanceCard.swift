import SwiftUI

// MARK: - HeroBalanceCard
// Card principal del dashboard. Tiene tres variantes visuales según MonthContext.

struct HeroBalanceCard: View {
    let context:     MonthContext
    let balance:     Double
    let income:      Double
    let expenses:    Double
    let savingsPct:  Int
    let currency:    String
    let dayOfMonth:  Int     // solo relevante en .current
    let daysInMonth: Int     // solo relevante en .current

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            badge
                .padding(.bottom, 8)

            label
                .padding(.bottom, 2)

            amountText
                .padding(.bottom, 4)

            subtitle
                .padding(.bottom, 10)

            pills
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(cardBorder)
    }

    // MARK: - Badge
    private var badge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(badgeDotColor)
                .frame(width: 5, height: 5)
            Text(badgeText)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(badgeForeground)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(badgeBackground)
        .clipShape(Capsule())
    }

    // MARK: - Label
    private var label: some View {
        Text(labelText.uppercased())
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(labelColor)
            .kerning(0.8)
    }

    // MARK: - Amount
    private var amountText: some View {
        Text(formatAmount(balance, currency: currency))
            .font(.system(size: 34, weight: .bold, design: .rounded))
            .foregroundStyle(amountColor)
            .minimumScaleFactor(0.6)
            .lineLimit(1)
    }

    // MARK: - Subtitle
    private var subtitle: some View {
        Text(subtitleText)
            .font(.system(size: 12))
            .foregroundStyle(subtitleColor)
    }

    // MARK: - Pills (ingresos / gastos)
    private var pills: some View {
        HStack(spacing: 6) {
            pill(text: "+\(formatCompact(income, currency: currency))",
                 dotColor: incomeDotColor)
            pill(text: "−\(formatCompact(expenses, currency: currency))",
                 dotColor: expenseDotColor)
        }
    }

    private func pill(text: String, dotColor: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(dotColor).frame(width: 5, height: 5)
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(pillForeground)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(pillBackground)
        .clipShape(Capsule())
    }

    // MARK: - Backgrounds & borders
    @ViewBuilder
    private var cardBackground: some View {
        switch context {
        case .current:
            Color(red: 0.063, green: 0.725, blue: 0.506)   // verde
        case .past:
            Color.finaCard
        case .future:
            Color.finaCard
        }
    }

    @ViewBuilder
    private var cardBorder: some View {
        switch context {
        case .current:
            RoundedRectangle(cornerRadius: 16).stroke(Color.clear, lineWidth: 0)
        case .past:
            RoundedRectangle(cornerRadius: 16).stroke(Color.finaBorder, lineWidth: 1)
        case .future:
            RoundedRectangle(cornerRadius: 16).stroke(
                Color(red: 0.063, green: 0.725, blue: 0.506).opacity(0.3),
                style: StrokeStyle(lineWidth: 1, dash: [5, 3])
            )
        }
    }

    // MARK: - Content by context
    private var badgeText: String {
        switch context {
        case .past:    return "Mes cerrado"
        case .current: return "En curso · día \(dayOfMonth) de \(daysInMonth)"
        case .future:  return "Proyección · basada en recurrentes"
        }
    }

    private var labelText: String {
        switch context {
        case .past:    return "Balance final"
        case .current: return "Balance actual"
        case .future:  return "Balance estimado"
        }
    }

    private var subtitleText: String {
        switch context {
        case .past:    return "\(savingsPct)% de ahorro en el mes"
        case .current: return "\(savingsPct)% ahorrado hasta hoy"
        case .future:  return "si gastos variables se mantienen"
        }
    }

    // MARK: - Colors by context
    private var amountColor: Color {
        switch context {
        case .current: return .white
        case .past:    return Color.finaMutedForeground
        case .future:  return Color(red: 0.063, green: 0.725, blue: 0.506)
        }
    }

    private var labelColor: Color {
        context == .current
            ? .white.opacity(0.6)
            : Color.finaMutedForeground.opacity(0.7)
    }

    private var subtitleColor: Color {
        context == .current ? .white.opacity(0.75) : Color.finaMutedForeground
    }

    private var badgeBackground: Color {
        switch context {
        case .current: return .white.opacity(0.2)
        case .past:    return Color.finaMuted
        case .future:  return Color(red: 0.063, green: 0.725, blue: 0.506).opacity(0.12)
        }
    }

    private var badgeForeground: Color {
        switch context {
        case .current: return .white.opacity(0.9)
        case .past:    return Color.finaMutedForeground
        case .future:  return Color(red: 0.063, green: 0.725, blue: 0.506)
        }
    }

    private var badgeDotColor: Color {
        switch context {
        case .current: return .white.opacity(0.7)
        case .past:    return Color.finaMutedForeground.opacity(0.4)
        case .future:  return Color(red: 0.063, green: 0.725, blue: 0.506)
        }
    }

    private var pillBackground: Color {
        context == .current ? .white.opacity(0.18) : Color.finaMuted
    }

    private var pillForeground: Color {
        context == .current ? .white.opacity(0.85) : Color.finaMutedForeground
    }

    private var incomeDotColor: Color {
        context == .current
            ? Color(red: 0.29, green: 0.87, blue: 0.5)
            : Color.finaMutedForeground.opacity(0.4)
    }

    private var expenseDotColor: Color {
        context == .current
            ? Color(red: 0.98, green: 0.64, blue: 0.64)
            : Color.finaMutedForeground.opacity(0.4)
    }
}

// MARK: - Compact amount formatter
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
