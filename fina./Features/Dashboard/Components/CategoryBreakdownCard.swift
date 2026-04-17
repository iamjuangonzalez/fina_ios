import SwiftUI

// MARK: - CategoryBreakdownCard
// Barras verticales por categoría usando el color real de cada una.
// Scroll horizontal cuando hay muchas categorías.

/*  
struct CategoryBreakdownCard: View {
    let totals:     [CategoryTotal]
    let categories: [String: CategoryRecord]   // lookup id → record
    let currency:   String

    private let BAR_MAX: CGFloat = 110
    private let BAR_W:   CGFloat = 40
    private let ICON_W:  CGFloat = 40

    var body: some View {
        Group {
            if totals.isEmpty {
                HStack {
                    Spacer()
                    Text("Sin gastos este mes")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.finaMutedForeground)
                        .padding(.vertical, 40)
                    Spacer()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 14) {
                        ForEach(totals, id: \.categoryId) { item in
                            categoryColumn(item)
                        }
                    }
                    .padding(.horizontal, 4)
                    .frame(minHeight: BAR_MAX + 72)
                }
            }
        }
    } */

    // MARK: Columna individual
    /* private func categoryColumn(_ item: CategoryTotal) -> some View {
        let cat      = categories[item.categoryId]
        let catColor = Color(hex: cat?.color ?? "#888888")

        return VStack(spacing: 0) {
            // Monto encima de la barra (solo cuando es el más alto o todos)
            Text(compactAmount(item.total))
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(catColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: ICON_W)
                .padding(.bottom, 4)

            // Barra — color pastel (sin fondo de restante)
            RoundedRectangle(cornerRadius: 10)
                .fill(catColor.opacity(0.38))
                .frame(width: BAR_W, height: max(10, item.fraction * BAR_MAX))
                .animation(.spring(duration: 0.5), value: item.fraction)

            // Ícono de categoría
            BrandIconView(
                iconKey: item.categoryId,
                emoji:   cat?.emoji ?? "💸",
                color:   cat?.color ?? "#888888",
                size:    ICON_W
            )
            .padding(.top, 8)

            // Nombre
            Text(cat?.name ?? item.categoryId)
                .font(.system(size: 10))
                .foregroundStyle(Color.finaMutedForeground)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: ICON_W)
                .padding(.top, 4)
        }
        .frame(width: ICON_W)
    }

    // MARK: Formato compacto
    private func compactAmount(_ v: Double) -> String {
        if v >= 1_000_000 { return String(format: "%.1fM", v / 1_000_000) }
        if v >= 1_000     { return String(format: "%.0fK", v / 1_000) }
        return "\(Int(v))"
    }
}

 */