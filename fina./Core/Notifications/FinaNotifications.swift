import UserNotifications
import Foundation

// MARK: - FinaNotifications
// Servicio centralizado de notificaciones locales.
// Úsalo desde App Intents (background) o desde cualquier parte del app.

enum FinaNotifications {

    // MARK: - Configuración de categorías UNNotification
    // Llama a esto una vez al arrancar la app (en FinaApp.init)
    static func registerCategories() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_TRANSACTION",
            title: "Ver transacción",
            options: .foreground
        )
        let transactionCategory = UNNotificationCategory(
            identifier: NotificationCategory.transaction,
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([transactionCategory])
    }

    // MARK: - Categorías
    enum NotificationCategory {
        static let transaction = "FINA_TRANSACTION"
    }

    // MARK: - Enviar notificación de transacción
    static func sendTransaction(
        amount:        Double,
        desc:          String,
        type:          String,       // "expense" | "income"
        categoryEmoji: String = "",
        categoryName:  String = "",
        currency:      String = "COP"
    ) {
        let content = UNMutableNotificationContent()

        // Título según tipo
        if type == "income" {
            content.title = "Ingreso registrado"
        } else {
            content.title = "Gasto registrado"
        }

        // Subtítulo: emoji + nombre de categoría
        if !categoryEmoji.isEmpty || !categoryName.isEmpty {
            content.subtitle = "\(categoryEmoji) \(categoryName)".trimmingCharacters(in: .whitespaces)
        }

        // Cuerpo: descripción · monto formateado
        let sign    = type == "income" ? "+" : "-"
        let amtStr  = formatAmount(amount, currency: currency)
        content.body = "\(desc) · \(sign)\(amtStr)"

        // Agrupación: todas las transacciones en un hilo
        content.threadIdentifier  = "fina.transactions"
        content.categoryIdentifier = NotificationCategory.transaction
        content.sound = .default

        // Icono de la app — se asigna automáticamente
        // userInfo para deep link al abrir
        content.userInfo = ["type": type, "amount": amount, "desc": desc]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil   // inmediata
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("[FinaNotif] Error: \(error)") }
        }
    }

    // MARK: - Formato de monto
    static func formatAmount(_ amount: Double, currency: String) -> String {
        if currency == "COP" {
            if amount >= 1_000_000 {
                return String(format: "$%.1fM", amount / 1_000_000)
            } else if amount >= 1_000 {
                return "$\(Int(amount / 1_000))k"
            } else {
                return "$\(Int(amount))"
            }
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}
