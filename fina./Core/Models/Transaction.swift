import Foundation

// MARK: - Enums
enum TransactionType: String, Codable { case expense, income }
enum Frequency: String, Codable { case once, daily, weekly, monthly, yearly }
enum Nature: String, Codable { case fixed, variable, unexpected, hormiga }

// MARK: - Service (embebido en la query de transacciones)
struct Service: Codable, Identifiable {
    let id: String
    let name: String
    let domain: String?
    let iconUrl: String?
    let color: String?

    enum CodingKeys: String, CodingKey {
        case id, name, domain, color
        case iconUrl = "icon_url"
    }
}

// MARK: - Transaction
struct Transaction: Codable, Identifiable {
    let id: String
    let userId: String
    let serviceId: String
    let type: TransactionType
    let amount: Double
    let currency: String
    let description: String?
    let date: String           // yyyy-MM-dd
    let frequency: Frequency
    let frequencyEnd: String?
    let parentId: String?
    let customIcon: String?
    let customColor: String?
    let nature: Nature?
    let services: Service?

    enum CodingKeys: String, CodingKey {
        case id, type, amount, currency, description, date, frequency, nature, services
        case userId        = "user_id"
        case serviceId     = "service_id"
        case frequencyEnd  = "frequency_end"
        case parentId      = "parent_id"
        case customIcon    = "custom_icon"
        case customColor   = "custom_color"
    }

    // Nombre para mostrar: descripción propia o nombre del servicio
    var displayName: String {
        description ?? services?.name ?? "Sin nombre"
    }

    // Color para mostrar: custom > servicio > gris
    var displayColor: String {
        customColor ?? services?.color ?? "#888888"
    }
}

// MARK: - Formateo de moneda
func formatAmount(_ amount: Double, currency: String = "COP") -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currency
    formatter.maximumFractionDigits = currency == "COP" || currency == "CLP" ? 0 : 2
    return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
}
