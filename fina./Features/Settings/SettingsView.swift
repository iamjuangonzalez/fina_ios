import SwiftUI
import UserNotifications

// MARK: - Monedas disponibles
struct Currency: Identifiable {
    let id: String      // código ISO
    let flag: String
    let name: String
}

private let CURRENCIES: [Currency] = [
    .init(id: "COP", flag: "🇨🇴", name: "Peso colombiano"),
    .init(id: "USD", flag: "🇺🇸", name: "Dólar estadounidense"),
    .init(id: "EUR", flag: "🇪🇺", name: "Euro"),
    .init(id: "MXN", flag: "🇲🇽", name: "Peso mexicano"),
    .init(id: "ARS", flag: "🇦🇷", name: "Peso argentino"),
    .init(id: "CLP", flag: "🇨🇱", name: "Peso chileno"),
    .init(id: "PEN", flag: "🇵🇪", name: "Sol peruano"),
    .init(id: "BRL", flag: "🇧🇷", name: "Real brasileño"),
    .init(id: "GBP", flag: "🇬🇧", name: "Libra esterlina"),
]

// MARK: - SettingsView
struct SettingsView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var systemScheme

    @AppStorage("appColorScheme")      private var storedScheme: String  = "system"
    @AppStorage("appCurrency")         private var currency: String       = "COP"
    @AppStorage("appLanguage")         private var appLanguage: String    = "es"

    @AppStorage("hasPro") private var hasPro: Bool = false

    @State private var notificationsEnabled = false
    @State private var showCurrencyPicker   = false
    @State private var showLanguagePicker   = false
    @State private var showSignOutAlert     = false
    @State private var showApplePay         = false
    @State private var showBankSMS          = false
    @State private var showCategories       = false
    @State private var showInviteFriends    = false
    @State private var showPro              = false

    var selectedCurrency: Currency? { CURRENCIES.first { $0.id == currency } }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: Pro banner
                    if !hasPro {
                        proBanner
                    }

                    // MARK: Cuenta
                    settingsSection(label: "Cuenta") {
                        row(icon: "person", label: "Editar perfil") {}
                        rowDivider()
                        row(icon: "rectangle.portrait.and.arrow.right",
                            label: "Cerrar sesión",
                            destructive: true) {
                            showSignOutAlert = true
                        }
                    }

                    // MARK: Preferencias
                    settingsSection(label: "Preferencias") {
                        // Tema
                        HStack(spacing: 12) {
                            iconBox(systemName: storedScheme == "dark" ? "moon"
                                           : storedScheme == "light" ? "sun.max" : "iphone")
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Tema")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.finaForeground)
                            }
                            Spacer()
                            themeToggle
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        rowDivider()

                        // Moneda
                        Button { showCurrencyPicker = true } label: {
                            HStack(spacing: 12) {
                                iconBox(systemName: "dollarsign.circle")
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Moneda")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Color.finaForeground)
                                    if let c = selectedCurrency {
                                        Text(c.name)
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color.finaMutedForeground)
                                    }
                                }
                                Spacer()
                                Text(currency)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.finaMutedForeground)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.finaMutedForeground)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }

                        rowDivider()

                        // Idioma
                        Button { showLanguagePicker = true } label: {
                            HStack(spacing: 12) {
                                iconBox(systemName: "globe")
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Idioma")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Color.finaForeground)
                                    Text(appLanguage == "en" ? "English" : "Español")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.finaMutedForeground)
                                }
                                Spacer()
                                Text(appLanguage == "en" ? "🇺🇸 EN" : "🇪🇸 ES")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.finaMutedForeground)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.finaMutedForeground)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }

                    // MARK: Más
                    settingsSection(label: "Más") {
                        row(icon: "square.grid.2x2",
                            label: "Categorías",
                            subtitle: "Gestiona tus categorías") {
                            showCategories = true
                        }
                        rowDivider()
                        row(icon: "wallet.pass",
                            label: "Apple Pay",
                            subtitle: "Seguimiento automático") {
                            showApplePay = true
                        }
                        rowDivider()
                        row(icon: "message",
                            label: "SMS Bancario",
                            subtitle: "Registra pagos desde tus mensajes") {
                            showBankSMS = true
                        }
                        rowDivider()
                        row(icon: "person.2",
                            label: "Invitar amigos",
                            subtitle: "Invita a tus amigos a usar fina") {
                            showInviteFriends = true
                        }
                    }

                    // MARK: Notificaciones
                    settingsSection(label: "Notificaciones") {
                        HStack(spacing: 12) {
                            iconBox(systemName: "bell")
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Notificaciones")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.finaForeground)
                                Text("Recordatorios y push")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.finaMutedForeground)
                            }
                            Spacer()
                            Toggle("", isOn: $notificationsEnabled)
                                .labelsHidden()
                                .tint(Color.finaPrimary)
                                .onChange(of: notificationsEnabled) { _, newVal in
                                    handleNotificationsToggle(newVal)
                                }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color.finaBackground)
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Listo") { dismiss() }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.finaForeground)
                }
            }
        }
        .onAppear { checkNotificationStatus() }
        .fullScreenCover(isPresented: $showPro)      { ProUpgradeView().finaColorScheme() }
        .sheet(isPresented: $showLanguagePicker)    { languagePickerSheet.finaColorScheme() }
        .sheet(isPresented: $showCurrencyPicker)    { currencyPickerSheet.finaColorScheme() }
        .sheet(isPresented: $showApplePay)          { ApplePayView().finaColorScheme() }
        .sheet(isPresented: $showBankSMS)           { BankSMSView().finaColorScheme() }
        .sheet(isPresented: $showCategories)        { CategoriesView().finaColorScheme() }
        .sheet(isPresented: $showInviteFriends)     { inviteFriendsSheet.finaColorScheme() }
        .confirmationDialog("¿Estás seguro?", isPresented: $showSignOutAlert, titleVisibility: .visible) {
            Button("Cerrar sesión", role: .destructive) {
                Task { await auth.signOut(); dismiss() }
            }
            Button("Cancelar", role: .cancel) {}
        }
    }

    // MARK: - Pro banner
    private var proBanner: some View {
        Button { showPro = true } label: {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 7) {
                        Text("fina.")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                        Text("PRO")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(.white.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    Text("Desbloquea todas las funciones")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                Text("Upgrade")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(red: 0.980, green: 0.451, blue: 0.086))
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(.white)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 18).padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.08, blue: 0.06),
                        Color(red: 0.20, green: 0.10, blue: 0.05),
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(red: 0.980, green: 0.451, blue: 0.086).opacity(0.35), lineWidth: 1)
            )
        }
    }

    // MARK: - Language picker sheet
    private var languagePickerSheet: some View {
        let languages: [(code: String, flag: String, name: String)] = [
            ("es", "🇪🇸", "Español"),
            ("en", "🇺🇸", "English"),
        ]
        return NavigationStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("El cambio se aplica de inmediato.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.finaMutedForeground)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                List(languages, id: \.code) { lang in
                    Button {
                        guard lang.code != appLanguage else { return }
                        appLanguage = lang.code
                        LanguageManager.shared.setLanguage(lang.code)
                        showLanguagePicker = false
                    } label: {
                        HStack(spacing: 12) {
                            Text(lang.flag).font(.system(size: 28))
                            Text(lang.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.finaForeground)
                            Spacer()
                            if lang.code == appLanguage {
                                ZStack {
                                    Circle().stroke(Color.finaForeground, lineWidth: 2)
                                    Circle().fill(Color.finaForeground).frame(width: 10, height: 10)
                                }
                                .frame(width: 20, height: 20)
                            } else {
                                Circle().stroke(Color.finaBorder, lineWidth: 2)
                                    .frame(width: 20, height: 20)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
            .background(Color.finaBackground)
            .navigationTitle("Idioma")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { showLanguagePicker = false }
                        .foregroundStyle(Color.finaForeground)
                }
            }
        }
        .presentationDetents([.fraction(0.35)])
    }

    // MARK: - Invite friends sheet
    private var inviteFriendsSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "person.2.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.finaPrimary)

                VStack(spacing: 8) {
                    Text("Invita a tus amigos")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.finaForeground)
                    Text("Comparte fina con tus amigos\ny controlen sus finanzas juntos")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.finaMutedForeground)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                ShareLink(
                    item: "Usa fina para controlar tus finanzas personales. ¡Únete aquí: https://getfina.app",
                    message: Text("Te recomiendo fina")
                ) {
                    Label("Compartir fina", systemImage: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.finaPrimaryForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.finaPrimary)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(Color.finaBackground)
            .navigationTitle("Invitar amigos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { showInviteFriends = false }
                        .foregroundStyle(Color.finaForeground)
                }
            }
        }
        .presentationDetents([.fraction(0.55)])
    }

    // MARK: - Currency picker sheet
    private var currencyPickerSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Se aplica a toda la app.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.finaMutedForeground)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                List(CURRENCIES) { c in
                    Button {
                        currency = c.id
                        showCurrencyPicker = false
                    } label: {
                        HStack(spacing: 12) {
                            Text(c.flag).font(.system(size: 28))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(c.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.finaForeground)
                                Text(c.id)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.finaMutedForeground)
                            }
                            Spacer()
                            if c.id == currency {
                                ZStack {
                                    Circle().stroke(Color.finaForeground, lineWidth: 2)
                                    Circle().fill(Color.finaForeground).frame(width: 10, height: 10)
                                }
                                .frame(width: 20, height: 20)
                            } else {
                                Circle().stroke(Color.finaBorder, lineWidth: 2)
                                    .frame(width: 20, height: 20)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
            .background(Color.finaBackground)
            .navigationTitle("Elige moneda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { showCurrencyPicker = false }
                        .foregroundStyle(Color.finaForeground)
                }
            }
        }
        .presentationDetents([.fraction(0.55)])
    }

    // MARK: - Theme toggle  (Auto / Claro / Oscuro)
    private var themeToggle: some View {
        let options: [(icon: String, value: String)] = [
            ("iphone",   "system"),
            ("sun.max",  "light"),
            ("moon",     "dark"),
        ]
        return HStack(spacing: 2) {
            ForEach(options, id: \.value) { opt in
                Button { storedScheme = opt.value } label: {
                    Image(systemName: opt.icon)
                        .font(.system(size: 13))
                        .foregroundStyle(storedScheme == opt.value
                                         ? Color.finaForeground
                                         : Color.finaMutedForeground)
                        .frame(width: 32, height: 28)
                        .background(storedScheme == opt.value
                                    ? Color.finaCard
                                    : Color.clear)
                        .cornerRadius(8)
                }
            }
        }
        .padding(2)
        .background(Color.finaMuted)
        .cornerRadius(10)
    }

    // MARK: - Helpers de layout
    @ViewBuilder
    private func settingsSection(label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.finaMutedForeground)
                .kerning(0.8)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.finaMuted.opacity(0.5))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.finaBorder, lineWidth: 1))
        }
    }

    private func row(
        icon: String,
        label: String,
        subtitle: String? = nil,
        destructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                iconBox(systemName: icon, destructive: destructive)
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(destructive ? Color.finaDestructive : Color.finaForeground)
                    if let sub = subtitle {
                        Text(sub)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.finaMutedForeground)
                    }
                }
                Spacer()
                if !destructive {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.finaMutedForeground)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func rowDivider() -> some View {
        Divider().padding(.leading, 52)
    }

    private func iconBox(systemName: String, destructive: Bool = false) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 15))
            .foregroundStyle(destructive ? Color.finaDestructive : Color.finaForeground)
            .frame(width: 32, height: 32)
            .background(Color.finaMuted)
            .cornerRadius(8)
    }

    // MARK: - Notificaciones
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }

    private func handleNotificationsToggle(_ enabled: Bool) {
        guard enabled else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                notificationsEnabled = granted
                if !granted {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
    }
}
