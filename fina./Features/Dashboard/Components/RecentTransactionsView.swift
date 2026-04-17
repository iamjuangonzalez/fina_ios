import SwiftUI

// MARK: - RecentTransactionsView
// Listado de transacciones ya registradas en el mes visible.
// Ordenadas por fecha descendente.

struct RecentTransactionsView: View {
    let transactions:    [TxRecord]
    let categoryColors:  [String: String]   // categoryId → hex color
    let categoryEmojis:  [String: String]   // categoryId → emoji
    var onSelect:        ((TxRecord) -> Void)? = nil
    var onDelete:        ((TxRecord) -> Void)? = nil

    @State private var newestFirst = true
    @State private var showLimit:  Int    = 10     // 10 | 20 | 0 (todos)
    @State private var typeFilter: String = "all"  // "all" | "expense" | "income"

    private var displayed: [TxRecord] {
        let filtered = typeFilter == "all"
            ? transactions
            : transactions.filter { $0.type == typeFilter }
        let sorted = newestFirst
            ? filtered.sorted { $0.date > $1.date }
            : filtered.sorted { $0.date < $1.date }
        return showLimit == 0 ? sorted : Array(sorted.prefix(showLimit))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Header + filtros
            HStack(spacing: 6) {
                Text("RECIENTES")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.finaMutedForeground.opacity(0.6))
                    .kerning(0.8)

                Spacer()

                // Tipo
                Menu {
                    Button { withAnimation { typeFilter = "all"     } } label: { Label("Todos",    systemImage: typeFilter == "all"     ? "checkmark" : "") }
                    Button { withAnimation { typeFilter = "expense" } } label: { Label("Gastos",   systemImage: typeFilter == "expense" ? "checkmark" : "") }
                    Button { withAnimation { typeFilter = "income"  } } label: { Label("Ingresos", systemImage: typeFilter == "income"  ? "checkmark" : "") }
                } label: {
                    HStack(spacing: 4) {
                        Text(typeFilter == "expense" ? "Gastos" : typeFilter == "income" ? "Ingresos" : "Todos")
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                    }
                    .foregroundStyle(Color.finaMutedForeground)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.finaMuted)
                    .clipShape(Capsule())
                }

                // Orden
                Button {
                    withAnimation(.spring(duration: 0.2)) { newestFirst.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: newestFirst ? "arrow.down" : "arrow.up")
                            .font(.system(size: 10, weight: .semibold))
                        Text(newestFirst ? "Reciente" : "Antiguo")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(Color.finaMutedForeground)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.finaMuted)
                    .clipShape(Capsule())
                }

                // Cantidad
                Menu {
                    Button("Últimos 10")  { withAnimation { showLimit = 10 } }
                    Button("Últimos 20")  { withAnimation { showLimit = 20 } }
                    Button("Todos")       { withAnimation { showLimit = 0  } }
                } label: {
                    HStack(spacing: 4) {
                        Text(showLimit == 0 ? "Todos" : "\(showLimit)")
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                    }
                    .foregroundStyle(Color.finaMutedForeground)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.finaMuted)
                    .clipShape(Capsule())
                }
            }

            if transactions.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(displayed) { tx in
                        Button { onSelect?(tx) } label: {
                            transactionRow(tx)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                onDelete?(tx)
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(minHeight: CGFloat(displayed.count) * 72)
                .scrollDisabled(true)
            }
        }
    }

    // MARK: - Row
    private func transactionRow(_ tx: TxRecord) -> some View {
        let accentHex = tx.customColor ?? categoryColors[tx.categoryId] ?? "#888888"
        let accent    = Color(hex: accentHex)
        let emoji     = categoryEmojis[tx.categoryId] ?? ""
        let isExpense = tx.type == "expense"
        let amountColor: Color = isExpense
            ? Color(red: 0.937, green: 0.267, blue: 0.267)
            : Color(red: 0.063, green: 0.725, blue: 0.506)

        return HStack(spacing: 12) {
            // Icono de categoría
            ZStack {
                Circle()
                    .fill(accent.opacity(0.18))
                    .frame(width: 44, height: 44)
                if emoji.isEmpty {
                    BrandIconView(iconKey: tx.categoryId, emoji: "", color: accentHex, size: 22)
                } else {
                    Text(emoji)
                        .font(.system(size: 22))
                }
            }

            // Nombre + fecha
            VStack(alignment: .leading, spacing: 2) {
                Text(tx.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.finaForeground)
                    .lineLimit(1)
                Text(formattedDate(tx.date))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.finaMutedForeground)
            }

            Spacer()

            // Indicador + monto
            HStack(spacing: 4) {
                Circle()
                    .fill(amountColor)
                    .frame(width: 6, height: 6)
                Text("\(formatAmount(tx.amount, currency: tx.currency))")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.finaForeground)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.finaCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Empty state
    private var emptyState: some View {
        Text("Sin transacciones registradas este mes.")
            .font(.system(size: 13))
            .foregroundStyle(Color.finaMutedForeground)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 20)
    }

    // MARK: - Helpers
    private func formattedDate(_ dateStr: String) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "es_CO")
        guard let date = df.date(from: dateStr) else { return dateStr }

        if Calendar.current.isDateInToday(date)     { return "Hoy" }
        if Calendar.current.isDateInYesterday(date) { return "Ayer" }

        let out = DateFormatter()
        out.locale = Locale(identifier: "es_CO")
        out.dateFormat = "d MMM"
        return out.string(from: date)
    }
}

