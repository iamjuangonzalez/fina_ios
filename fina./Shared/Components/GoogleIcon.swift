import SwiftUI

// Ícono de Google construido con las mismas rutas SVG que el RN
struct GoogleIcon: View {
    var size: CGFloat = 18

    var body: some View {
        Canvas { ctx, _ in
            // Escalar de 24x24 (viewBox original) a `size`
            let s = size / 24

            // Azul — parte superior derecha
            var p1 = Path()
            p1.move(to: CGPoint(x: 22.56 * s, y: 12.25 * s))
            p1.addCurve(
                to: CGPoint(x: 12 * s, y: 10 * s),
                control1: CGPoint(x: 22.49 * s, y: 11.47 * s),
                control2: CGPoint(x: 17.8 * s, y: 10 * s)
            )
            p1.addLine(to: CGPoint(x: 12 * s, y: 14.26 * s))
            p1.addLine(to: CGPoint(x: 17.92 * s, y: 14.26 * s))
            p1.addCurve(
                to: CGPoint(x: 15.71 * s, y: 17.57 * s),
                control1: CGPoint(x: 17.66 * s, y: 15.63 * s),
                control2: CGPoint(x: 16.88 * s, y: 16.79 * s)
            )
            p1.addLine(to: CGPoint(x: 19.28 * s, y: 20.34 * s))
            p1.addCurve(
                to: CGPoint(x: 22.56 * s, y: 12.25 * s),
                control1: CGPoint(x: 21.36 * s, y: 18.26 * s),
                control2: CGPoint(x: 22.56 * s, y: 15.44 * s)
            )
            ctx.fill(p1, with: .color(Color(red: 0.259, green: 0.522, blue: 0.957)))

            // Verde — parte inferior derecha
            var p2 = Path()
            p2.move(to: CGPoint(x: 12 * s, y: 23 * s))
            p2.addCurve(
                to: CGPoint(x: 19.28 * s, y: 20.34 * s),
                control1: CGPoint(x: 14.97 * s, y: 23 * s),
                control2: CGPoint(x: 17.46 * s, y: 22.02 * s)
            )
            p2.addLine(to: CGPoint(x: 15.71 * s, y: 17.57 * s))
            p2.addCurve(
                to: CGPoint(x: 12 * s, y: 18.63 * s),
                control1: CGPoint(x: 14.73 * s, y: 18.23 * s),
                control2: CGPoint(x: 13.48 * s, y: 18.63 * s)
            )
            p2.addCurve(
                to: CGPoint(x: 5.84 * s, y: 14.1 * s),
                control1: CGPoint(x: 9.14 * s, y: 18.63 * s),
                control2: CGPoint(x: 6.71 * s, y: 16.7 * s)
            )
            p2.addLine(to: CGPoint(x: 2.18 * s, y: 16.93 * s))
            p2.addCurve(
                to: CGPoint(x: 12 * s, y: 23 * s),
                control1: CGPoint(x: 3.99 * s, y: 20.53 * s),
                control2: CGPoint(x: 7.7 * s, y: 23 * s)
            )
            ctx.fill(p2, with: .color(Color(red: 0.204, green: 0.659, blue: 0.325)))

            // Amarillo — parte izquierda
            var p3 = Path()
            p3.move(to: CGPoint(x: 5.84 * s, y: 14.09 * s))
            p3.addCurve(
                to: CGPoint(x: 5.49 * s, y: 12 * s),
                control1: CGPoint(x: 5.62 * s, y: 13.43 * s),
                control2: CGPoint(x: 5.49 * s, y: 12.73 * s)
            )
            p3.addCurve(
                to: CGPoint(x: 5.84 * s, y: 9.91 * s),
                control1: CGPoint(x: 5.49 * s, y: 11.27 * s),
                control2: CGPoint(x: 5.62 * s, y: 10.57 * s)
            )
            p3.addLine(to: CGPoint(x: 2.18 * s, y: 7.07 * s))
            p3.addCurve(
                to: CGPoint(x: 2.18 * s, y: 16.93 * s),
                control1: CGPoint(x: 1.43 * s, y: 8.55 * s),
                control2: CGPoint(x: 1.43 * s, y: 15.45 * s)
            )
            ctx.fill(p3, with: .color(Color(red: 0.984, green: 0.737, blue: 0.02)))

            // Rojo — parte superior izquierda
            var p4 = Path()
            p4.move(to: CGPoint(x: 12 * s, y: 5.38 * s))
            p4.addCurve(
                to: CGPoint(x: 16.21 * s, y: 7.02 * s),
                control1: CGPoint(x: 13.62 * s, y: 5.38 * s),
                control2: CGPoint(x: 15.06 * s, y: 5.94 * s)
            )
            p4.addLine(to: CGPoint(x: 19.36 * s, y: 3.87 * s))
            p4.addCurve(
                to: CGPoint(x: 12 * s, y: 1 * s),
                control1: CGPoint(x: 17.45 * s, y: 2.09 * s),
                control2: CGPoint(x: 14.97 * s, y: 1 * s)
            )
            p4.addCurve(
                to: CGPoint(x: 2.18 * s, y: 7.07 * s),
                control1: CGPoint(x: 7.7 * s, y: 1 * s),
                control2: CGPoint(x: 3.99 * s, y: 3.47 * s)
            )
            p4.addLine(to: CGPoint(x: 5.84 * s, y: 9.91 * s))
            p4.addCurve(
                to: CGPoint(x: 12 * s, y: 5.38 * s),
                control1: CGPoint(x: 7.14 * s, y: 7.31 * s),
                control2: CGPoint(x: 9.38 * s, y: 5.38 * s)
            )
            ctx.fill(p4, with: .color(Color(red: 0.918, green: 0.263, blue: 0.208)))
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    GoogleIcon(size: 24)
        .padding()
}
