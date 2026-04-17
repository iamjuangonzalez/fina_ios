import SwiftUI

// MARK: - CategoryBarRow
// Fila de categoría con barra horizontal proporcional y porcentaje.

struct CategoryBarRow: View {
    let stat: CategoryStat

    var body: some View {
        HStack(spacing: 10) {
            // Dot de color
            Circle()
                .fill(Color(hex: stat.color))
                .frame(width: 9, height: 9)

            // Nombre
            Text(stat.name)
                .font(.system(size: 13))
                .foregroundStyle(Color.finaForeground)
                .frame(width: 100, alignment: .leading)
                .lineLimit(1)

            // Barra
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.finaMuted)
                        .frame(height: 5)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: stat.color))
                        .frame(width: geo.size.width * stat.pct, height: 5)
                }
            }
            .frame(height: 5)

            // Porcentaje
            Text("\(Int(stat.pct * 100))%")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.finaMutedForeground)
                .frame(width: 32, alignment: .trailing)
        }
    }
}
