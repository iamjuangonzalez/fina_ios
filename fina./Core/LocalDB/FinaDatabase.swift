import SwiftData
import Foundation

// MARK: - FinaDatabase
// Punto central de configuración de SwiftData.
// Uso:
//   .modelContainer(FinaDatabase.container)   → en FinaApp
//   @Environment(\.modelContext) var ctx       → en cualquier View / ViewModel

enum FinaDatabase {

    // Todos los modelos que persisten localmente
    static let schema = Schema([
        CategoryRecord.self,
        TxRecord.self,
        AISession.self,
        AIMessage.self,
        VoiceCommand.self,
        AIInsight.self,
    ])

    static let container: ModelContainer = {
        let config = ModelConfiguration(
            "fina",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("[FinaDB] No se pudo crear el ModelContainer: \(error)")
        }
    }()
}

// MARK: - FinaDB actor
// Wrapper seguro para operaciones de escritura en background.
// Uso: await FinaDB.shared.save(session)

@globalActor
actor FinaDBActor: GlobalActor {
    static let shared = FinaDBActor()
}

// MARK: - Helpers de contexto en MainActor
// Extensiones convenientes para usar desde Views/ViewModels en el hilo principal.

extension ModelContext {

    // Guarda e ignora el error (útil para operaciones de bajo riesgo)
    func safeSave() {
        do { try save() } catch { print("[FinaDB] save error:", error) }
    }

    // Shortcut: inserta y guarda en una sola llamada
    func insertAndSave<T: PersistentModel>(_ model: T) {
        insert(model)
        safeSave()
    }
}
