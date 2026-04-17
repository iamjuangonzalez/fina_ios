import SwiftUI

// MARK: - BrandIconView
// Muestra el logo de una marca/categoría.
// Si existe un Image Asset con nombre `iconKey` en xcassets, lo usa.
// Si no, cae en el emoji de fallback.
//
// Para agregar un nuevo logo:
//   1. Agrega el SVG en Assets.xcassets/<iconKey>.imageset/
//   2. En Contents.json pon "preserves-vector-representation": true
//   3. Listo — BrandIconView lo pica automáticamente por su iconKey.

struct BrandIconView: View {
    let iconKey: String   // id del catálogo (ej. "netflix") — debe coincidir con el nombre del imageset
    let emoji: String     // fallback cuando no hay asset
    let color: String     // hex del color de marca — se usa para el fondo de la burbuja
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(Color(hex: color).opacity(0.15))
                .frame(width: size, height: size)

            if UIImage(named: iconKey) != nil {
                Image(iconKey)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.62, height: size * 0.62)
            } else {
                Text(emoji)
                    .font(.system(size: size * 0.48))
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 24) {
        // Con asset (SVG en xcassets)
        HStack(spacing: 16) {
            BrandIconView(iconKey: "netflix", emoji: "🎬", color: "#E50914", size: 52)
            BrandIconView(iconKey: "spotify", emoji: "🎵", color: "#1DB954", size: 52)
            BrandIconView(iconKey: "notion",  emoji: "📝", color: "#000000", size: 52)
            BrandIconView(iconKey: "figma",   emoji: "🎨", color: "#F24E1E", size: 52)
        }
        // Sin asset → emoji fallback
        HStack(spacing: 16) {
            BrandIconView(iconKey: "fake_key_1", emoji: "🍔", color: "#F97316", size: 52)
            BrandIconView(iconKey: "fake_key_2", emoji: "🚗", color: "#3B82F6", size: 52)
            BrandIconView(iconKey: "fake_key_3", emoji: "🏠", color: "#F59E0B", size: 52)
        }
    }
    .padding()
    .background(Color(.systemBackground))
}
