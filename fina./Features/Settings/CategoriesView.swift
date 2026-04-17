import SwiftUI
import SwiftData

// MARK: - ViewModel

@MainActor
@Observable
final class CategoriesViewModel {

    var categories:   [CategoryRecord] = []
    var showCustom    = false
    var deleteError:  String?          = nil   // nombre de categoría bloqueada

    private var context: ModelContext?

    func setup(context: ModelContext) {
        self.context = context
        load()
        migrateFromUserDefaultsIfNeeded()
    }

    // MARK: Persistencia SwiftData
    private func load() {
        guard let context else { return }
        var descriptor = FetchDescriptor<CategoryRecord>(
            predicate: #Predicate { !$0.isDeleted },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        descriptor.fetchLimit = 200
        categories = (try? context.fetch(descriptor)) ?? []
    }

    // MARK: Acciones
    func addCustom(name: String, emoji: String, color: String) {
        guard let context else { return }
        let id = "custom_\(UUID().uuidString.prefix(8).lowercased())"
        let record = CategoryRecord(
            id:        id,
            name:      name,
            emoji:     emoji,
            color:     color,
            sortOrder: categories.count
        )
        context.insertAndSave(record)
        load()
    }

    func remove(at offsets: IndexSet) {
        for cat in offsets.map({ categories[$0] }) {
            attemptRemove(cat)
        }
    }

    func remove(_ category: CategoryRecord) {
        attemptRemove(category)
    }

    func removeById(_ id: String) {
        guard let existing = categories.first(where: { $0.id == id }) else { return }
        attemptRemove(existing)
    }

    // Verifica que ninguna transacción use la categoría antes de eliminarla.
    private func attemptRemove(_ category: CategoryRecord) {
        guard let context else { return }
        let catId = category.id
        let descriptor = FetchDescriptor<TxRecord>(
            predicate: #Predicate { $0.categoryId == catId }
        )
        let count = (try? context.fetchCount(descriptor)) ?? 0
        if count > 0 {
            deleteError = "\"\(category.name)\" está en uso en \(count) transacción\(count == 1 ? "" : "es") y no se puede eliminar."
        } else {
            category.isDeleted = true
            context.safeSave()
            load()
        }
    }

    // MARK: Migración desde UserDefaults (una sola vez)
    private func migrateFromUserDefaultsIfNeeded() {
        guard let context else { return }
        let legacyKey    = "user_categories_v1"
        let migrationKey = "categories_migrated_to_swiftdata"

        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        if !categories.isEmpty {
            UserDefaults.standard.set(true, forKey: migrationKey)
            return
        }

        struct LegacyCat: Codable { var id, name, emoji, color: String }
        if let data   = UserDefaults.standard.data(forKey: legacyKey),
           let legacy = try? JSONDecoder().decode([LegacyCat].self, from: data),
           !legacy.isEmpty {
            legacy.enumerated().forEach { i, cat in
                let record = CategoryRecord(id: cat.id, name: cat.name,
                                            emoji: cat.emoji, color: cat.color,
                                            sortOrder: i)
                context.insert(record)
            }
            context.safeSave()
            UserDefaults.standard.removeObject(forKey: legacyKey)
        } else {
            DEFAULT_CATEGORIES.enumerated().forEach { i, entry in
                let record = CategoryRecord(id: entry.id, name: entry.name,
                                            emoji: entry.emoji, color: entry.color,
                                            sortOrder: i)
                context.insert(record)
            }
            context.safeSave()
        }

        UserDefaults.standard.set(true, forKey: migrationKey)
        load()
    }
}

// MARK: - Vista principal
struct CategoriesView: View {
    @Environment(\.dismiss)      private var dismiss
    @Environment(\.modelContext) private var ctx
    @State private var vm = CategoriesViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.finaBackground.ignoresSafeArea()
                if vm.categories.isEmpty { emptyState } else { categoryList }
            }
            .navigationTitle("Categorías")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.finaForeground)
                            .frame(width: 32, height: 32)
                            .background(Color.finaMuted)
                            .clipShape(Circle())
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { vm.showCustom = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.finaPrimaryForeground)
                            .frame(width: 32, height: 32)
                            .background(Color.finaPrimary)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .onAppear { vm.setup(context: ctx) }
        .alert("No se puede eliminar", isPresented: Binding(
            get: { vm.deleteError != nil },
            set: { if !$0 { vm.deleteError = nil } }
        )) {
            Button("Entendido", role: .cancel) { vm.deleteError = nil }
        } message: {
            Text(vm.deleteError ?? "")
        }
        .sheet(isPresented: $vm.showCustom) {
            CustomCategorySheet { name, emoji, color in
                vm.addCustom(name: name, emoji: emoji, color: color)
            }
            .finaColorScheme()
        }
    }

    // MARK: Lista
    private var categoryList: some View {
        List {
            Section {
                ForEach(vm.categories) { cat in
                    categoryRow(cat)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                vm.remove(cat)
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                }
            } header: {
                Text("MIS CATEGORÍAS")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.finaMutedForeground)
                    .kerning(0.8)
            } footer: {
                Text("Desliza a la izquierda para eliminar.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.finaMutedForeground)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.finaBackground)
    }

    private func categoryRow(_ cat: CategoryRecord) -> some View {
        HStack(spacing: 12) {
            BrandIconView(iconKey: cat.id, emoji: cat.emoji, color: cat.color, size: 40)
            Text(cat.name)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.finaForeground)
            Spacer()
        }
        .padding(.vertical, 2)
        .listRowBackground(Color.finaCard)
    }

    // MARK: Estado vacío
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tag")
                .font(.system(size: 40))
                .foregroundStyle(Color.finaMutedForeground)
            Text("Sin categorías")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.finaForeground)
            Text("Crea categorías personalizadas\npara organizar tus gastos.")
                .font(.system(size: 14))
                .foregroundStyle(Color.finaMutedForeground)
                .multilineTextAlignment(.center)
            Button { vm.showCustom = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Nueva categoría")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.finaPrimaryForeground)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.finaPrimary)
                .cornerRadius(12)
            }
        }
        .padding()
    }
}

// MARK: - Preview
#Preview {
    CategoriesView()
        .modelContainer(FinaDatabase.container)
}
