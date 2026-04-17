import SwiftUI

// MARK: - TrendsReportTab
// Tendencias: cambios significativos por categoría y gastos hormiga.

struct TrendsReportTab: View {
    let vm:       ReportsViewModel
    let currency: String

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {

                significantChangesCard
                hormigaCard
                monaiNote

            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Cambios significativos
    private var significantChangesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("CAMBIOS SIGNIFICATIVOS")
                .padding(.bottom, 10)

            if vm.significantChanges.isEmpty {
                Text("Sin cambios significativos respecto al mes anterior.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.finaMutedForeground)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(vm.significantChanges.enumerated()), id: \.element.id) { i, change in
                        if i > 0 { Divider().padding(.leading, 42) }
                        changeRow(change)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.finaCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.finaBorder, lineWidth: 1))
    }

    private func changeRow(_ change: CategoryChange) -> some View {
        HStack(spacing: 12) {
            // Ícono de categoría
            Circle()
                .fill(Color(hex: change.color).opacity(0.15))
                .frame(width: 32, height: 32)
                .overlay(
                    Circle().fill(Color(hex: change.color)).frame(width: 10, height: 10)
                )

            // Nombre + montos
            VStack(alignment: .leading, spacing: 2) {
                Text(change.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.finaForeground)
                HStack(spacing: 4) {
                    Text(formatCompact(change.prevAmount, currency: currency))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.finaMutedForeground)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.finaMutedForeground)
                    Text(formatCompact(change.currAmount, currency: currency))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.finaMutedForeground)
                }
            }

            Spacer()

            // Badge de cambio %
            let pct = change.changePct
            Text("\(pct >= 0 ? "+" : "")\(Int(pct))%")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(pct > 0
                    ? Color(red: 0.937, green: 0.267, blue: 0.267)
                    : Color(red: 0.063, green: 0.725, blue: 0.506))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background((pct > 0
                    ? Color(red: 0.937, green: 0.267, blue: 0.267)
                    : Color(red: 0.063, green: 0.725, blue: 0.506)).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.vertical, 10)
    }

    // MARK: - Gastos hormiga
    private var hormigaCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("GASTOS HORMIGA DETECTADOS")
                .padding(.bottom, 10)

            if vm.hormigaGroups.isEmpty {
                Text("No se detectaron gastos hormiga este mes.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.finaMutedForeground)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(vm.hormigaGroups.enumerated()), id: \.element.id) { i, group in
                        if i > 0 { Divider().padding(.leading, 42) }
                        hormigaRow(group)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.finaCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.finaBorder, lineWidth: 1))
    }

    private func hormigaRow(_ group: HormigaGroup) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: group.color))
                .frame(width: 10, height: 10)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.finaForeground)
                Text(group.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.finaMutedForeground)
            }

            Spacer()

            Text("$\(formatCompact(group.total, currency: currency))")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(red: 0.984, green: 0.451, blue: 0.086))
        }
        .padding(.vertical, 10)
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
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.finaCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.finaBorder, lineWidth: 1))
    }

    private var monaiText: String {
        if let top = vm.hormigaGroups.first {
            return "fina: \"\(top.name)\" es tu mayor gasto hormiga con $\(formatCompact(top.total, currency: currency)) este mes. Pequeños recortes aquí generan grandes diferencias al cierre."
        }
        if let topChange = vm.significantChanges.first, topChange.changePct > 20 {
            return "fina: \"\(topChange.name)\" subió un \(Int(topChange.changePct))% vs el mes anterior. Vale la pena revisarlo."
        }
        return "fina: No se detectaron anomalías importantes este mes. Sigue así."
    }

    // MARK: - Helpers
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(Color.finaMutedForeground.opacity(0.6))
            .kerning(0.7)
    }
}

private func formatCompact(_ amount: Double, currency: String) -> String {
    let divisor: Double; let suffix: String
    switch currency {
    case "COP", "CLP", "ARS":
        if amount >= 1_000_000 { divisor = 1_000_000; suffix = "M" }
        else                   { divisor = 1_000;     suffix = "k" }
    default:
        if amount >= 1_000     { divisor = 1_000;     suffix = "k" }
        else                   { divisor = 1;         suffix = "" }
    }
    let val = amount / divisor
    let fmt = val.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(val)) : String(format: "%.1f", val)
    return "\(fmt)\(suffix)"
}
