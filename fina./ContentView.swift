import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) private var auth
    @Binding var txPrefill: TransactionPrefill?

    var body: some View {
        Group {
            if auth.isInitializing {
                SplashView()
            } else if auth.isAuthenticated {
                DashboardView(txPrefill: $txPrefill)
                    .transition(.opacity)
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: auth.isInitializing)
        .animation(.easeInOut(duration: 0.35), value: auth.isAuthenticated)
    }
}

// MARK: - SplashView
// Se muestra los ~200ms que tarda Supabase en resolver la sesión cacheada.

private struct SplashView: View {
    @State private var opacity = 0.0

    var body: some View {
        ZStack {
            Color.finaBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                // Logo / nombre de la app
                Text("fina.")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.finaForeground)

                ProgressView()
                    .scaleEffect(0.8)
                    .tint(Color.finaMutedForeground)
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.2)) { opacity = 1 }
        }
    }
}
