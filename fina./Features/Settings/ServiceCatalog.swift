import Foundation

// MARK: - Modelos del catálogo
struct CatalogEntry: Identifiable, Hashable {
    let id: String     // key / iconKey (ej. "netflix") — se usa para lookup de SVG en BrandIconView
    let name: String
    let emoji: String  // fallback cuando no hay SVG registrado para este id
    let color: String  // hex
}

struct CatalogSection: Identifiable {
    let id: String
    let name: String
    let entries: [CatalogEntry]
}

// MARK: - Catálogo completo (espeja service-catalog.ts)
let SERVICE_CATALOG: [CatalogSection] = [

    .init(id: "streaming", name: "Streaming", entries: [
        .init(id: "netflix",       name: "Netflix",        emoji: "🎬", color: "#E50914"),
        .init(id: "spotify",       name: "Spotify",        emoji: "🎵", color: "#1DB954"),
        .init(id: "disneyplus",    name: "Disney+",        emoji: "✨", color: "#113CCF"),
        .init(id: "hbomax",        name: "Max",            emoji: "📺", color: "#002BE7"),
        .init(id: "primevideo",    name: "Prime Video",    emoji: "🎥", color: "#00A8E0"),
        .init(id: "appletv",       name: "Apple TV+",      emoji: "🍎", color: "#000000"),
        .init(id: "crunchyroll",   name: "Crunchyroll",    emoji: "🍥", color: "#F47521"),
        .init(id: "paramountplus", name: "Paramount+",     emoji: "⛰️", color: "#0064FF"),
    ]),

    .init(id: "music", name: "Música", entries: [
        .init(id: "applemusic",    name: "Apple Music",    emoji: "🎶", color: "#FC3C44"),
        .init(id: "youtubemusic",  name: "YouTube Music",  emoji: "🎧", color: "#FF0000"),
        .init(id: "tidal",         name: "Tidal",          emoji: "🌊", color: "#000000"),
        .init(id: "deezer",        name: "Deezer",         emoji: "🎸", color: "#FEAA2D"),
        .init(id: "amazonmusic",   name: "Amazon Music",   emoji: "🎼", color: "#00A8E0"),
    ]),

    .init(id: "productivity", name: "Productividad", entries: [
        .init(id: "notion",        name: "Notion",         emoji: "📝", color: "#000000"),
        .init(id: "slack",         name: "Slack",          emoji: "💬", color: "#4A154B"),
        .init(id: "microsoftoffice",name:"Microsoft 365",  emoji: "📊", color: "#D83B01"),
        .init(id: "googleone",     name: "Google One",     emoji: "☁️", color: "#4285F4"),
        .init(id: "dropbox",       name: "Dropbox",        emoji: "📂", color: "#0061FF"),
        .init(id: "adobe",         name: "Adobe CC",       emoji: "🅰️", color: "#FF0000"),
        .init(id: "chatgpt",       name: "ChatGPT",        emoji: "🤖", color: "#10A37F"),
        .init(id: "figma",         name: "Figma",          emoji: "🎨", color: "#F24E1E"),
    ]),

    .init(id: "gaming", name: "Juegos", entries: [
        .init(id: "playstation",   name: "PlayStation Plus", emoji: "🎮", color: "#003087"),
        .init(id: "xbox",          name: "Xbox Game Pass",  emoji: "🕹️", color: "#107C10"),
        .init(id: "nintendo",      name: "Nintendo Switch", emoji: "🔴", color: "#E4000F"),
        .init(id: "steam",         name: "Steam",           emoji: "🖥️", color: "#1B2838"),
        .init(id: "epicgames",     name: "Epic Games",      emoji: "🎯", color: "#313131"),
    ]),

    .init(id: "food", name: "Delivery & Comida", entries: [
        .init(id: "ubereats",      name: "Uber Eats",      emoji: "🛵", color: "#06C167"),
        .init(id: "rappi",         name: "Rappi",          emoji: "🦊", color: "#FF441F"),
        .init(id: "doordash",      name: "DoorDash",       emoji: "🚪", color: "#FF3008"),
        .init(id: "ifood",         name: "iFood",          emoji: "🍕", color: "#EA1D2C"),
    ]),

    .init(id: "transport", name: "Transporte", entries: [
        .init(id: "uber",          name: "Uber",           emoji: "🚗", color: "#000000"),
        .init(id: "lyft",          name: "Lyft",           emoji: "🚕", color: "#FF00BF"),
        .init(id: "cabify",        name: "Cabify",         emoji: "🟣", color: "#7C3AED"),
        .init(id: "indrive",       name: "inDrive",        emoji: "🚘", color: "#73E849"),
        .init(id: "metro",         name: "Metro / Bus",    emoji: "🚌", color: "#2563EB"),
    ]),

    .init(id: "cloud", name: "Cloud & Dev", entries: [
        .init(id: "github",        name: "GitHub",         emoji: "🐙", color: "#181717"),
        .init(id: "vercel",        name: "Vercel",         emoji: "▲",  color: "#000000"),
        .init(id: "aws",           name: "AWS",            emoji: "☁️", color: "#FF9900"),
        .init(id: "digitalocean",  name: "DigitalOcean",   emoji: "💧", color: "#0080FF"),
        .init(id: "supabase",      name: "Supabase",       emoji: "⚡", color: "#3ECF8E"),
        .init(id: "mongodb",       name: "MongoDB Atlas",  emoji: "🍃", color: "#47A248"),
    ]),

    .init(id: "education", name: "Educación", entries: [
        .init(id: "duolingo",      name: "Duolingo",       emoji: "🦉", color: "#58CC02"),
        .init(id: "coursera",      name: "Coursera",       emoji: "🎓", color: "#0056D2"),
        .init(id: "udemy",         name: "Udemy",          emoji: "📖", color: "#A435F0"),
        .init(id: "masterclass",   name: "MasterClass",    emoji: "🏆", color: "#000000"),
        .init(id: "linkedin",      name: "LinkedIn Learning", emoji: "💼", color: "#0A66C2"),
        .init(id: "domestika",     name: "Domestika",      emoji: "🎭", color: "#FD4A4A"),
    ]),

    .init(id: "finance", name: "Finanzas", entries: [
        .init(id: "nequi",         name: "Nequi",          emoji: "💜", color: "#7C3AED"),
        .init(id: "nubank",        name: "Nubank",         emoji: "💳", color: "#8A05BE"),
        .init(id: "mercadopago",   name: "Mercado Pago",   emoji: "💰", color: "#009EE3"),
        .init(id: "paypal",        name: "PayPal",         emoji: "🅿️", color: "#00457C"),
        .init(id: "revolut",       name: "Revolut",        emoji: "🔷", color: "#191C1F"),
    ]),

    .init(id: "health", name: "Salud & Fitness", entries: [
        .init(id: "gym",           name: "Gimnasio",       emoji: "🏋️", color: "#EF4444"),
        .init(id: "applefitness",  name: "Apple Fitness+", emoji: "🏃", color: "#FC3C44"),
        .init(id: "strava",        name: "Strava",         emoji: "🚴", color: "#FC4C02"),
        .init(id: "headspace",     name: "Headspace",      emoji: "🧘", color: "#F47D31"),
        .init(id: "calm",          name: "Calm",           emoji: "😌", color: "#3E5FCC"),
    ]),

    .init(id: "general", name: "Categorías generales", entries: [
        .init(id: "food_general",      name: "Alimentación",   emoji: "🍔", color: "#F97316"),
        .init(id: "transport_general", name: "Transporte",     emoji: "🚗", color: "#3B82F6"),
        .init(id: "health_general",    name: "Salud",          emoji: "🏥", color: "#10B981"),
        .init(id: "entertainment",     name: "Entretenimiento",emoji: "🎬", color: "#8B5CF6"),
        .init(id: "home",              name: "Hogar",          emoji: "🏠", color: "#F59E0B"),
        .init(id: "education_general", name: "Educación",      emoji: "📚", color: "#06B6D4"),
        .init(id: "clothing",          name: "Ropa",           emoji: "👕", color: "#EC4899"),
        .init(id: "pets",              name: "Mascotas",       emoji: "🐶", color: "#84CC16"),
        .init(id: "travel",            name: "Viajes",         emoji: "✈️", color: "#0EA5E9"),
        .init(id: "savings",           name: "Ahorro",         emoji: "🐷", color: "#22C55E"),
        .init(id: "salary",            name: "Salario",        emoji: "💵", color: "#EAB308"),
        .init(id: "freelance",         name: "Freelance",      emoji: "💻", color: "#A855F7"),
        .init(id: "gifts",             name: "Regalos",        emoji: "🎁", color: "#F43F5E"),
        .init(id: "beauty",            name: "Belleza",        emoji: "💄", color: "#E879F9"),
        .init(id: "sports",            name: "Deporte",        emoji: "⚽", color: "#F97316"),
    ]),
]

// MARK: - Defaults (espeja DEFAULT_USER_CATEGORIES de service-catalog.ts)
let DEFAULT_CATEGORIES: [CatalogEntry] = [
    .init(id: "food_general",      name: "Alimentación",   emoji: "🍔", color: "#F97316"),
    .init(id: "transport_general", name: "Transporte",     emoji: "🚗", color: "#3B82F6"),
    .init(id: "health_general",    name: "Salud",          emoji: "🏥", color: "#10B981"),
    .init(id: "entertainment",     name: "Entretenimiento",emoji: "🎬", color: "#8B5CF6"),
    .init(id: "home",              name: "Hogar",          emoji: "🏠", color: "#F59E0B"),
    .init(id: "education_general", name: "Educación",      emoji: "📚", color: "#06B6D4"),
    .init(id: "clothing",          name: "Ropa",           emoji: "👕", color: "#EC4899"),
    .init(id: "savings",           name: "Ahorro",         emoji: "🐷", color: "#22C55E"),
    .init(id: "salary",            name: "Salario",        emoji: "💵", color: "#EAB308"),
    .init(id: "freelance",         name: "Freelance",      emoji: "💻", color: "#A855F7"),
]
