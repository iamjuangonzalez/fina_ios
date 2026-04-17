import SwiftUI
import SwiftData

// MARK: - Nature option model
private struct NatureOption {
    let value: String
    let title: String
    let subtitle: String
    let icon: String
}

private let NATURE_OPTIONS: [NatureOption] = [
    .init(value: "fixed",      title: "Fijo",       subtitle: "Recurrente, predecible",    icon: "pencil"),
    .init(value: "variable",   title: "Variable",   subtitle: "Cambia cada mes",           icon: "waveform.path"),
    .init(value: "hormiga",    title: "Hormiga",    subtitle: "Pequeño y frecuente",       icon: "sun.min"),
    .init(value: "unexpected", title: "Inesperado", subtitle: "Imprevisto o emergencia",   icon: "exclamationmark.triangle"),
]

struct NewTransactionView: View {
    @Environment(\.dismiss)        private var dismiss
    @Environment(\.modelContext)   private var ctx
    @Environment(AuthManager.self) private var auth
    @AppStorage("appCurrency")     private var currency: String = "COP"

    var prefill:     TransactionPrefill?  = nil
    var voiceIntent: ParsedVoiceIntent?  = nil

    @Query(filter: #Predicate<CategoryRecord> { !$0.isDeleted },
           sort: \CategoryRecord.sortOrder)
    private var categories: [CategoryRecord]

    // MARK: Form state
    @State private var desc          = ""
    @State private var amountText    = ""
    @State private var txDate        = Date()
    @State private var frequency     = "once"
    @State private var txType        = "expense"
    @State private var categoryId: String?  = nil
    @State private var nature: String?      = nil
    @State private var frequencyEnd: String? = nil   // "yyyy-MM"
    @State private var showDatePicker   = false
    @State private var showMonthPicker  = false
    @State private var natureAutoSet    = false

    // Sugerencia de categoría con AI
    @State private var categoryAISuggested  = false
    @State private var categoriesCollapsed  = false
    @State private var suggestionTask: Task<Void, Never>? = nil
    @State private var isSuggesting         = false
    @State private var showAddCategory      = false
    @State private var showNoMatchToast     = false
    @State private var toastDismissTask: Task<Void, Never>? = nil

    @FocusState private var focused: Field?
    private enum Field { case desc, amount }

    // MARK: Computed
    private var amount: Double {
        Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
    // Monto + categoría obligatorios. Descripción opcional.
    private var canSave: Bool { amount > 0 && categoryId != nil }
    private var isRecurring: Bool { frequency != "once" }
    private var typeColor: Color {
        txType == "income" ? Color.finaSavingsGood : Color.finaSavingsBad
    }

    // Auto-sugerencia de nature — basada en frecuencia, no en categoría
    private var suggestedNature: String? {
        let amountVal = Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0

        switch frequency {
        case "monthly", "yearly":
            return "fixed"
        case "weekly":
            return "variable"
        case "once":
            // Monto pequeño → hormiga; monto grande → sin sugerencia
            if amountVal > 0 && amountVal <= 20_000 { return "hormiga" }
            return nil
        default:
            return nil
        }
    }

    // MARK: Body
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.finaBackground.ignoresSafeArea()
            typeColor.opacity(0.04).ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: txType)

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 16)
                        amountDisplay
                            .padding(.bottom, 16)
                        descField
                            .padding(.bottom, 24)
                        categoryRow
                            .padding(.bottom, 20)
                        pillsRow
                            .padding(.bottom, 28)
                        natureSection
                            .padding(.bottom, 8)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture { focused = nil }

                // Footer fijo con botón guardar
                VStack(spacing: 0) {
                    saveButton
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                }
            }

            // MARK: – No-match toast
            if showNoMatchToast {
                HStack(spacing: 10) {
                    Image(systemName: "sparkle.magnifyingglass")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.finaMutedForeground)
                    Text("Sin coincidencia — elige una categoría")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.finaForeground)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.finaBorder, lineWidth: 1))
                .shadow(color: .black.opacity(0.10), radius: 12, y: 4)
                .padding(.bottom, 90)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            if let p = prefill {
                desc       = p.merchant
                amountText = p.amount > 0 ? String(Int(p.amount)) : ""
            }
            if let v = voiceIntent {
                desc       = v.description ?? ""
                amountText = v.amount.map { String(Int($0)) } ?? ""
                txType     = v.txType
                if let cid = v.categoryId { categoryId = cid }
                if v.dateOffset != 0 {
                    txDate = Calendar.current.date(
                        byAdding: .day, value: v.dateOffset, to: Date()) ?? Date()
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                focused = amountText.isEmpty ? .amount : .desc
            }
        }
        .onChange(of: frequency)   { _, _ in applyNatureSuggestion() }
        .onChange(of: categoryId)  { _, _ in applyNatureSuggestion() }
        .onChange(of: amountText)  { _, _ in applyNatureSuggestion() }
        .onChange(of: desc) { _, newVal in
            guard !categoryAISuggested || categoryId == nil else { return }
            suggestionTask?.cancel()

            guard newVal.count >= 3 else {
                isSuggesting = false
                return
            }

            // Fase 1: quickMatch local — instantáneo, sin spinner
            if let local = CategorySuggester.quickMatch(newVal, categories: categories, minScore: 8) {
                isSuggesting = false
                withAnimation(.spring(duration: 0.35)) {
                    categoryId          = local
                    categoryAISuggested = true
                    categoriesCollapsed = true
                }
                return
            }

            // Fase 2: Claude Haiku — debounce 300ms, spinner solo durante el API call
            suggestionTask = Task {
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }

                // Mostrar spinner SOLO cuando vamos a llamar a la API
                await MainActor.run { isSuggesting = true }

                let suggested = await CategorySuggester.suggest(
                    description: newVal, categories: categories)

                guard !Task.isCancelled else {
                    await MainActor.run { isSuggesting = false }
                    return
                }
                await MainActor.run {
                    isSuggesting = false
                    if let s = suggested {
                        withAnimation(.spring(duration: 0.35)) {
                            categoryId          = s
                            categoryAISuggested = true
                            categoriesCollapsed = true
                        }
                    } else {
                        showNoMatchToastBriefly()
                    }
                }
            }
        }
        .sheet(isPresented: $showDatePicker)    { datepickerSheet }
        .sheet(isPresented: $showMonthPicker)   { monthPickerSheet }
        .sheet(isPresented: $showAddCategory)   {
            CategoriesView().finaColorScheme()
        }
    }

    // MARK: – Top bar
    private var topBar: some View {
        HStack {
            HStack(spacing: 0) {
                typeTab(label: "Gasto",   value: "expense")
                typeTab(label: "Ingreso", value: "income")
            }
            .background(Color.finaMuted)
            .clipShape(Capsule())
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.finaMutedForeground)
                    .frame(width: 32, height: 32)
                    .background(Color.finaMuted)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 4)
    }

    private func typeTab(label: String, value: String) -> some View {
        let active = txType == value
        return Button {
            withAnimation(.spring(duration: 0.25)) { txType = value }
        } label: {
            Text(label)
                .font(.system(size: 13, weight: active ? .semibold : .regular))
                .foregroundStyle(active ? .white : Color.finaMutedForeground)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(active ? typeColor : Color.clear)
                .clipShape(Capsule())
        }
        .animation(.spring(duration: 0.25), value: txType)
    }

    // MARK: – Amount
    private var amountDisplay: some View {
        VStack(spacing: 4) {
            Text(currency)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(typeColor.opacity(0.7))
            TextField("0", text: $amountText)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(typeColor)
                .tint(typeColor)
                .multilineTextAlignment(.center)
                .keyboardType(.decimalPad)
                .focused($focused, equals: .amount)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .padding(.horizontal, 24)
        }
        .animation(.easeInOut(duration: 0.2), value: txType)
    }

    // MARK: – Description
    private var descField: some View {
        TextField("¿En qué gastaste? (opcional)", text: $desc)
            .font(.system(size: 22))
            .foregroundColor(Color.finaForeground)
            .multilineTextAlignment(.center)
            .focused($focused, equals: .desc)
            .submitLabel(.done)
            .padding(.horizontal, 32)
    }

    // MARK: – Categories
    private var categoryRow: some View {
        VStack(alignment: .leading, spacing: 0) {
            if categoriesCollapsed, let selId = categoryId,
               let selCat = categories.first(where: { $0.id == selId }) {
                // ── Estado colapsado: solo categoría sugerida + badge AI + "N más" ──
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Spinner AI (al inicio, mientras busca)
                        if isSuggesting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 28, height: 28)
                                .transition(.opacity)
                        }
                        // Botón añadir categoría
                        Button { showAddCategory = true } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.finaMutedForeground)
                                .frame(width: 32, height: 32)
                                .background(Color.finaMuted)
                                .clipShape(Circle())
                        }

                        // Chip de la categoría seleccionada
                        Button {
                            // Tocar la seleccionada → expandir todas
                            withAnimation(.spring(duration: 0.3)) {
                                categoriesCollapsed  = false
                                categoryAISuggested  = false
                            }
                        } label: {
                            HStack(spacing: 6) {
                                BrandIconView(iconKey: selCat.id, emoji: selCat.emoji,
                                              color: selCat.color, size: 24)
                                Text(selCat.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(typeColor)
                                // Badge AI
                                if categoryAISuggested {
                                    Text("AI")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 5).padding(.vertical, 2)
                                        .background(typeColor)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 14).padding(.vertical, 9)
                            .background(typeColor.opacity(0.10))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(typeColor, lineWidth: 1))
                        }

                        // Chip "N más" para expandir
                        let restCount = categories.count - 1
                        if restCount > 0 {
                            Button {
                                withAnimation(.spring(duration: 0.3)) {
                                    categoriesCollapsed = false
                                    categoryAISuggested = false
                                }
                            } label: {
                                Text("+ \(restCount) más")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.finaMutedForeground)
                                    .padding(.horizontal, 14).padding(.vertical, 9)
                                    .background(Color.finaMuted)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .transition(.opacity)

            } else {
                // ── Estado expandido: todas las categorías ──
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Spinner AI (al inicio, mientras busca)
                        if isSuggesting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 28, height: 28)
                                .transition(.opacity)
                        }
                        // Botón añadir categoría
                        Button { showAddCategory = true } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.finaMutedForeground)
                                .frame(width: 32, height: 32)
                                .background(Color.finaMuted)
                                .clipShape(Circle())
                        }

                        // Si hay una seleccionada, va primero
                        let ordered: [CategoryRecord] = {
                            if let selId = categoryId,
                               let idx = categories.firstIndex(where: { $0.id == selId }) {
                                var arr = categories
                                arr.move(fromOffsets: IndexSet(integer: idx), toOffset: 0)
                                return arr
                            }
                            return categories
                        }()

                        ForEach(ordered) { cat in
                            Button {
                                withAnimation(.spring(duration: 0.2)) {
                                    if categoryId == cat.id {
                                        categoryId = nil
                                    } else {
                                        categoryId          = cat.id
                                        categoryAISuggested = false
                                        categoriesCollapsed  = true
                                    }
                                }
                            } label: {
                                let selected = categoryId == cat.id
                                HStack(spacing: 6) {
                                    BrandIconView(iconKey: cat.id, emoji: cat.emoji,
                                                  color: cat.color, size: 24)
                                    Text(cat.name)
                                        .font(.system(size: 13,
                                                      weight: selected ? .semibold : .regular))
                                        .foregroundStyle(selected ? typeColor
                                                                   : Color.finaForeground)
                                }
                                .padding(.horizontal, 14).padding(.vertical, 9)
                                .background(selected ? typeColor.opacity(0.10) : Color.finaCard)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(
                                    selected ? typeColor : Color.finaBorder, lineWidth: 1))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .transition(.opacity)
            }

        }
        .animation(.spring(duration: 0.3), value: categoriesCollapsed)
        .animation(.easeInOut(duration: 0.2), value: isSuggesting)
    }

    // MARK: – Pills (fecha + frecuencia + hasta cuando)
    private var pillsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Fecha
                Button { showDatePicker = true } label: {
                    pillLabel(Calendar.current.isDateInToday(txDate)
                              ? "Hoy"
                              : txDate.formatted(.dateTime.day().month(.abbreviated)),
                              icon: "calendar")
                }

                // Frecuencia — tap cicla entre opciones
                let freqMap   = ["once":"Una vez","weekly":"Semanal","monthly":"Mensual","yearly":"Anual"]
                let freqOrder = ["once","weekly","monthly","yearly"]
                Button {
                    withAnimation(.spring(duration: 0.2)) {
                        let i = freqOrder.firstIndex(of: frequency) ?? 0
                        frequency = freqOrder[(i + 1) % freqOrder.count]
                        if frequency == "once" { frequencyEnd = nil }
                    }
                } label: {
                    pillLabel(freqMap[frequency] ?? "Una vez", icon: "repeat")
                }

                // "Hasta" — solo si es recurrente
                if isRecurring {
                    Button { showMonthPicker = true } label: {
                        let label = frequencyEnd.map { endMonthLabel($0) } ?? "hasta ∞"
                        pillLabel(label, icon: "calendar.badge.clock",
                                  active: frequencyEnd != nil)
                    }
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .animation(.spring(duration: 0.25), value: isRecurring)
            .animation(.spring(duration: 0.25), value: frequencyEnd)
        }
    }

    /// "2026-04" → "Abr 2026"
    private func endMonthLabel(_ key: String) -> String {
        let parts = key.split(separator: "-")
        guard parts.count == 2,
              let month = Int(parts[1]) else { return key }
        let names = ["","Ene","Feb","Mar","Abr","May","Jun",
                     "Jul","Ago","Sep","Oct","Nov","Dic"]
        let m = names[safe: month] ?? key
        return "hasta \(m) \(parts[0])"
    }

    private func pillLabel(_ text: String, icon: String? = nil, active: Bool = false) -> some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(active ? typeColor : Color.finaMutedForeground)
            }
            Text(LocalizedStringKey(text))
                .font(.system(size: 13, weight: active ? .semibold : .medium))
                .foregroundStyle(active ? typeColor : Color.finaForeground)
            Image(systemName: "chevron.down")
                .font(.system(size: 10))
                .foregroundStyle(Color.finaMutedForeground)
        }
        .padding(.horizontal, 14).padding(.vertical, 9)
        .background(active ? typeColor.opacity(0.10) : Color.finaMuted)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(active ? typeColor.opacity(0.3) : Color.clear, lineWidth: 1))
    }

    // MARK: – Nature tags (compactos)
    private var natureSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(NATURE_OPTIONS, id: \.value) { opt in
                    let selected = nature == opt.value
                    Button {
                        withAnimation(.spring(duration: 0.2)) {
                            nature        = selected ? nil : opt.value
                            natureAutoSet = false
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: opt.icon)
                                .font(.system(size: 11))
                            Text(LocalizedStringKey(opt.title))
                                .font(.system(size: 12, weight: selected ? .semibold : .regular))
                            if selected && natureAutoSet {
                                Text("auto")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(typeColor)
                            }
                        }
                        .foregroundStyle(selected ? typeColor : Color.finaMutedForeground)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(selected ? typeColor.opacity(0.10) : Color.clear)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(
                            selected ? typeColor.opacity(0.4) : Color.finaBorder, lineWidth: 1))
                    }
                    .animation(.spring(duration: 0.2), value: nature)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: – Save button
    private var saveButton: some View {
        Button { save() } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                Text("Guardar")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(canSave ? .white : Color.finaMutedForeground)
            .frame(maxWidth: .infinity).frame(height: 54)
            .background(canSave ? typeColor : Color.finaMuted)
            .clipShape(Capsule())
            .animation(.easeInOut(duration: 0.2), value: canSave)
        }
        .disabled(!canSave)
    }

    // MARK: – Date picker sheet
    private var datepickerSheet: some View {
        NavigationStack {
            DatePicker("", selection: $txDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(typeColor)
                .padding()
                .background(Color.finaBackground)
                .navigationTitle("Fecha")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Listo") { showDatePicker = false }
                            .foregroundStyle(Color.finaForeground)
                    }
                }
        }
        .presentationDetents([.medium])
    }

    // MARK: – Month picker sheet
    private var monthPickerSheet: some View {
        let months = Self.nextMonths(count: 24)
        return NavigationStack {
            List {
                // Opción vaciar
                Button {
                    frequencyEnd = nil
                    showMonthPicker = false
                } label: {
                    HStack {
                        Text("Sin fecha de fin")
                            .foregroundStyle(Color.finaMutedForeground)
                        Spacer()
                        if frequencyEnd == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(typeColor)
                        }
                    }
                }
                .listRowBackground(Color.finaCard)

                ForEach(months, id: \.key) { item in
                    Button {
                        frequencyEnd = item.key
                        showMonthPicker = false
                    } label: {
                        HStack {
                            Text(item.label)
                                .foregroundStyle(Color.finaForeground)
                            Spacer()
                            if frequencyEnd == item.key {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(typeColor)
                            }
                        }
                    }
                    .listRowBackground(Color.finaCard)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.finaBackground)
            .navigationTitle("Hasta cuando")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { showMonthPicker = false }
                        .foregroundStyle(Color.finaForeground)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: – Helpers

    private func showNoMatchToastBriefly() {
        toastDismissTask?.cancel()
        withAnimation(.spring(duration: 0.3)) { showNoMatchToast = true }
        toastDismissTask = Task {
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.25)) { showNoMatchToast = false }
            }
        }
    }

    private func applyNatureSuggestion() {
        guard let suggested = suggestedNature else { return }
        // No sobreescribir si el usuario eligió manualmente (!natureAutoSet → elección manual)
        guard natureAutoSet || nature == nil else { return }
        guard nature != suggested else { return }   // ya está correcto, no animar de nuevo
        withAnimation(.spring(duration: 0.25)) {
            nature        = suggested
            natureAutoSet = true
        }
    }

    private func save() {
        guard canSave, let userId = auth.userId else { return }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let cal = Calendar.current

        // Generar todas las fechas de ocurrencia
        var dates: [Date] = [txDate]
        // ID compartido para todos los registros de esta serie
        let sid = frequency != "once" ? UUID().uuidString : nil

        if frequency != "once", let endKey = frequencyEnd {
            let endParts = endKey.split(separator: "-")
            if endParts.count == 2,
               let endYear  = Int(endParts[0]),
               let endMonth = Int(endParts[1]) {

                let component: Calendar.Component = {
                    switch frequency {
                    case "weekly":  return .weekOfYear
                    case "yearly":  return .year
                    default:        return .month   // "monthly"
                    }
                }()

                var cursor = txDate
                while true {
                    guard let next = cal.date(byAdding: component, value: 1, to: cursor) else { break }
                    let y = cal.component(.year,  from: next)
                    let m = cal.component(.month, from: next)
                    if y > endYear || (y == endYear && m > endMonth) { break }
                    dates.append(next)
                    cursor = next
                }
            }
        }

        for date in dates {
            let tx = TxRecord(
                userId:     userId,
                categoryId: categoryId ?? "general",
                type:       txType,
                amount:     amount,
                currency:   currency,
                desc:       desc,
                date:       df.string(from: date),
                frequency:  frequency,
                nature:     nature
            )
            tx.frequencyEnd = frequencyEnd
            tx.seriesId     = sid
            ctx.insert(tx)
        }
        ctx.safeSave()
        dismiss()
    }

    // Genera los próximos N meses como (key: "yyyy-MM", label: "Abril 2026")
    private static func nextMonths(count: Int) -> [(key: String, label: String)] {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "es_CO")
        fmt.dateFormat = "MMMM yyyy"
        let keyFmt = DateFormatter()
        keyFmt.dateFormat = "yyyy-MM"

        return (1...count).compactMap { offset in
            guard let date = cal.date(byAdding: .month, value: offset, to: Date()) else { return nil }
            let label = fmt.string(from: date)
            return (key: keyFmt.string(from: date),
                    label: label.prefix(1).uppercased() + label.dropFirst())
        }
    }
}

// MARK: - Array helpers
private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
