import SwiftUI

struct BalanceCard: View {
    let balance: Double
    let savingsPct: Int
    let currency: String
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("BALANCE")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.finaBackground.opacity(0.5))
                .kerning(1)

            if isLoading {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.finaMuted.opacity(0.3))
                    .frame(width: 130, height: 32)
            } else {
                Text(formatAmount(abs(balance), currency: currency))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.finaSavingsGood)
            }

            if savingsPct > 0 {
                Text("\(savingsPct)% guardado este mes")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.finaBackground.opacity(0.4))
            } else {
                Text("Sin ahorro este mes")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.finaBackground.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.finaForeground)
        .cornerRadius(16)
    }
}
