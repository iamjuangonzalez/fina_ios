import SwiftUI
import SwiftData

private let WEEKDAYS = ["L", "M", "X", "J", "V", "S", "D"]
private let GAP: CGFloat = 4

// MARK: - Frequency dot color
private func freqColor(_ freq: String) -> Color {
    switch freq {
    case "monthly": Color(red: 0.984, green: 0.573, blue: 0.235)
    case "yearly":  Color(red: 0.063, green: 0.725, blue: 0.506)
    case "weekly":  Color(red: 0.984, green: 0.753, blue: 0.141)
    default:        Color(red: 0.376, green: 0.647, blue: 0.980)
    }
}

// MARK: - Calendar day cell
private struct DayCell: View {
    let day: Date
    let currentMonth: Date
    let txs: [TxRecord]
    let categories: [String: CategoryRecord]
    let onTap: () -> Void

    private var cal: Calendar { .current }
    private var inMonth:  Bool { cal.isDate(day, equalTo: currentMonth, toGranularity: .month) }
    private var isToday:  Bool { cal.isDateInToday(day) }
    private var dayNum:   String { "\(cal.component(.day, from: day))" }

    private var firstTx:    TxRecord? { txs.first }
    private var extraCount: Int       { max(0, txs.count - 1) }
    private var hasExpenses: Bool     { txs.contains { $0.type == "expense" } }
    private var hasIncomes:  Bool     { txs.contains { $0.type == "income" } }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if inMonth {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isToday ? Color.finaMuted : Color.finaCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isToday ? Color.finaMutedForeground : Color.finaBorder,
                                        lineWidth: 1)
                        )
                }

                if inMonth {
                    VStack(spacing: 0) {
                        // Número de día
                        Text(dayNum)
                            .font(.system(size: 11, weight: isToday ? .bold : .medium))
                            .foregroundStyle(isToday ? Color.finaForeground : Color.finaMutedForeground)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 4)
                            .padding(.top, 4)

                        Spacer(minLength: 0)

                        // Ícono de primera transacción usando BrandIconView
                        if let tx = firstTx {
                            let cat = categories[tx.categoryId]
                            BrandIconView(
                                iconKey: tx.categoryId,
                                emoji:   cat?.emoji ?? "💸",
                                color:   cat?.color ?? "#888888",
                                size:    24
                            )
                            // Frequency dot — esquina superior izquierda del ícono
                            .overlay(alignment: .topLeading) {
                                Circle()
                                    .fill(freqColor(tx.frequency))
                                    .frame(width: 6, height: 6)
                                    .overlay(Circle().stroke(Color.finaBackground, lineWidth: 1))
                                    .offset(x: -3, y: -3)
                            }
                            // +N badge — esquina superior derecha
                            .overlay(alignment: .topTrailing) {
                                if extraCount > 0 {
                                    Text("+\(extraCount)")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundStyle(Color.finaBackground)
                                        .padding(.horizontal, 3).padding(.vertical, 1)
                                        .background(Color.finaForeground)
                                        .clipShape(Capsule())
                                        .offset(x: 6, y: -4)
                                }
                            }
                        }

                        // Dots bar (expense / income)
                        if !txs.isEmpty {
                            HStack(spacing: 2) {
                                if hasExpenses {
                                    Circle()
                                        .fill(Color.finaSavingsBad)
                                        .frame(width: 4, height: 4)
                                }
                                if hasIncomes {
                                    Circle()
                                        .fill(Color.finaSavingsGood)
                                        .frame(width: 4, height: 4)
                                }
                            }
                            .padding(.bottom, 4)
                        } else {
                            Spacer(minLength: 7)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .opacity(inMonth ? 1 : 0)
        .disabled(!inMonth)
        .frame(height: 58)
    }
}

// MARK: - Day detail sheet
private struct DayDetailSheet: View {
    let date: Date
    let txs: [TxRecord]
    let categories: [String: CategoryRecord]

    @Environment(\.dismiss)   private var dismiss
    @AppStorage("appCurrency") private var currency: String = "COP"

    private var dateHeader: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "es_CO")
        fmt.dateFormat = "EEEE d 'de' MMMM"
        let s = fmt.string(from: date)
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    private var totalExpenses: Double { txs.filter { $0.type == "expense" }.reduce(0) { $0 + $1.amount } }
    private var totalIncomes:  Double { txs.filter { $0.type == "income"  }.reduce(0) { $0 + $1.amount } }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // Totales del día
                    if !txs.isEmpty {
                        HStack(spacing: 12) {
                            if totalExpenses > 0 {
                                summaryPill(label: "Gastos",
                                            amount: totalExpenses,
                                            color: Color.finaSavingsBad)
                            }
                            if totalIncomes > 0 {
                                summaryPill(label: "Ingresos",
                                            amount: totalIncomes,
                                            color: Color.finaSavingsGood)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    }

                    // Lista de transacciones
                    if txs.isEmpty {
                        VStack(spacing: 8) {
                            Text("Sin movimientos")
                                .font(.system(size: 15))
                                .foregroundStyle(Color.finaMutedForeground)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        VStack(spacing: 1) {
                            ForEach(txs) { tx in
                                txRow(tx)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.finaBorder, lineWidth: 1))
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 40)
                }
            }
            .background(Color.finaBackground)
            .navigationTitle(dateHeader)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Color.finaForeground)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: Transaction row
    private func txRow(_ tx: TxRecord) -> some View {
        let cat      = categories[tx.categoryId]
        let isExpense = tx.type == "expense"
        let amtColor  = isExpense ? Color.finaSavingsBad : Color.finaSavingsGood
        let sign      = isExpense ? "-" : "+"

        return HStack(spacing: 12) {
            BrandIconView(
                iconKey: tx.categoryId,
                emoji:   cat?.emoji ?? "💸",
                color:   cat?.color ?? "#888888",
                size:    40
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(tx.displayName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.finaForeground)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let catName = cat?.name {
                        Text(catName)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.finaMutedForeground)
                    }
                    if tx.frequency != "once" {
                        freqBadge(tx.frequency)
                    }
                    if let nature = tx.nature {
                        natureBadge(nature)
                    }
                }
            }

            Spacer()

            Text("\(sign)\(formatAmount(tx.amount))")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(amtColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.finaCard)
    }

    private func freqBadge(_ freq: String) -> some View {
        let labels = ["weekly":"Semanal","monthly":"Mensual","yearly":"Anual"]
        return Text(labels[freq] ?? freq)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(freqColor(freq))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(freqColor(freq).opacity(0.12))
            .clipShape(Capsule())
    }

    private func natureBadge(_ nature: String) -> some View {
        let map: [String: (label: String, color: Color)] = [
            "fixed":      ("Fijo",      Color.finaSavingsGood),
            "variable":   ("Variable",  Color(red: 0.376, green: 0.647, blue: 0.980)),
            "hormiga":    ("Hormiga",   Color(red: 0.984, green: 0.753, blue: 0.141)),
            "unexpected": ("Imprevisto",Color.finaSavingsBad),
        ]
        guard let info = map[nature] else { return AnyView(EmptyView()) }
        return AnyView(
            Text(info.label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(info.color)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(info.color.opacity(0.12))
                .clipShape(Capsule())
        )
    }

    private func summaryPill(label: String, amount: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color.opacity(0.8))
                .kerning(0.5)
            Text(formatAmount(amount))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.2), lineWidth: 1))
    }

    private func formatAmount(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = v.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        f.groupingSeparator = "."
        return "\(currency) \(f.string(from: NSNumber(value: v)) ?? "\(v)")"
    }
}

// MARK: - Main calendar
struct ExpenseCalendar: View {
    let currentDate: Date
    let transactionsByDate: [String: [TxRecord]]

    @Query(filter: #Predicate<CategoryRecord> { !$0.isDeleted })
    private var categoriesArr: [CategoryRecord]

    @State private var selectedDate: Date? = nil

    private var categoryById: [String: CategoryRecord] {
        Dictionary(uniqueKeysWithValues: categoriesArr.map { ($0.id, $0) })
    }

    private let df: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private var selectedTxs: [TxRecord] {
        guard let d = selectedDate else { return [] }
        return transactionsByDate[df.string(from: d)] ?? []
    }

    private var gridDays: [[Date]] {
        let cal = Calendar.current
        let start = cal.startOfMonth(for: currentDate)

        var startWeekday = cal.component(.weekday, from: start)
        startWeekday = startWeekday == 1 ? 7 : startWeekday - 1
        let gridStart = cal.date(byAdding: .day, value: -(startWeekday - 1), to: start)!

        var endComps = cal.dateComponents([.year, .month], from: currentDate)
        endComps.month! += 1
        endComps.day = 0
        let endOfMonth = cal.date(from: endComps)!
        var endWeekday = cal.component(.weekday, from: endOfMonth)
        endWeekday = endWeekday == 1 ? 7 : endWeekday - 1
        let daysToAdd = endWeekday == 7 ? 0 : 7 - endWeekday
        let gridEnd = cal.date(byAdding: .day, value: daysToAdd, to: endOfMonth)!

        var days: [Date] = []
        var cur = gridStart
        while cur <= gridEnd {
            days.append(cur)
            cur = cal.date(byAdding: .day, value: 1, to: cur)!
        }
        return stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<min($0+7, days.count)]) }
    }

    var body: some View {
        VStack(spacing: GAP) {
            // Cabecera días
            HStack(spacing: GAP) {
                ForEach(WEEKDAYS, id: \.self) { d in
                    Text(d)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.finaMutedForeground)
                        .frame(maxWidth: .infinity)
                }
            }

            // Filas
            ForEach(Array(gridDays.enumerated()), id: \.offset) { _, week in
                HStack(spacing: GAP) {
                    ForEach(week, id: \.self) { day in
                        let key = df.string(from: day)
                        DayCell(
                            day:        day,
                            currentMonth: currentDate,
                            txs:        transactionsByDate[key] ?? [],
                            categories: categoryById,
                            onTap:      { selectedDate = day }
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .sheet(item: $selectedDate) { date in
            DayDetailSheet(
                date:       date,
                txs:        transactionsByDate[df.string(from: date)] ?? [],
                categories: categoryById
            )
        }
    }
}

// MARK: - Date: Identifiable (para sheet(item:))
extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}
