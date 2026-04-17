import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AuthManager.self)  private var auth
    @Environment(\.modelContext)    private var ctx
    @AppStorage("appCurrency")      private var currency: String = "COP"
    @State private var vm = DashboardViewModel()
    @State private var showNewTransaction  = false
    @State private var showVoiceInput      = false
    @State private var showReports         = false
    @State private var selectedTransaction: TxRecord? = nil
    @State private var txToDelete:          TxRecord? = nil
    @State private var showDeleteConfirm   = false
    @State private var showSeriesDialog    = false
    @Binding var txPrefill: TransactionPrefill?

    @Query(filter: #Predicate<CategoryRecord> { !$0.isDeleted })
    private var categoriesArr: [CategoryRecord]

    // categoryId → hex color para pasar a componentes hijos
    private var categoryColors: [String: String] {
        Dictionary(uniqueKeysWithValues: categoriesArr.map { ($0.id, $0.color) })
    }
    private var categoryEmojis: [String: String] {
        Dictionary(uniqueKeysWithValues: categoriesArr.map { ($0.id, $0.emoji) })
    }

    var body: some View {
        VStack(spacing: 0) {

            AppHeader()
                .environment(auth)

            Divider()
                .foregroundStyle(Color.finaBorder)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {

                    monthNavigator

                    heroCard

                    miniStats

                    monaiNote

                    contextualSection

                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 100)   // espacio para la barra flotante
            }
        }
        .background(Color.finaBackground)
        .onAppear {
            vm.setup(context: ctx, userId: auth.userId, currency: currency)
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.willEnterForegroundNotification)) { _ in
            Task { await vm.fetchAll() }
        }
        .overlay(alignment: .bottom) { bottomBar }
        .sheet(isPresented: $showNewTransaction, onDismiss: {
            Task { await vm.fetchTransactions() }
        }) {
            NewTransactionView()
                .environment(auth)
                .finaColorScheme()
        }
        .sheet(item: $txPrefill, onDismiss: {
            Task { await vm.fetchTransactions() }
        }) { prefill in
            NewTransactionView(prefill: prefill)
                .environment(auth)
                .finaColorScheme()
        }
        .sheet(isPresented: $showVoiceInput, onDismiss: {
            Task { await vm.fetchTransactions() }
        }) {
            VoiceInputView()
                .environment(auth)
                .finaColorScheme()
        }
        .sheet(isPresented: $showReports) {
            ReportsView()
                .environment(auth)
                .finaColorScheme()
        }
        .sheet(item: $selectedTransaction, onDismiss: {
            Task { await vm.fetchTransactions() }
        }) { tx in
            let category = categoriesArr.first { $0.id == tx.categoryId }
            TransactionDetailView(
                tx:              tx,
                category:        category,
                previousAmount:  vm.previousMonthAmount(for: tx),
                allTransactions: vm.allTxForDetail
            )
            .finaColorScheme()
        }
        // Alerts de eliminación desde swipe
        .alert("¿Eliminar transacción?", isPresented: $showDeleteConfirm) {
            Button("Eliminar", role: .destructive) { commitDelete(.single) }
            Button("Cancelar", role: .cancel) {}
        } message: { Text("Esta acción no se puede deshacer.") }
        .alert("¿Qué quieres eliminar?", isPresented: $showSeriesDialog) {
            Button("Solo esta",              role: .destructive) { commitDelete(.single)     }
            Button("Este y los siguientes",  role: .destructive) { commitDelete(.thisAndFuture) }
            Button("Todos",                  role: .destructive) { commitDelete(.all)        }
            Button("Cancelar", role: .cancel) {}
        } message: { Text("Esta acción no se puede deshacer.") }
    }

    // MARK: - Delete desde swipe
    private func requestDelete(_ tx: TxRecord) {
        txToDelete = tx
        let siblings = vm.allTxForDetail.filter { $0.seriesId != nil && $0.seriesId == tx.seriesId }
        if tx.frequency != "once", !siblings.isEmpty, siblings.count > 1 {
            showSeriesDialog = true
        } else {
            showDeleteConfirm = true
        }
    }

    private enum DeleteScope { case single, thisAndFuture, all }

    private func commitDelete(_ scope: DeleteScope) {
        guard let tx = txToDelete else { return }
        switch scope {
        case .single:
            ctx.delete(tx)
        case .thisAndFuture:
            let siblings = vm.allTxForDetail.filter { $0.seriesId == tx.seriesId && $0.date >= tx.date }
            siblings.forEach { ctx.delete($0) }
        case .all:
            let siblings = vm.allTxForDetail.filter { $0.seriesId == tx.seriesId }
            siblings.forEach { ctx.delete($0) }
        }
        ctx.safeSave()
        txToDelete = nil
        Task { await vm.fetchAll() }
    }

    // MARK: - Month navigator
    private var monthNavigator: some View {
        ZStack {
            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(vm.monthName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.finaForeground)
                    Text(", ")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.finaMutedForeground)
                    Text(vm.yearLabel)
                        .font(.system(size: 22))
                        .foregroundStyle(
                            vm.isCurrentMonth
                                ? Color(red: 0.063, green: 0.725, blue: 0.506)
                                : Color.finaMutedForeground
                        )
                }
            }

            HStack {
                navButton(icon: "chevron.left")  { vm.prevMonth() }
                Spacer()
                navButton(icon: "chevron.right") { vm.nextMonth() }
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Hero card
    private var heroCard: some View {
        let cal = Calendar.current
        let day = cal.component(.day, from: Date())
        let range = cal.range(of: .day, in: .month, for: Date())?.count ?? 30

        return HeroBalanceCard(
            context:     vm.monthContext,
            balance:     vm.balance,
            income:      vm.totalIncomes,
            expenses:    vm.totalExpenses,
            savingsPct:  vm.savingsPct,
            currency:    currency,
            dayOfMonth:  day,
            daysInMonth: range
        )
    }

    // MARK: - Mini stats
    @ViewBuilder
    private var miniStats: some View {
        switch vm.monthContext {
        case .past:
            MiniStatsRow.forPast(
                savingsPct:  vm.savingsPct,
                topCategory: vm.topCategory,
                hormigaTotal: vm.hormigaTotal,
                currency:    currency
            )
        case .current:
            MiniStatsRow.forCurrent(
                savingsPct:    vm.savingsPct,
                budgetPct:     nil,   // presupuesto por implementar
                todayExpenses: vm.todayExpenses,
                currency:      currency
            )
        case .future:
            MiniStatsRow.forFuture(
                projection: vm.projectionData,
                currency:   currency
            )
        }
    }

    // MARK: - Monai note
    private var monaiNote: some View {
        MonaiNoteView(
            context: vm.monthContext,
            note: MonaiNoteView.defaultNote(
                context:     vm.monthContext,
                monthName:   vm.monthName,
                savingsPct:  vm.savingsPct,
                topCategory: vm.topCategory,
                projection:  vm.monthContext == .future ? vm.projectionData : nil
            )
        )
    }

    // MARK: - Sección contextual
    @ViewBuilder
    private var contextualSection: some View {
        switch vm.monthContext {
        case .current:
            UpcomingPaymentsView(
                payments:       vm.upcomingPayments,
                categoryColors: categoryColors
            )
            RecentTransactionsView(
                transactions:   vm.recentTransactions,
                categoryColors: categoryColors,
                categoryEmojis: categoryEmojis,
                onSelect:       { selectedTransaction = $0 },
                onDelete:       { requestDelete($0) }
            )
        case .future:
            ProjectionBreakdownView(
                projection: vm.projectionData,
                currency:   currency
            )
        case .past:
            RecentTransactionsView(
                transactions:   vm.recentTransactions,
                categoryColors: categoryColors,
                categoryEmojis: categoryEmojis,
                onSelect:       { selectedTransaction = $0 },
                onDelete:       { requestDelete($0) }
            )
        }
    }

    // MARK: - Bottom bar
    private var bottomBar: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color.finaBackground.opacity(0), Color.finaBackground],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 100)
            .allowsHitTesting(false)

            HStack(alignment: .bottom, spacing: 0) {

                // Nueva transacción
                Button { showNewTransaction = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.finaForeground)
                        .frame(width: 48, height: 48)
                        .background(Color.finaBackground)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.10), radius: 10, y: 3)
                }

                // Reportes — junto al +
                Button { showReports = true } label: {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.finaMutedForeground)
                        .frame(width: 48, height: 48)
                        .background(Color.finaBackground)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.10), radius: 10, y: 3)
                }
                .padding(.leading, 8)

                Spacer()

                // Mic / voz
                Button { showVoiceInput = true } label: {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color(red: 0.937, green: 0.267, blue: 0.267))
                        .clipShape(Circle())
                        .shadow(color: Color(red: 0.937, green: 0.267, blue: 0.267).opacity(0.35),
                                radius: 12, y: 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Nav button
    private func navButton(icon: String, onTap: @escaping () -> Void) -> some View {
        Button { onTap() } label: {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.finaMutedForeground)
                .frame(width: 32, height: 32)
                .background(Color.finaMuted)
                .clipShape(Circle())
        }
    }
}

#Preview {
    DashboardView(txPrefill: .constant(nil))
        .environment(AuthManager())
}
