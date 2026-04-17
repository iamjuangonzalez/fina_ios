import AppIntents
import SwiftData
import Foundation

// MARK: - Errores
enum FinaIntentError: Error, CustomLocalizedStringResourceConvertible {
    case notLoggedIn
    case saveFailed(String)
    case noAmountFound

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notLoggedIn:        return "Debes iniciar sesión en fina. primero."
        case .saveFailed(let m):  return "No se pudo guardar: \(m)"
        case .noAmountFound:      return "No se encontró ningún monto en el mensaje."
        }
    }
}

// MARK: - 1. Automatización de Apple Pay
// Corre en background — no abre la app.
// Trigger recomendado: Atajos → Automatización → Transacción (Cartera)
// Conectar: Monto = Entrada de shortcut → Monto
//           Comercio = Entrada de shortcut → Comercio
struct ApplePayAutomationIntent: AppIntent {

    static var title: LocalizedStringResource = "Automatización de Apple Pay"
    static var description = IntentDescription(
        "Registra automáticamente un pago de Apple Pay en fina. Usar con la automatización 'Transacción' de Atajos.",
        categoryName: "Transacciones"
    )
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Monto", description: "Monto del pago — conectar a 'Entrada de shortcut → Monto'")
    var amount: Double

    @Parameter(title: "Comercio", description: "Nombre del comercio — conectar a 'Entrada de shortcut → Comercio'")
    var merchant: String

    @Parameter(title: "Moneda", description: "Código de moneda (COP, USD…) — conectar a 'Entrada de shortcut → Código de divisa'")
    var currency: String?

    @Parameter(title: "Tarjeta", description: "Nombre o últimos 4 dígitos de la tarjeta usada")
    var card: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Registrar \(\.$amount) en \(\.$merchant)") {
            \.$currency
            \.$card
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let userId = UserDefaults.standard.string(forKey: "fina_user_id"),
              !userId.isEmpty else { throw FinaIntentError.notLoggedIn }

        let resolvedCurrency = currency
            ?? UserDefaults.standard.string(forKey: "appCurrency")
            ?? "COP"

        let desc = card.map { "\(merchant) (\($0))" } ?? merchant

        try await saveTx(userId: userId, amount: amount, type: "expense",
                        desc: desc, currency: resolvedCurrency)

        return .result(dialog: "✓ \(merchant) registrado en fina.")
    }
}

// MARK: - 2. Nueva transacción
// Abre la app con datos pre-cargados.
struct NewTransactionIntent: AppIntent {

    static var title: LocalizedStringResource = "Nueva transacción"
    static var description = IntentDescription(
        "Abre fina. para registrar una nueva transacción.",
        categoryName: "Transacciones"
    )
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Monto", description: "Monto de la transacción (opcional)")
    var amount: Double?

    @Parameter(title: "Descripción", description: "Descripción del gasto (opcional)")
    var merchant: String?

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults.standard
        if let a = amount   { defaults.set(a,    forKey: "intent_prefill_amount") }
        if let m = merchant { defaults.set(m,    forKey: "intent_prefill_merchant") }
        defaults.set(true, forKey: "intent_prefill_pending")
        return .result()
    }
}

// MARK: - 3. Transacción desde mensaje
// Abre la app con datos pre-cargados extraídos de un SMS.
struct TransactionFromMessageIntent: AppIntent {

    static var title: LocalizedStringResource = "Transacción desde mensaje"
    static var description = IntentDescription(
        "Extrae el monto y comercio de un mensaje de texto y abre fina. para revisar antes de guardar.",
        categoryName: "Transacciones"
    )
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Mensaje", description: "Texto del SMS o notificación bancaria")
    var message: String

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults.standard
        if let a = regexAmount(from: message)    { defaults.set(a, forKey: "intent_prefill_amount") }
        if let m = regexMerchant(from: message)  { defaults.set(m, forKey: "intent_prefill_merchant") }
        defaults.set(true, forKey: "intent_prefill_pending")
        return .result()
    }

    private func regexAmount(from text: String) -> Double? {
        let pattern = #"[\$]?\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text)
        else { return nil }
        let raw = String(text[range])
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
        return Double(raw)
    }

    private func regexMerchant(from text: String) -> String? {
        let patterns = [#"(?:en|at|in)\s+([A-Za-záéíóúÁÉÍÓÚñÑ\s]+?)(?:\s+por|\.|,|$)"#]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                  let range = Range(match.range(at: 1), in: text)
            else { continue }
            return String(text[range]).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }
}

// MARK: - 4. SMS Bancario ✨
// Corre en background — no abre la app.
// Usa Claude Haiku para extraer monto, tipo e descripción del SMS y guarda en SwiftData.
struct BankSMSIntent: AppIntent {

    static var title: LocalizedStringResource = "SMS Bancario"
    static var description = IntentDescription(
        "Registra automáticamente una transacción leyendo un SMS bancario con IA. No abre la app.",
        categoryName: "Transacciones"
    )
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Mensaje", description: "Texto del SMS bancario (Bancolombia, Nequi, Davivienda…)")
    var message: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let userId = UserDefaults.standard.string(forKey: "fina_user_id"),
              !userId.isEmpty else { throw FinaIntentError.notLoggedIn }

        // Intentar parseo con IA primero, luego fallback a regex
        let parsed = await parseWithAI(message: message) ?? parseWithRegex(message: message)

        guard let result = parsed, result.amount > 0 else {
            throw FinaIntentError.noAmountFound
        }

        // Guardar en SwiftData
        try await saveTx(
            userId: userId,
            amount: result.amount,
            type:   result.type,
            desc:   result.description
        )

        let sign = result.type == "income" ? "+" : "-"
        let fmt  = formatCOP(result.amount)
        return .result(dialog: "✓ \(result.description) \(sign)\(fmt) guardado en fina.")
    }

    // MARK: IA: Claude Haiku
    private func parseWithAI(message: String) async -> SMSParseResult? {
        let key = APIConfig.anthropicKey
        guard !key.isEmpty, !key.hasPrefix("TU_") else { return nil }
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { return nil }

        let prompt = """
        Eres un parser de SMS bancarios latinoamericanos. Del siguiente SMS extrae:

        - amount: monto en número entero sin puntos ni comas (ej: 14900)
        - type: "expense" si salió dinero (compraste, pagaste, retiraste, transferiste, debitaron), "income" si entró (recibiste, consignaron, te abonaron, ingresó)
        - description: descripción CORTA y ÚTIL en español, siguiendo estas reglas:
          * Si es una COMPRA: usa el nombre del comercio formateado (ej: "APPLE.COM BILL" → "Compra Apple.com", "EXITO BELLO" → "Éxito", "RAPPI*RESTAURANTE" → "Rappi")
          * Si es un RETIRO: "Retiro cajero"
          * Si es TRANSFERENCIA ENVIADA: "Transferencia enviada" (si hay nombre del destinatario, úsalo: "Transferencia a Carlos")
          * Si es TRANSFERENCIA RECIBIDA: si hay nombre del remitente úsalo ("Te transfirió María", "Recibiste de Juan"), si no hay nombre "Transferencia recibida"
          * Si es PAGO DE SERVICIO: "Pago [servicio]" (ej: "Pago Netflix", "Pago PSE Claro")
          * Si es RECARGA: "Recarga [operador]"
          * Máximo 30 caracteres. Sin mencionar el banco.

        SMS: "\(message)"

        Responde ÚNICAMENTE en JSON: {"amount": 14900, "type": "expense", "description": "Compra Apple.com"}
        Si no es mensaje bancario: {"amount": 0, "type": "expense", "description": ""}
        """

        let body: [String: Any] = [
            "model":    "claude-haiku-4-5-20251001",
            "max_tokens": 60,
            "system":   "Eres un parser de SMS bancarios. Responde solo en JSON.",
            "messages": [["role": "user", "content": prompt]]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(key,               forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01",      forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody        = try? JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 8

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json    = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let text    = content.first?["text"] as? String
        else { return nil }

        // Extraer JSON de la respuesta
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let jsonData  = cleaned.data(using: .utf8),
              let parsed    = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let amount    = parsed["amount"] as? Double, amount > 0,
              let type      = parsed["type"]   as? String,
              let desc      = parsed["description"] as? String, !desc.isEmpty
        else { return nil }

        return SMSParseResult(amount: amount, type: type, description: desc)
    }

    // MARK: Fallback: regex para bancos colombianos
    private func parseWithRegex(message: String) -> SMSParseResult? {
        let lower = message.lowercased()

        // Detectar tipo
        let expenseWords = ["transferiste","pagaste","retiraste","debitaron","realizaste","compraste","enviaste"]
        let incomeWords  = ["recibiste","consignaron","depositaron","te abonaron","ingresó","acreditaron"]
        let type: String = {
            if incomeWords.contains(where: { lower.contains($0) })  { return "income" }
            if expenseWords.contains(where: { lower.contains($0) }) { return "expense" }
            return "expense"   // default
        }()

        // Extraer monto — patrón colombiano: $50.000 o $50,000 o 50000
        let amountPatterns = [
            #"\$\s*([\d]{1,3}(?:[.,]\d{3})+)"#,   // $50.000 o $50,000
            #"\$\s*(\d+)"#,                          // $50000
            #"(\d{1,3}(?:\.\d{3})+)"#,              // 50.000 sin $
        ]
        var amount: Double?
        for pattern in amountPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: message, range: NSRange(message.startIndex..., in: message)),
                  let range = Range(match.range(at: 1), in: message)
            else { continue }
            let raw = String(message[range])
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: "")
            amount = Double(raw)
            break
        }
        guard let amt = amount else { return nil }

        // Detectar tipo de operación más específico
        let purchaseWords  = ["compraste", "compra en", "compra con", "pagaste en"]
        let withdrawWords  = ["retiraste", "retiro en", "cajero"]
        let sentWords      = ["transferiste", "enviaste", "transferencia a"]
        let serviceWords   = ["pse", "recarga", "pago de servicio"]

        let desc: String = {
            // Compra: intentar extraer nombre del comercio
            if purchaseWords.contains(where: { lower.contains($0) }) {
                // Patrón: "en NOMBRE_COMERCIO con" o "en NOMBRE_COMERCIO el"
                let pattern = #"(?:en|EN)\s+([A-Z0-9 .*_\-]+?)(?:\s+con|\s+el\s+\d|\s*,)"#
                if let regex = try? NSRegularExpression(pattern: pattern),
                   let match = regex.firstMatch(in: message, range: NSRange(message.startIndex..., in: message)),
                   let range = Range(match.range(at: 1), in: message) {
                    let raw = String(message[range]).trimmingCharacters(in: .whitespaces)
                    let merchant = raw.split(separator: "*").first.map(String.init) ?? raw
                    return "Compra \(merchant.prefix(20))"
                }
                return "Compra"
            }
            if withdrawWords.contains(where: { lower.contains($0) }) { return "Retiro cajero" }
            if sentWords.contains(where: { lower.contains($0) })     { return "Transferencia enviada" }
            if lower.contains("pse")                                  { return "Pago PSE" }
            if lower.contains("recarga")                              { return "Recarga" }
            if type == "income"                                       { return "Transferencia recibida" }

            // Fallback: banco detectado
            let bankMap: [(String, String)] = [
                ("bancolombia", "Bancolombia"),
                ("nequi",       "Nequi"),
                ("daviplata",   "Daviplata"),
                ("davivienda",  "Davivienda"),
                ("bbva",        "BBVA"),
                ("itaú",        "Itaú"),
                ("scotiabank",  "Scotiabank"),
            ]
            let bank = bankMap.first(where: { lower.contains($0.0) })?.1 ?? ""
            return type == "income" ? "Ingreso \(bank)".trimmingCharacters(in: .whitespaces)
                                    : "Gasto \(bank)".trimmingCharacters(in: .whitespaces)
        }()

        return SMSParseResult(amount: amt, type: type, description: desc)
    }
}

// MARK: - Shared helpers

private struct SMSParseResult {
    let amount:      Double
    let type:        String   // "expense" | "income"
    let description: String
}

// Guarda una TxRecord en SwiftData desde un App Intent.
// Usa el mismo store "fina" que FinaDatabase.
// Sugiere categoría automáticamente con IA antes de guardar.
private func saveTx(userId: String, amount: Double, type: String,
                    desc: String, currency: String? = nil) async throws {
    let schema = Schema([
        CategoryRecord.self, TxRecord.self, AISession.self,
        AIMessage.self, VoiceCommand.self, AIInsight.self,
    ])
    let config    = ModelConfiguration("fina", schema: schema,
                                       isStoredInMemoryOnly: false, allowsSave: true)
    let container = try ModelContainer(for: schema, configurations: [config])
    let ctx       = ModelContext(container)

    // Obtener categorías disponibles del usuario
    let catDescriptor = FetchDescriptor<CategoryRecord>(
        predicate: #Predicate<CategoryRecord> { !$0.isDeleted },
        sortBy: [SortDescriptor(\.sortOrder)]
    )
    let categories = (try? ctx.fetch(catDescriptor)) ?? []

    // Sugerir categoría con IA (local keywords + Claude Haiku como fallback)
    let categoryId: String
    if let suggested = await CategorySuggester.suggest(description: desc, categories: categories) {
        categoryId = suggested
    } else if let fallback = categories.first {
        // Último recurso: primera categoría disponible
        categoryId = fallback.id
    } else {
        categoryId = "general"
    }

    let dateStr = { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date()) }()
    let tx = TxRecord(
        userId:     userId,
        categoryId: categoryId,
        type:       type,
        amount:     amount,
        currency:   currency ?? UserDefaults.standard.string(forKey: "appCurrency") ?? "COP",
        desc:       desc,
        date:       dateStr
    )
    ctx.insert(tx)
    try ctx.save()

    // Notificación local con categoría resuelta
    let matchedCat = categories.first { $0.id == categoryId }
    FinaNotifications.sendTransaction(
        amount:        amount,
        desc:          desc,
        type:          type,
        categoryEmoji: matchedCat?.emoji ?? "",
        categoryName:  matchedCat?.name  ?? "",
        currency:      currency ?? UserDefaults.standard.string(forKey: "appCurrency") ?? "COP"
    )
}

private func formatCOP(_ amount: Double) -> String {
    if amount >= 1_000_000 { return "\(String(format: "%.1f", amount / 1_000_000))M" }
    if amount >= 1_000     { return "\(Int(amount / 1_000))k" }
    return "\(Int(amount))"
}
