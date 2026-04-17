import SwiftUI
import SwiftData

// MARK: - ReportsView
// Contenedor principal con selector de 3 tabs.

struct ReportsView: View {
    @Environment(\.modelContext)  private var ctx
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss)       private var dismiss
    @AppStorage("appCurrency")    private var currency: String = "COP"

    @State private var vm          = ReportsViewModel()
    @State private var selectedTab = 0

    @Query(filter: #Predicate<CategoryRecord> { !$0.isDeleted })
    private var categories: [CategoryRecord]

    private let tabs = ["Reportes", "Tendencias", "Proyección"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Tab selector
                tabPicker
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                Divider().foregroundStyle(Color.finaBorder)

                // Contenido del tab activo
                switch selectedTab {
                case 0:
                    OverviewReportTab(vm: vm, currency: currency)
                case 1:
                    TrendsReportTab(vm: vm, currency: currency)
                default:
                    ProjectionReportTab(vm: vm, currency: currency)
                }
            }
            .background(Color.finaBackground)
            .navigationTitle(tabs[selectedTab])
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    monthPicker
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar") { dismiss() }
                        .font(.system(size: 15))
                        .foregroundStyle(Color.finaForeground)
                }
            }
        }
        .onAppear {
            vm.setup(context: ctx, userId: auth.userId, categories: categories)
        }
        .onChange(of: categories) { _, new in
            vm.updateCategories(new)
        }
    }

    // MARK: - Tab picker (segmented)
    private var tabPicker: some View {
        HStack(spacing: 4) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { i, label in
                Button {
                    withAnimation(.spring(duration: 0.25)) { selectedTab = i }
                } label: {
                    Text(label)
                        .font(.system(size: 13, weight: selectedTab == i ? .semibold : .regular))
                        .foregroundStyle(selectedTab == i ? Color.finaForeground : Color.finaMutedForeground)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(selectedTab == i ? Color.finaCard : Color.clear)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(
                                selectedTab == i ? Color.finaBorder : Color.clear,
                                lineWidth: 1
                            )
                        )
                }
                .animation(.spring(duration: 0.25), value: selectedTab)
            }
            Spacer()
        }
    }

    // MARK: - Month picker (en toolbar)
    private var monthPicker: some View {
        HStack(spacing: 4) {
            Button { vm.prevMonth() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.finaMutedForeground)
            }

            Text(vm.monthLabel)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.finaForeground)

            Button { vm.nextMonth() } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.finaMutedForeground)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.finaMuted)
        .clipShape(Capsule())
    }
}
