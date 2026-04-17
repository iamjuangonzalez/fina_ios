import SwiftUI

// MARK: - MonaiNoteView
// Strip con barra izquierda de color y texto generado por Monai (o placeholder).

struct MonaiNoteView: View {
    let context: MonthContext
    let note: String          // texto a mostrar

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Barra lateral
            RoundedRectangle(cornerRadius: 2)
                .fill(barColor)
                .frame(width: 2)

            // Texto
            Text(note)
                .font(.system(size: 10))
                .foregroundStyle(Color.finaMutedForeground)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(Color.finaCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.finaBorder, lineWidth: 1))
    }

    private var barColor: Color {
        switch context {
        case .current: return Color(red: 0.984, green: 0.451, blue: 0.086)   // naranja fina
        case .past:    return Color.finaMutedForeground.opacity(0.35)
        case .future:  return Color(red: 0.984, green: 0.451, blue: 0.086).opacity(0.5)
        }
    }
}

// MARK: - Default note generator
// Genera el texto de Monai cuando no hay uno personalizado desde el backend.

extension MonaiNoteView {
    static func defaultNote(
        context: MonthContext,
        monthName: String,
        savingsPct: Int,
        topCategory: String?,
        projection: ProjectionData?
    ) -> String {
        switch context {
        case .past:
            let top = topCategory?.capitalized ?? "varios rubros"
            return "\(monthName) cerrado. Tu mayor categoría de gasto fue \(top). Ahorraste \(savingsPct)% del ingreso del mes."

        case .current:
            if savingsPct >= 30 {
                return "fina: Vas muy bien este mes. Mantén el ritmo y podrías superar tu récord de ahorro."
            } else if savingsPct > 0 {
                return "fina: Llevas \(savingsPct)% de ahorro. Revisa tus gastos hormiga para mejorar el cierre del mes."
            } else {
                return "fina: Tus gastos superan los ingresos registrados hasta hoy. Registra tus ingresos si faltan."
            }

        case .future:
            let est = projection?.estimatedSavingsPct ?? 0
            return "Basado en tus recurrentes programados + promedio de variables de los últimos 3 meses. Ahorro estimado: \(est)%."
        }
    }
}
