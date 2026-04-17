import SwiftUI

// MARK: - Text Field
struct FinaTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.poppins(.regular, size: 14))
                    .foregroundStyle(Color.finaMutedForeground.opacity(0.55))
                    .padding(.horizontal, 14)
                    .allowsHitTesting(false)
            }
            TextField("", text: $text)
                .font(.poppins(.regular, size: 14))
                .foregroundStyle(Color.finaForeground)
                .tint(Color.finaPrimary)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
                .padding(.horizontal, 14)
        }
        .frame(height: 44)
        .background(Color.finaMuted)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.finaBorder, lineWidth: 1))
    }
}

// MARK: - Secure Field
struct FinaSecureField: View {
    let placeholder: String
    @Binding var text: String
    @State private var isVisible = false

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.poppins(.regular, size: 14))
                    .foregroundStyle(Color.finaMutedForeground.opacity(0.55))
                    .padding(.horizontal, 14)
                    .allowsHitTesting(false)
            }
            HStack {
                if isVisible {
                    TextField("", text: $text)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } else {
                    SecureField("", text: $text)
                }
                Button {
                    isVisible.toggle()
                } label: {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                        .foregroundStyle(Color.finaMutedForeground)
                        .font(.system(size: 16))
                }
            }
            .font(.poppins(.regular, size: 14))
            .foregroundStyle(Color.finaForeground)
            .tint(Color.finaPrimary)
            .padding(.horizontal, 14)
        }
        .frame(height: 44)
        .background(Color.finaMuted)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.finaBorder, lineWidth: 1))
    }
}
