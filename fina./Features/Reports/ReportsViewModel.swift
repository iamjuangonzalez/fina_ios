import SwiftUI
import SwiftData

// MARK: - Supporting types

struct MonthBarData: Identifiable {
    let id     = UUID()
    let label:    String     // "Ene", "Feb", …
    let income:   Double
    let expenses: Double
    let isCurrent: Bool
}

struct CategoryStat: Identifiable {
    let id:         String   // categoryId
    let name:       String
    let color:      String   // hex
    let total:      Double
    let pct:        Double   // 0–1 relativo al total de gastos
}

struct CategoryChange: Identifiable {
    let id:         String
    let name:       String
    let color:      String
    let prevAmount: Double
    let currAmount: Double
    var changePct:  Double {
        guard prevAmount > 0 else { return 0 }
        return ((currAmount - prevAmount) / prevAmount) * 100
    }
}

struct HormigaGroup: Identifiable {
    let id:       String   // categoryId
    let name:     String
    let color:    String
    let total:    Double
    let count:    Int
    let subtitle: String   // "14 veces este mes"
}

// MARK: - ReportsViewModel

@MainActor
@Observable
final class ReportsViewModel {

    var selectedMonth: Date = Calendar.current.startOfMonth(for: Date())
    var isLoading = false

    private var allTransactions: [TxRecord] = []
    private var categories:      [CategoryRecord] = []

    // MARK: - Setup
    func setup(context: ModelContext, userId: String?, categories: [CategoryRecord]) {
        self.categories = categories
        isLoading = true
        Task {
            let descriptor = FetchDescriptor<TxRecord>(
                predicate: #Predicate<TxRecord> { $0.userId == userId ?? "" },
                sortBy: [SortDescriptor(\.date)]
            )
            allTransactions = (try? context.fetch(descriptor)) ?? []
            isLoading = false
        }
    }

    func updateCategories(_ cats: [CategoryRecord]) {
        categories = cats
    }

    // MARK: - Month navigation
    func prevMonth() {
        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
    }
    func nextMonth() {
        selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
    }

    var monthLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_CO")
        f.dateFormat = "MMMM yyyy"
        let s = f.string(from: selectedMonth)
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    var shortMonthLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_CO")
        f.dateFormat = "MMM"
        let s = f.string(from: selectedMonth)
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    // MARK: - Current month transactions
    var monthTransactions: [TxRecord] {
        txFor(month: selectedMonth)
    }

    // MARK: - Overview stats
    var totalIncome: Double   { monthTransactions.filter { $0.type == "income"  }.reduce(0) { $0 + $1.amount } }
    var totalExpenses: Double { monthTransactions.filter { $0.type == "expense" }.reduce(0) { $0 + $1.amount } }
    var netSavings: Double    { totalIncome - totalExpenses }
    var savingsPct: Int {
        guard totalIncome > 0 else { return 0 }
        return max(0, Int((netSavings / totalIncome) * 100))
    }

    var dailyAvgExpense: Double {
        let cal  = Calendar.current
        let days = cal.range(of: .day, in: .month, for: selectedMonth)?.count ?? 30
        guard days > 0 else { return 0 }
        return totalExpenses / Double(days)
    }

    // % cambio vs mes anterior
    var incomePctChange: Double  { pctChange(current: totalIncome,   prev: prevMonthIncome) }
    var expensePctChange: Double { pctChange(current: totalExpenses,  prev: prevMonthExpenses) }

    private var prevMonthIncome: Double {
        guard let prev = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) else { return 0 }
        return txFor(month: prev).filter { $0.type == "income" }.reduce(0) { $0 + $1.amount }
    }
    private var prevMonthExpenses: Double {
        guard let prev = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) else { return 0 }
        return txFor(month: prev).filter { $0.type == "expense" }.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Last 6 months bar chart
    var last6MonthsData: [MonthBarData] {
        let cal = Calendar.current
        let f   = DateFormatter()
        f.locale = Locale(identifier: "es_CO")
        f.dateFormat = "MMM"

        return (0..<6).reversed().compactMap { offset -> MonthBarData? in
            guard let m = cal.date(byAdding: .month, value: -offset, to: selectedMonth) else { return nil }
            let txs  = txFor(month: m)
            let inc  = txs.filter { $0.type == "income"  }.reduce(0) { $0 + $1.amount }
            let exp  = txs.filter { $0.type == "expense" }.reduce(0) { $0 + $1.amount }
            let label = String(f.string(from: m).prefix(3))
            let isCurrent = cal.isDate(m, equalTo: selectedMonth, toGranularity: .month)
            return MonthBarData(label: label.prefix(1).uppercased() + label.dropFirst(),
                                income: inc, expenses: exp, isCurrent: isCurrent)
        }
    }

    // MARK: - Category breakdown
    var categoryStats: [CategoryStat] {
        let expenses = monthTransactions.filter { $0.type == "expense" }
        let total    = expenses.reduce(0) { $0 + $1.amount }
        guard total > 0 else { return [] }

        var grouped: [String: Double] = [:]
        for tx in expenses { grouped[tx.categoryId, default: 0] += tx.amount }

        return grouped
            .sorted { $0.value > $1.value }
            .prefix(6)
            .map { catId, amount in
                let cat = categories.first { $0.id == catId }
                return CategoryStat(
                    id:    catId,
                    name:  cat?.name ?? catId.capitalized,
                    color: cat?.color ?? "#888888",
                    total: amount,
                    pct:   amount / total
                )
            }
    }

    // MARK: - Trends: cambios significativos
    var significantChanges: [CategoryChange] {
        guard let prev = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) else { return [] }
        let prevTxs  = txFor(month: prev).filter { $0.type == "expense" }
        let currTxs  = monthTransactions.filter  { $0.type == "expense" }

        var prevByCategory: [String: Double] = [:]
        var currByCategory: [String: Double] = [:]
        for tx in prevTxs { prevByCategory[tx.categoryId, default: 0] += tx.amount }
        for tx in currTxs { currByCategory[tx.categoryId, default: 0] += tx.amount }

        let allCats = Set(prevByCategory.keys).union(currByCategory.keys)
        return allCats.compactMap { catId -> CategoryChange? in
            let prev = prevByCategory[catId] ?? 0
            let curr = currByCategory[catId] ?? 0
            guard prev > 0 || curr > 0 else { return nil }
            let cat = categories.first { $0.id == catId }
            return CategoryChange(
                id:         catId,
                name:       cat?.name ?? catId.capitalized,
                color:      cat?.color ?? "#888888",
                prevAmount: prev,
                currAmount: curr
            )
        }
        .sorted { abs($0.changePct) > abs($1.changePct) }
        .prefix(4)
        .filter { abs($0.changePct) >= 5 }   // solo cambios relevantes
    }

    var prevMonthShortLabel: String {
        guard let prev = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) else { return "ant." }
        let f = DateFormatter(); f.locale = Locale(identifier: "es_CO"); f.dateFormat = "MMM"
        let s = f.string(from: prev)
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    // MARK: - Hormiga groups
    var hormigaGroups: [HormigaGroup] {
        let txs = monthTransactions.filter { $0.type == "expense" && $0.nature == "hormiga" }
        var grouped: [String: [TxRecord]] = [:]
        for tx in txs { grouped[tx.categoryId, default: []].append(tx) }

        return grouped
            .map { catId, txs in
                let cat   = categories.first { $0.id == catId }
                let total = txs.reduce(0) { $0 + $1.amount }
                let count = txs.count
                return HormigaGroup(
                    id:       catId,
                    name:     cat?.name ?? catId.capitalized,
                    color:    cat?.color ?? "#F97316",
                    total:    total,
                    count:    count,
                    subtitle: "\(count) \(count == 1 ? "vez" : "veces") este mes"
                )
            }
            .sorted { $0.total > $1.total }
    }

    // MARK: - Projection
    var projectedBalance: Double {
        guard totalIncome > 0 else { return 0 }
        let cal      = Calendar.current
        let today    = cal.component(.day, from: Date())
        let daysTotal = cal.range(of: .day, in: .month, for: selectedMonth)?.count ?? 30
        guard today > 0 else { return netSavings }
        let dailyRate = totalExpenses / Double(today)
        let projectedExpenses = dailyRate * Double(daysTotal)
        return totalIncome - projectedExpenses
    }

    var remainingExpenses: Double {
        let cal      = Calendar.current
        let today    = cal.component(.day, from: Date())
        let daysTotal = cal.range(of: .day, in: .month, for: selectedMonth)?.count ?? 30
        guard today > 0 else { return 0 }
        let dailyRate = totalExpenses / Double(today)
        return dailyRate * Double(daysTotal - today)
    }

    var daysRemaining: Int {
        let cal      = Calendar.current
        let today    = cal.component(.day, from: Date())
        let daysTotal = cal.range(of: .day, in: .month, for: selectedMonth)?.count ?? 30
        return max(0, daysTotal - today)
    }

    // Fracción real (gastado hasta hoy / proyección total)
    var realFraction: Double {
        let proj = totalExpenses + remainingExpenses
        guard proj > 0 else { return 0 }
        return min(1, totalExpenses / proj)
    }

    // MARK: - Helpers
    private func txFor(month: Date) -> [TxRecord] {
        let cal   = Calendar.current
        let start = cal.startOfMonth(for: month)
        let end   = cal.date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? start
        let df    = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let s = df.string(from: start)
        let e = df.string(from: end)
        return allTransactions.filter { $0.date >= s && $0.date <= e }
    }

    private func pctChange(current: Double, prev: Double) -> Double {
        guard prev > 0 else { return 0 }
        return ((current - prev) / prev) * 100
    }
}
