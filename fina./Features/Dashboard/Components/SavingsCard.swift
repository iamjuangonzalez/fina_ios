import SwiftUI

struct SavingsCard: View {
    let savingsPct: Int
    let savingsLabel: String
    let savingsColor: Color
    let isLoading: Bool

    private let radius: CGFloat = 28
    private var circumference: CGFloat { 2 * .pi * radius }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("AHORRO DEL MES")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.finaMutedForeground)
                .kerning(1.2)
                .padding(.bottom, 16)

            HStack(spacing: 16) {
                // Donut chart
                ZStack {
                    // Track
                    Circle()
                        .stroke(Color.finaBorder, lineWidth: 7)

                    // Progress
                    Circle()
                        .trim(from: 0, to: isLoading ? 0 : CGFloat(savingsPct) / 100)
                        .stroke(
                            isLoading ? Color.finaBorder : savingsColor,
                            style: StrokeStyle(lineWidth: 7, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.6), value: savingsPct)
                }
                .frame(width: 72, height: 72)

                // Texto
                VStack(alignment: .leading, spacing: 2) {
                    if isLoading {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.finaMuted)
                            .frame(width: 80, height: 36)
                    } else {
                        Text("\(savingsPct)%")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(savingsColor)
                    }
                    Text(savingsLabel)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.finaMutedForeground)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.finaCard)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.finaBorder, lineWidth: 1))
    }
}
