import SwiftUI
import SwiftData

// MARK: - TransactionDetailView
// Modal de detalle de una transacción individual.

struct TransactionDetailView: View {
    @Environment(\.dismiss)      private var dismiss
    @Environment(\.modelContext) private var ctx

    let tx:               TxRecord
    let category:         CategoryRecord?
    let previousAmount:   Double?
    let allTransactions:  [TxRecord]

    @State private var showDeleteConfirm  = false
    @State private var showSeriesDialog   = false

    private var isExpense: Bool { tx.type == "expense" }

    private var amountColor: Color {
        isExpense
            ? Color(red: 0.937, green: 0.267, blue: 0.267)
            : Color(red: 0.063, green: 0.725, blue: 0.506)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        heroSection
                        infoCard
                        monaiNote
                        bottomStats

                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }

                // Footer fijo con botón eliminar
                deleteButton
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
            }
            .background(Color.finaBackground)
            .navigationTitle("Transacción")
            .navigationBarTitleDisplayMode(.inline)
            // Diálogo simple (transacción única)
            .alert("¿Eliminar transacción?", isPresented: $showDeleteConfirm) {
                Button("Eliminar", role: .destructive) { deleteTransaction() }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Esta acción no se puede deshacer.")
            }
            // Diálogo para series recurrentes
            .alert("¿Qué quieres eliminar?", isPresented: $showSeriesDialog) {
                Button("Solo esta", role: .destructive)             { deleteTransaction() }
                Button("Este y los siguientes", role: .destructive) { deleteThisAndFuture() }
                Button("Todos", role: .destructive)                 { deleteAllInSeries() }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Esta acción no se puede deshacer.")
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.finaForeground)
                            .frame(width: 32, height: 32)
                            .background(Color.finaMuted)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    // MARK: - Hero
    private var heroSection: some View {
        VStack(spacing: 12) {
            // Ícono de categoría
            let colorHex = tx.customColor ?? category?.color ?? "#888888"
            BrandIconView(
                iconKey: category?.id ?? "",
                emoji:   category?.emoji ?? "💳",
                color:   colorHex,
                size:    56
            )
            .frame(width: 72, height: 72)
            .background(Color(hex: colorHex).opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 18))

            // Nombre
            Text(tx.displayName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.finaForeground)
                .multilineTextAlignment(.center)

            // Monto
            Text("\(isExpense ? "−" : "+")\(formatAmount(tx.amount, currency: tx.currency))")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(amountColor)

            // Fecha
            Text(formattedDate(tx.date))
                .font(.system(size: 13))
                .foregroundStyle(Color.finaMutedForeground)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Info card
    private var infoCard: some View {
        VStack(spacing: 0) {
            infoRow(label: "Categoría",  value: category?.name ?? "—")
            rowDivider()
            infoRow(label: "Frecuencia", value: frequencyLabel(tx.frequency))
            rowDivider()
            infoRow(label: "Naturaleza", value: natureLabel(tx.nature))
            rowDivider()
            infoRow(label: "Tipo",       value: isExpense ? "Gasto" : "Ingreso")
        }
        .background(Color.finaCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.finaBorder, lineWidth: 1))
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Color.finaMutedForeground)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.finaForeground)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private func rowDivider() -> some View {
        Divider().padding(.leading, 16)
    }

    // MARK: - Monai note
    private var monaiNote: some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0.984, green: 0.451, blue: 0.086))
                .frame(width: 3)

            Text(monaiText)
                .font(.system(size: 13))
                .foregroundStyle(Color.finaMutedForeground)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.finaCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.finaBorder, lineWidth: 1))
    }

    private var monaiText: String {
        let catName = category?.name ?? "esta categoría"
        switch tx.frequency {
        case "monthly":
            return "fina: Este es un gasto recurrente mensual en \(catName)."
        case "yearly":
            return "fina: Este gasto anual en \(catName) equivale a \(formatAmount(tx.amount / 12, currency: tx.currency)) al mes."
        case "weekly":
            return "fina: Este gasto semanal suma \(formatAmount(tx.amount * 4, currency: tx.currency)) al mes en \(catName)."
        default:
            if tx.nature == "hormiga" {
                return "fina: Los gastos hormiga suman sin notarse. Revisa cuántos tienes este mes."
            }
            return "fina: Gasto registrado en \(catName)."
        }
    }

    // MARK: - Bottom stats
    private var bottomStats: some View {
        HStack(spacing: 10) {
            statCard(
                label: "Igual mes anterior",
                value: previousAmount.map { formatAmount($0, currency: tx.currency) } ?? "—",
                valueColor: Color.finaMutedForeground
            )
            statCard(
                label: "Próximo cobro",
                value: nextPaymentLabel,
                valueColor: nextPaymentLabel == "—"
                    ? Color.finaMutedForeground
                    : Color(red: 0.984, green: 0.451, blue: 0.086)
            )
        }
    }

    private func statCard(label: String, value: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.finaMutedForeground.opacity(0.7))
                .lineLimit(1)
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.finaCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.finaBorder, lineWidth: 1))
    }

    // MARK: - Computed helpers

    private var nextPaymentLabel: String {
        guard tx.frequency != "once" else { return "—" }
        guard let next = nextPaymentDate(from: tx.date, frequency: tx.frequency) else { return "—" }
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_CO")
        df.dateFormat = "MMM d"
        let s = df.string(from: next)
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    private func nextPaymentDate(from dateStr: String, frequency: String) -> Date? {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        guard let base = df.date(from: dateStr) else { return nil }
        let cal = Calendar.current
        switch frequency {
        case "weekly":  return cal.date(byAdding: .weekOfYear, value: 1, to: base)
        case "monthly": return cal.date(byAdding: .month, value: 1, to: base)
        case "yearly":  return cal.date(byAdding: .year,  value: 1, to: base)
        default:        return nil
        }
    }

    private func formattedDate(_ dateStr: String) -> String {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "es_CO")
        guard let date = df.date(from: dateStr) else { return dateStr }
        let out = DateFormatter()
        out.locale = Locale(identifier: "es_CO")
        out.dateFormat = "d MMM yyyy"
        return out.string(from: date)
    }

    private func frequencyLabel(_ freq: String) -> String {
        switch freq {
        case "once":    return "Una vez"
        case "daily":   return "Diario"
        case "weekly":  return "Semanal"
        case "monthly": return "Mensual"
        case "yearly":  return "Anual"
        default:        return freq
        }
    }

    private func natureLabel(_ nature: String?) -> String {
        switch nature {
        case "fixed":      return "Fijo"
        case "variable":   return "Variable"
        case "hormiga":    return "Hormiga"
        case "unexpected": return "Inesperado"
        default:           return "—"
        }
    }

    // MARK: - Delete button
    private var deleteButton: some View {
        Button {
            if tx.frequency != "once", tx.seriesId != nil, seriesSiblings.count > 1 {
                showSeriesDialog = true
            } else {
                showDeleteConfirm = true
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .medium))
                Text("Eliminar transacción")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(Color.finaDestructive)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Siblings (todos los registros de la misma serie)
    private var seriesSiblings: [TxRecord] {
        guard let sid = tx.seriesId else { return [] }
        return allTransactions.filter { $0.seriesId == sid }
    }

    // MARK: - Delete actions

    // Elimina solo este registro
    private func deleteTransaction() {
        let mctx = tx.modelContext ?? ctx
        mctx.delete(tx)
        try? mctx.save()
        dismiss()
    }

    // Elimina este y todos los que vienen después (por fecha)
    private func deleteThisAndFuture() {
        let mctx = tx.modelContext ?? ctx
        for sibling in seriesSiblings where sibling.date >= tx.date {
            mctx.delete(sibling)
        }
        try? mctx.save()
        dismiss()
    }

    // Elimina toda la serie
    private func deleteAllInSeries() {
        let mctx = tx.modelContext ?? ctx
        for sibling in seriesSiblings {
            mctx.delete(sibling)
        }
        try? mctx.save()
        dismiss()
    }
}
