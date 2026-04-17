import SwiftData
import Foundation

// MARK: - CategoryRecord
// Reemplaza el almacenamiento en UserDefaults de CategoriesViewModel.
// id == iconKey ("netflix", "food_general") — mismo esquema que el catálogo.

@Model
final class CategoryRecord {
    @Attribute(.unique) var id: String
    var name: String
    var emoji: String
    var color: String           // hex, ej. "#F97316"
    var sortOrder: Int
    var isDeleted: Bool         // soft-delete para sincronizar con Supabase

    init(id: String, name: String, emoji: String, color: String, sortOrder: Int = 0) {
        self.id        = id
        self.name      = name
        self.emoji     = emoji
        self.color     = color
        self.sortOrder = sortOrder
        self.isDeleted = false
    }
}

// MARK: - TxRecord
// Cache local de transacciones de Supabase + drafts creados offline.
// syncStatus lleva el rastro de lo que todavía no se ha subido.

@Model
final class TxRecord {
    @Attribute(.unique) var id: String
    var userId: String
    var categoryId: String      // FK lógico → CategoryRecord.id
    var type: String            // "expense" | "income"
    var amount: Double
    var currency: String
    var desc: String?
    var date: String            // yyyy-MM-dd
    var frequency: String       // "once" | "weekly" | "monthly" | "yearly"
    var nature: String?         // "fixed" | "variable" | "unexpected" | "hormiga"
    var frequencyEnd: String?   // "yyyy-MM" — último mes en que aplica (para recurrentes)
    var seriesId: String?       // UUID compartido entre todos los registros de la misma serie recurrente
    var customColor: String?    // color hex override
    var syncStatus: String      // "synced" | "pending" | "failed"
    var createdAt: Date
    var updatedAt: Date

    // Propiedades de display (sin lookup de DB)
    var displayName: String  { desc ?? categoryId }
    var displayColor: String { customColor ?? "#888888" }

    init(
        id: String       = UUID().uuidString,
        userId: String,
        categoryId: String,
        type: String,
        amount: Double,
        currency: String  = "COP",
        desc: String?     = nil,
        date: String,
        frequency: String = "once",
        nature: String?   = nil,
        syncStatus: String = "pending"
    ) {
        self.id         = id
        self.userId     = userId
        self.categoryId = categoryId
        self.type       = type
        self.amount     = amount
        self.currency   = currency
        self.desc       = desc
        self.date       = date
        self.frequency   = frequency
        self.nature        = nature
        self.frequencyEnd  = nil
        self.seriesId      = nil
        self.customColor   = nil
        self.syncStatus  = syncStatus
        self.createdAt  = Date()
        self.updatedAt  = Date()
    }
}

// MARK: - AISession
// Cada conversación con Monai es una sesión independiente.
// context guarda en JSON el mes activo, cuenta seleccionada, etc.
// para que la IA tenga contexto sin necesitar re-preguntar.

@Model
final class AISession {
    @Attribute(.unique) var id: String
    var userId: String
    var title: String
    var contextJSON: String?    // JSON: { month, accountId, filters }
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \AIMessage.session)
    var messages: [AIMessage] = []

    init(userId: String, title: String = "", contextJSON: String? = nil) {
        self.id          = UUID().uuidString
        self.userId      = userId
        self.contextJSON = contextJSON
        self.createdAt   = Date()
        self.updatedAt   = Date()

        let dateStr = Date().formatted(.dateTime.day().month(.abbreviated))
        self.title = title.isEmpty ? "Conversación \(dateStr)" : title
    }

    var sortedMessages: [AIMessage] {
        messages.sorted { $0.createdAt < $1.createdAt }
    }

    var lastMessage: AIMessage? {
        sortedMessages.last
    }
}

// MARK: - AIMessage
// Un turno dentro de una sesión: puede ser del usuario (texto o voz)
// o de Monai (asistente). actions guarda en JSON cualquier
// transacción creada o acción disparada por ese mensaje.

@Model
final class AIMessage {
    @Attribute(.unique) var id: String
    var role: String            // "user" | "assistant"
    var content: String
    var inputType: String       // "text" | "voice"
    var transcript: String?     // transcripción del audio si fue por voz
    var actionsJSON: String?    // JSON: [{ type, transactionId, ... }]
    var tokensUsed: Int?
    var createdAt: Date

    var session: AISession?

    init(
        role: String,
        content: String,
        inputType: String    = "text",
        transcript: String?  = nil,
        actionsJSON: String? = nil
    ) {
        self.id          = UUID().uuidString
        self.role        = role
        self.content     = content
        self.inputType   = inputType
        self.transcript  = transcript
        self.actionsJSON = actionsJSON
        self.createdAt   = Date()
    }

    var isFromUser: Bool { role == "user" }
    var wasVoice:   Bool { inputType == "voice" }
}

// MARK: - VoiceCommand
// Historial de cada comando de voz enviado a Monai.
// parsedIntentJSON almacena lo que el modelo extrajo del audio:
// { "action": "create_expense", "amount": 80000, "category": "rappi", "date": "today" }

@Model
final class VoiceCommand {
    @Attribute(.unique) var id: String
    var userId: String
    var rawTranscript: String
    var parsedIntentJSON: String?
    var confidence: Double?
    var resultStatus: String    // "applied" | "ignored" | "error" | "pending"
    var transactionId: String?  // si creó una transacción
    var createdAt: Date

    init(userId: String, rawTranscript: String) {
        self.id            = UUID().uuidString
        self.userId        = userId
        self.rawTranscript = rawTranscript
        self.resultStatus  = "pending"
        self.createdAt     = Date()
    }
}

// MARK: - AIInsight
// Observaciones generadas por Monai para mostrar en el dashboard.
// Se guardan localmente para no re-calcularlas en cada apertura.

@Model
final class AIInsight {
    @Attribute(.unique) var id: String
    var userId: String
    var type: String            // "spending_pattern" | "saving_tip" | "anomaly" | "forecast"
    var title: String
    var body: String
    var dataJSON: String?       // JSON con números de respaldo
    var month: String?          // "yyyy-MM" al que aplica
    var isRead: Bool
    var createdAt: Date
    var expiresAt: Date?        // nil = no expira

    init(
        userId: String,
        type: String,
        title: String,
        body: String,
        dataJSON: String? = nil,
        month: String?    = nil,
        expiresAt: Date?  = nil
    ) {
        self.id        = UUID().uuidString
        self.userId    = userId
        self.type      = type
        self.title     = title
        self.body      = body
        self.dataJSON  = dataJSON
        self.month     = month
        self.isRead    = false
        self.createdAt = Date()
        self.expiresAt = expiresAt
    }

    var isExpired: Bool {
        guard let exp = expiresAt else { return false }
        return Date() > exp
    }
}
