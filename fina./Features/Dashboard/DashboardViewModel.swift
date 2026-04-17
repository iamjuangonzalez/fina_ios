import SwiftUI
import SwiftData

// MARK: - MonthContext
// Determina qué estado muestra el dashboard según el mes navegado.
enum MonthContext {
    case past       // mes anterior al actual — cerrado
    case current    // mes de hoy — en curso
    case future     // mes posterior al actual — proyección
}

// MARK: - ProjectionData
// Datos calculados para el mes futuro.
struct ProjectionData {
    let estimatedIncome:    Double
    let scheduledFixed:     Double   // gastos recurrentes programados
    let estimatedVariable:  Double   // promedio de variables de meses pasados
    var estimatedBalance:   Double   { estimatedIncome - scheduledFixed - estimatedVariable }
    var estimatedSavingsPct: Int {
        guard estimatedIncome > 0 else { return 0 }
        return max(0, Int((estimatedBalance / estimatedIncome) * 100))
    }
    // Desglose por categoría de los fijos programados
    var fixedLines: [(label: String, amount: Double)] = []
}

// MARK: - DashboardViewModel
@MainActor
@Observable
final class DashboardViewModel {

    var transactions: [TxRecord] = []
    var isLoading = false
    var currency: String = "COP"

    private var context: ModelContext?
    private var userId: String?
    private var allTransactions: [TxRecord] = []   // cache sin filtro de mes

    private(set) var currentDate: Date = Calendar.current.startOfMonth(for: Date())

    // MARK: - Setup
    func setup(context: ModelContext, userId: String?, currency: String) {
        self.context  = context
        self.userId   = userId
        self.currency = currency
        Task { await fetchAll() }
    }

    // MARK: - Navegación de mes
    func prevMonth() {
        currentDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
        filterTransactions()
    }

    func nextMonth() {
        currentDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
        filterTransactions()
    }

    var monthName: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_CO")
        f.dateFormat = "MMMM"
        let s = f.string(from: currentDate)
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    var yearString: String {
        Calendar.current.component(.year, from: currentDate).description
    }

    // MARK: - MonthContext
    var monthContext: MonthContext {
        let cal   = Calendar.current
        let today = cal.startOfMonth(for: Date())
        if currentDate < today  { return .past }
        if currentDate > today  { return .future }
        return .current
    }

    var isCurrentMonth: Bool { monthContext == .current }

    // "2026 · hoy" solo en el mes actual
    var yearLabel: String {
        isCurrentMonth ? "\(yearString) · hoy" : yearString
    }

    // MARK: - Totales del mes visible
    var totalExpenses: Double {
        transactions.filter { $0.type == "expense" }.reduce(0) { $0 + $1.amount }
    }
    var totalIncomes: Double {
        transactions.filter { $0.type == "income" }.reduce(0) { $0 + $1.amount }
    }
    var balance: Double { totalIncomes - totalExpenses }

    var savingsPct: Int {
        guard totalIncomes > 0 else { return 0 }
        return max(0, Int(((totalIncomes - totalExpenses) / totalIncomes) * 100))
    }

    // Gasto de hoy (solo relevante en .current)
    var todayExpenses: Double {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let todayStr = df.string(from: Date())
        return transactions
            .filter { $0.type == "expense" && $0.date == todayStr }
            .reduce(0) { $0 + $1.amount }
    }

    // Categoría con más gasto del mes
    var topCategory: String? {
        let expenses = transactions.filter { $0.type == "expense" }
        guard !expenses.isEmpty else { return nil }
        return Dictionary(grouping: expenses, by: \.categoryId)
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
            .max(by: { $0.value < $1.value })?.key
    }

    // Gastos "hormiga" del mes (nature == "hormiga")
    var hormigaTotal: Double {
        transactions
            .filter { $0.type == "expense" && $0.nature == "hormiga" }
            .reduce(0) { $0 + $1.amount }
    }

    // MARK: - Upcoming payments (próximos 7 días, solo recurrentes)
    var upcomingPayments: [TxRecord] {
        guard monthContext == .current else { return [] }
        let cal = Calendar.current
        let today = Date()
        let limit = cal.date(byAdding: .day, value: 7, to: today) ?? today
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let todayStr = df.string(from: today)
        let limitStr = df.string(from: limit)

        return allTransactions
            .filter {
                $0.type == "expense" &&
                $0.frequency != "once" &&
                $0.date >= todayStr &&
                $0.date <= limitStr
            }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Projection (mes futuro)
    var projectionData: ProjectionData {
        guard monthContext == .future else {
            return ProjectionData(estimatedIncome: 0, scheduledFixed: 0, estimatedVariable: 0)
        }

        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let cal = Calendar.current

        // Ingresos: promedio de los últimos 3 meses
        let estimatedIncome = averageIncome(lastMonths: 3)

        // Gastos fijos programados para este mes (recurrentes con frequency != "once")
        let monthStr = currentMonthPrefix()   // "yyyy-MM"
        let fixedTxs = allTransactions.filter {
            $0.type == "expense" &&
            $0.frequency != "once" &&
            $0.date.hasPrefix(monthStr)
        }
        let scheduledFixed = fixedTxs.reduce(0) { $0 + $1.amount }

        // Líneas de desglose agrupadas por categoría
        let fixedLines: [(label: String, amount: Double)] = Dictionary(
            grouping: fixedTxs, by: \.categoryId
        )
        .mapValues { $0.reduce(0) { $0 + $1.amount } }
        .map { (label: $0.key, amount: $0.value) }
        .sorted { $0.amount > $1.amount }

        // Variables: promedio de los últimos 3 meses (gastos no recurrentes)
        let estimatedVariable = averageVariableExpenses(lastMonths: 3)

        return ProjectionData(
            estimatedIncome:   estimatedIncome,
            scheduledFixed:    scheduledFixed,
            estimatedVariable: estimatedVariable,
            fixedLines:        fixedLines
        )
    }

    // MARK: - Transacciones recientes (mes visible, más recientes primero)
    var recentTransactions: [TxRecord] {
        transactions.sorted { $0.date > $1.date }
    }

    // MARK: - Agrupación por fecha (para uso futuro en calendario)
    var transactionsByDate: [String: [TxRecord]] {
        Dictionary(grouping: transactions, by: \.date)
    }

    // MARK: - Totales por categoría
    struct CategoryTotal {
        let categoryId: String
        let total: Double
        let fraction: Double
    }

    var categoryTotals: [CategoryTotal] {
        let expenses = transactions.filter { $0.type == "expense" }
        var totals: [String: Double] = [:]
        for tx in expenses { totals[tx.categoryId, default: 0] += tx.amount }
        let sorted = totals.sorted { $0.value > $1.value }
        let maxVal = sorted.first?.value ?? 1
        return sorted.prefix(8).map {
            CategoryTotal(categoryId: $0.key, total: $0.value, fraction: $0.value / maxVal)
        }
    }

    // MARK: - Fetch
    func fetchAll() async {
        guard let context, let userId else { return }
        isLoading = true
        let descriptor = FetchDescriptor<TxRecord>(
            predicate: #Predicate<TxRecord> { $0.userId == userId },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        allTransactions = (try? context.fetch(descriptor)) ?? []
        filterTransactions()
        isLoading = false
    }

    // Filtra `allTransactions` al mes visible y actualiza `transactions`
    func filterTransactions() {
        let cal = Calendar.current
        let start = cal.startOfMonth(for: currentDate)
        let end   = cal.date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? start
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let startStr = df.string(from: start)
        let endStr   = df.string(from: end)
        transactions = allTransactions.filter { $0.date >= startStr && $0.date <= endStr }
    }

    // Alias para compatibilidad con sheets que llaman fetchTransactions()
    func fetchTransactions() async { await fetchAll() }

    // Expone allTransactions para TransactionDetailView (cálculo de próximo cobro)
    var allTxForDetail: [TxRecord] { allTransactions }

    // Busca el monto de la misma categoría en el mes anterior
    func previousMonthAmount(for tx: TxRecord) -> Double? {
        let cal = Calendar.current
        let df  = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        guard let txDate  = df.date(from: tx.date),
              let prevStart = cal.date(byAdding: .month, value: -1, to: cal.startOfMonth(for: txDate))
        else { return nil }
        let prevEnd = cal.date(byAdding: DateComponents(month: 1, day: -1), to: prevStart) ?? prevStart
        let s = df.string(from: prevStart)
        let e = df.string(from: prevEnd)
        let match = allTransactions.first {
            $0.categoryId == tx.categoryId &&
            $0.type       == tx.type       &&
            $0.date >= s  && $0.date <= e
        }
        return match?.amount
    }

    // MARK: - Helpers privados
    private func currentMonthPrefix() -> String {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM"
        return df.string(from: currentDate)
    }

    private func averageIncome(lastMonths: Int) -> Double {
        let cal = Calendar.current
        let df  = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        var totals: [Double] = []
        for offset in 1...lastMonths {
            guard let m = cal.date(byAdding: .month, value: -offset, to: currentDate) else { continue }
            let start = cal.startOfMonth(for: m)
            let end   = cal.date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? start
            let s = df.string(from: start); let e = df.string(from: end)
            let sum = allTransactions
                .filter { $0.type == "income" && $0.date >= s && $0.date <= e }
                .reduce(0) { $0 + $1.amount }
            totals.append(sum)
        }
        guard !totals.isEmpty else { return 0 }
        return totals.reduce(0, +) / Double(totals.count)
    }

    private func averageVariableExpenses(lastMonths: Int) -> Double {
        let cal = Calendar.current
        let df  = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        var totals: [Double] = []
        for offset in 1...lastMonths {
            guard let m = cal.date(byAdding: .month, value: -offset, to: currentDate) else { continue }
            let start = cal.startOfMonth(for: m)
            let end   = cal.date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? start
            let s = df.string(from: start); let e = df.string(from: end)
            let sum = allTransactions
                .filter { $0.type == "expense" && $0.frequency == "once" && $0.date >= s && $0.date <= e }
                .reduce(0) { $0 + $1.amount }
            totals.append(sum)
        }
        guard !totals.isEmpty else { return 0 }
        return totals.reduce(0, +) / Double(totals.count)
    }
}

// MARK: - Calendar extension
extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}
