import Foundation

// MARK: - ParsedVoiceIntent
struct ParsedVoiceIntent {
    var amount:       Double?
    var description:  String?
    var categoryId:   String?
    var txType:       String  = "expense"   // "expense" | "income"
    var dateOffset:   Int     = 0           // 0=hoy, -1=ayer
}

// MARK: - VoiceParser
// Extrae intención financiera del texto transcrito en español colombiano.
// Sin dependencias externas — solo regex y keyword matching.

struct VoiceParser {

    static func parse(_ raw: String) -> ParsedVoiceIntent {
        var intent   = ParsedVoiceIntent()
        let text     = raw.lowercased()
            .replacingOccurrences(of: ",", with: "")
            .folding(options: .diacriticInsensitive, locale: .current)

        intent.txType      = extractType(text)
        intent.dateOffset  = extractDate(text)
        intent.amount      = extractAmount(text)
        intent.categoryId  = extractCategory(text)
        intent.description = cleanDescription(text)
        return intent
    }

    // MARK: - Tipo (gasto / ingreso)
    private static func extractType(_ text: String) -> String {
        let incomeWords = ["ingreso","recibi","me pagaron","cobré","cobré","cobré","gané","deposito","transferencia recibida"]
        if incomeWords.contains(where: { text.contains($0) }) { return "income" }
        return "expense"
    }

    // MARK: - Fecha
    private static func extractDate(_ text: String) -> Int {
        if text.contains("ayer")         { return -1 }
        if text.contains("anteayer")     { return -2 }
        return 0
    }

    // MARK: - Monto
    // Entiende: "50 mil", "50000", "1.5 millones", "30k", "doscientos mil"
    private static func extractAmount(_ text: String) -> Double? {
        // 1. Número explícito + modificador (50 mil, 1.5 millones)
        let modifierPattern = #"(\d+[\.,]?\d*)\s*(mil(?:lon(?:es)?)?|k|lucas|millones?)"#
        if let match = text.range(of: modifierPattern, options: .regularExpression) {
            let fragment = String(text[match])
            let parts    = fragment.components(separatedBy: .whitespaces)
            if let base = Double(parts[0].replacingOccurrences(of: ".", with: "")
                                          .replacingOccurrences(of: ",", with: ".")) {
                let modifier = parts.last ?? ""
                if modifier.hasPrefix("millon") { return base * 1_000_000 }
                return base * 1_000   // mil / k / lucas
            }
        }

        // 2. Número puro (sin modificador): "35000", "150"
        let digitPattern = #"\b(\d{2,9})\b"#
        let regex = try? NSRegularExpression(pattern: digitPattern)
        let ns    = text as NSString
        let matches = regex?.matches(in: text, range: NSRange(location: 0, length: ns.length)) ?? []
        if let m = matches.first {
            let numStr = ns.substring(with: m.range(at: 1))
                           .replacingOccurrences(of: ".", with: "")
            return Double(numStr)
        }

        // 3. Palabras de decenas/centenas (básico)
        let wordMap: [(String, Double)] = [
            ("cien mil", 100_000), ("cincuenta mil", 50_000),
            ("cuarenta mil", 40_000), ("treinta mil", 30_000),
            ("veinte mil", 20_000), ("quince mil", 15_000),
            ("diez mil", 10_000), ("cinco mil", 5_000),
            ("dos mil", 2_000), ("mil", 1_000),
            ("quinientos", 500), ("doscientos", 200), ("cien", 100),
        ]
        for (word, value) in wordMap where text.contains(word) { return value }

        return nil
    }

    // MARK: - Categoría (keyword → id del catálogo)
    private static func extractCategory(_ text: String) -> String? {
        let map: [(keywords: [String], id: String)] = [
            (["netflix"],                          "netflix"),
            (["spotify"],                          "spotify"),
            (["uber","didi","taxi","cabify"],       "transport"),
            (["rappi","domicilio","delivery"],      "rappi"),
            (["mercado","supermercado","tienda","exito","jumbo","d1","ara"], "groceries"),
            (["almuerzo","comida","restaurante","hamburguesa","pizza","sushi"], "food_general"),
            (["gasolina","gas"],                   "fuel"),
            (["gym","gimnasio"],                   "fitness"),
            (["arriendo","renta"],                 "rent"),
            (["medicina","farmacia","drogueria","medicamento"], "health"),
            (["cine","pelicula","teatro"],          "entertainment"),
            (["universidad","colegio","curso","clase"], "education"),
            (["cafe","starbucks","juan valdez"],    "coffee"),
        ]
        for entry in map {
            if entry.keywords.contains(where: { text.contains($0) }) { return entry.id }
        }
        return nil
    }

    // MARK: - Descripción limpia
    private static func cleanDescription(_ text: String) -> String {
        let stopWords = ["gaste","gasté","compré","compre","pague","pagué",
                         "costo","costó","hoy","ayer","anteayer",
                         "en","para","por","de","un","una","me","pesos","cop",
                         "mil","millones","millon","lucas","k"]
        let words = text.split(separator: " ").map(String.init)
        let filtered = words.filter { w in
            !stopWords.contains(w) && !w.allSatisfy(\.isNumber)
        }
        let result = filtered.joined(separator: " ")
        return result.isEmpty ? text : result.prefix(1).uppercased() + result.dropFirst()
    }
}
