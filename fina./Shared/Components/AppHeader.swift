import SwiftUI

struct AppHeader: View {
    @Environment(AuthManager.self) private var auth
    @State private var settingsOpen = false

    var body: some View {
        HStack(spacing: 10) {
            // Logo
            Text("fina")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.finaForeground)
            + Text(".")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color(red: 0.984, green: 0.451, blue: 0.086))

            Spacer()

            // Avatar → Settings
            Button { settingsOpen = true } label: {
                if let url = auth.avatarUrl, let imageUrl = URL(string: url) {
                    AsyncImage(url: imageUrl) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        avatarPlaceholder
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                } else {
                    avatarPlaceholder
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(Color.finaBackground)
        .sheet(isPresented: $settingsOpen) {
            SettingsView()
                .environment(auth)
                .finaColorScheme()
        }
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(Color.finaPrimary)
                .frame(width: 32, height: 32)
            Text(auth.initials.isEmpty ? "?" : auth.initials)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.finaPrimaryForeground)
        }
    }
}
