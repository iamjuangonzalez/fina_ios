import Supabase
import Foundation

// MARK: - Credenciales
// Reemplaza estos valores con los de tu proyecto en supabase.com → Settings → API
private enum Config {
    static let supabaseURL = "https://vdaswjwpngoxvzvgktnp.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkYXN3andwbmdveHZ6dmdrdG5wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM2MTQ0MDksImV4cCI6MjA4OTE5MDQwOX0.CnEEjVzqWhjgcIpQRnZUhM27BAKewQ1fDRYj5Xxqfpk"
}

// MARK: - Cliente global
let supabase = SupabaseClient(
    supabaseURL: URL(string: Config.supabaseURL)!,
    supabaseKey: Config.supabaseAnonKey,
    options: .init(
        auth: .init(
            emitLocalSessionAsInitialSession: true
        )
    )
)
