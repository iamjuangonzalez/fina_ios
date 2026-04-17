import Foundation

// MARK: - CategorySuggester
// Estrategia en dos fases:
//   Fase 1 — quickMatch: keyword matching local, síncrono, 0ms, sin costo.
//            Si la confianza es alta (score ≥ 8) se usa directamente.
//   Fase 2 — claudeSuggest: Claude Haiku, solo si la fase 1 falla o es baja confianza.
//            Latencia típica: 200–400ms.

struct CategorySuggester {

    // MARK: - API pública

    /// Match local instantáneo. Devuelve el categoryId si score ≥ minScore.
    static func quickMatch(
        _ description: String,
        categories: [CategoryRecord],
        minScore: Int = 5
    ) -> String? {
        localMatch(description, categories: categories, minScore: minScore)
    }

    /// Sugerencia completa: local primero, Claude Haiku como fallback.
    static func suggest(
        description: String,
        categories: [CategoryRecord]
    ) async -> String? {
        guard !description.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }

        // Fase 1: match local con umbral normal
        if let local = localMatch(description, categories: categories, minScore: 5) {
            return local
        }

        // Fase 2: Claude Haiku solo si hay key configurada
        guard APIConfig.hasAnthropicKey else { return nil }
        return await claudeSuggest(description: description, categories: categories)
    }

    // MARK: - Fase 1: keyword matching local

    static func localMatch(
        _ text: String,
        categories: [CategoryRecord],
        minScore: Int = 5
    ) -> String? {
        let normalized = text.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        let keywordMap: [String: [String]] = [
            "food_general":      ["comida","almuerzo","cena","desayuno","hamburguesa","pizza",
                                  "sushi","pollo","carne","restaurante","sandwich","ensalada",
                                  "tacos","arepa","empanada","bandeja","corrientazo","mcdonalds",
                                  "kfc","subway","comida rapida","pola","cerveza","almorcé",
                                  "comi","cené","desayuné","fonda","asadero","parrilla"],
            "transport_general": ["uber","didi","taxi","cabify","bus","metro","transmilenio",
                                  "transporte","gasolina","combustible","parqueadero","moto",
                                  "bicicleta","peaje","tiquete","pasaje","movilidad","beat",
                                  "indrive","sitp","lleno","bencina"],
            "groceries":         ["mercado","supermercado","exito","jumbo","d1","ara","carulla",
                                  "olimpica","alkosto","makro","viveres","frutas","verduras",
                                  "pan","leche","huevos","aseo","compras","despensa","lidl"],
            "netflix":           ["netflix","serie","episodio"],
            "spotify":           ["spotify","musica","canciones","playlist"],
            "hbomax":            ["hbo","max","hbo max","hbomax"],
            "disneyplus":        ["disney","disney plus","disneyplus"],
            "rappi":             ["rappi","domicilio","delivery","pedido","domicilios"],
            "ubereats":          ["uber eats","ubereats","pedido uber"],
            "health_general":    ["medico","doctor","cita","medicina","farmacia","drogueria",
                                  "medicamento","clinica","hospital","salud","examen","laboratorio",
                                  "consulta","eps","colsanitas","sura","vacuna"],
            "entertainment":     ["cine","pelicula","teatro","concierto","evento","show","fiesta",
                                  "bar","discoteca","boliche","tragos","rumba"],
            "education_general": ["universidad","colegio","curso","clase","taller","diplomado",
                                  "matricula","libro","libreria","udemy","coursera","platzi",
                                  "inscripcion","pensión","mensualidad"],
            "clothing":          ["ropa","camisa","pantalon","zapatos","tenis","jean","vestido",
                                  "chaqueta","buzo","camiseta","zapatillas","adidas","nike","zara",
                                  "h&m","pull&bear","bershka","calzado","ropa interior"],
            "travel":            ["hotel","viaje","vuelo","avion","airbnb","hospedaje","booking",
                                  "vacaciones","pasajes","tiquetes","aerolinea","latam","avianca"],
            "home":              ["arriendo","renta","alquiler","arrendamiento","hogar","casa",
                                  "apartamento","servicios","agua","luz","gas","internet","cable",
                                  "muebles","decoracion","ferreteria"],
            "gym":               ["gym","gimnasio","crossfit","yoga","entrenamiento","deporte",
                                  "suplemento","proteina","spinning","piscina","boxeo"],
            "salary":            ["salario","sueldo","nomina","quincena","pago","me pagaron",
                                  "deposito","transferencia","cobré","ingreso"],
            "freelance":         ["freelance","proyecto","cliente","honorarios","factura","cobro"],
            "savings":           ["ahorro","inversion","cdts","acciones","fondos","ahorré"],
            "coffee":            ["cafe","starbucks","juan valdez","tinto","cappuccino","latte",
                                  "americano","espresso","oma","amor perfecto"],
            "beauty":            ["belleza","salon","peluqueria","corte","manicure","pedicure",
                                  "spa","estetica","cosmeticos","maquillaje","perfume"],
            "pets":              ["mascota","veterinario","perro","gato","alimento mascota",
                                  "concentrado","vacuna veterinaria","grooming"],
        ]

        var scores: [String: Int] = [:]

        for cat in categories {
            var score = 0
            let catName = cat.name.lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)

            if normalized.contains(catName) { score += 10 }
            if let kws = keywordMap[cat.id] {
                for kw in kws where normalized.contains(kw) { score += 5 }
            }
            if normalized.contains(cat.id) { score += 8 }

            if score > 0 { scores[cat.id] = score }
        }

        guard let best = scores.max(by: { $0.value < $1.value }),
              best.value >= minScore else { return nil }
        return best.key
    }

    // MARK: - Fase 2: Claude Haiku

    private static func claudeSuggest(
        description: String,
        categories: [CategoryRecord]
    ) async -> String? {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { return nil }

        let catList = categories.map { "\($0.id):\($0.name)" }.joined(separator: ", ")

        let userMessage = """
        Transacción: "\(description)"
        Categorías: \(catList)
        Responde SOLO con el id exacto que mejor encaje. Si ninguna aplica responde: ninguna
        """

        let body: [String: Any] = [
            "model":      "claude-haiku-4-5-20251001",
            "max_tokens": 20,
            "system":     "Eres un clasificador de gastos personales. Responde únicamente con el id de categoría, sin explicación.",
            "messages":   [["role": "user", "content": userMessage]]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(APIConfig.anthropicKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01",            forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json",      forHTTPHeaderField: "content-type")
        request.httpBody        = try? JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 6

        guard let (data, _) = try? await URLSession.shared.data(for: request) else { return nil }

        guard
            let json    = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = json["content"] as? [[String: Any]],
            let text    = content.first?["text"] as? String
        else { return nil }

        let reply = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .newlines).first ?? ""

        guard reply != "ninguna",
              categories.contains(where: { $0.id == reply }) else { return nil }
        return reply
    }
}
