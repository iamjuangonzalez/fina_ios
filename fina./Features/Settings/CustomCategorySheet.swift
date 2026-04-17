import SwiftUI

// MARK: - CustomCategorySheet
struct CustomCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    var onConfirm: (String, String, String) -> Void

    @State private var name          = ""
    @State private var selectedEmoji = ""
    @State private var selectedColor = "#EF4444"
    @State private var emojiSearch   = ""

    @FocusState private var nameFieldFocused: Bool
    @FocusState private var searchFocused: Bool

    private let presetColors = [
        "#EF4444","#F97316","#F59E0B","#EAB308",
        "#84CC16","#22C55E","#10B981","#14B8A6",
        "#06B6D4","#3B82F6","#6366F1","#8B5CF6",
        "#A855F7","#EC4899","#F43F5E","#64748B",
    ]

    // Todos los emojis del teclado iOS organizados por sección
    private let allEmojis: [String] = [
        // Caritas
        "😀","😃","😄","😁","😆","😅","🤣","😂","🙂","🙃","😉","😊","😇",
        "🥰","😍","🤩","😘","😗","😚","😙","🥲","😋","😛","😜","🤪","😝",
        "🤑","🤗","🤭","🤫","🤔","🤐","🤨","😐","😑","😶","😏","😒","🙄",
        "😬","🤥","😌","😔","😪","🤤","😴","😷","🤒","🤕","🤢","🤮","🤧",
        "🥵","🥶","🥴","😵","🤯","🤠","🥳","🥸","😎","🤓","🧐","😕","😟",
        "🙁","☹️","😮","😯","😲","😳","🥺","😦","😧","😨","😰","😥","😢",
        "😭","😱","😖","😣","😞","😓","😩","😫","🥱","😤","😡","😠","🤬",
        "😈","👿","💀","☠️","💩","🤡","👹","👺","👻","👽","👾","🤖",
        // Gestos y personas
        "👋","🤚","🖐️","✋","🖖","👌","🤌","🤏","✌️","🤞","🤟","🤘","🤙",
        "👈","👉","👆","🖕","👇","☝️","👍","👎","✊","👊","🤛","🤜","👏",
        "🙌","👐","🤲","🤝","🙏","✍️","💅","🤳","💪","🦾","🦿","🦵","🦶",
        "👂","🦻","👃","🫀","🫁","🧠","🦷","🦴","👀","👁️","👅","👄",
        "🧑","👱","👩","🧔","👴","👵","🙍","🙎","🙅","🙆","💁","🙋","🧏",
        "🙇","🤦","🤷","💆","💇","🚶","🧍","🧎","🏃","💃","🕺","🧖",
        // Amor
        "❤️","🧡","💛","💚","💙","💜","🖤","🤍","🤎","💔","❣️","💕","💞",
        "💓","💗","💖","💘","💝","💟","☮️","✝️","☯️","🔯","🕎","☦️",
        // Animales
        "🐶","🐱","🐭","🐹","🐰","🦊","🐻","🐼","🐨","🐯","🦁","🐮","🐷",
        "🐸","🐵","🙈","🙉","🙊","🐔","🐧","🐦","🐤","🦆","🦅","🦉","🦇",
        "🐺","🐗","🐴","🦄","🐝","🐛","🦋","🐌","🐞","🐜","🦟","🦗","🕷️",
        "🦂","🐢","🐍","🦎","🦖","🦕","🐙","🦑","🦐","🦞","🦀","🐡","🐠",
        "🐟","🐬","🐳","🐋","🦈","🐊","🐅","🐆","🦓","🦍","🦧","🦣","🐘",
        "🦛","🦏","🐪","🐫","🦒","🦘","🦬","🐃","🐂","🐄","🐎","🐖","🐏",
        "🐑","🦙","🐐","🦌","🐕","🐩","🦮","🐕‍🦺","🐈","🐈‍⬛","🪶","🐓","🦃",
        "🦤","🦚","🦜","🦢","🦩","🕊️","🐇","🦝","🦨","🦡","🦫","🦦","🦥",
        "🐁","🐀","🐿️","🦔","🐾","🐉","🐲","🌵","🎄","🌲","🌳","🌴","🌱",
        "🌿","☘️","🍀","🎍","🎋","🍃","🍂","🍁","🍄","🌾","💐","🌷","🌹",
        "🥀","🌺","🌸","🌼","🌻","🌞","🌝","🌛","🌜","🌚","🌕","🌖","🌗",
        "🌘","🌑","🌒","🌓","🌔","🌙","🌟","⭐","🌠","🌌","☀️","⛅","☁️",
        "⛈️","🌤️","🌥️","🌦️","🌧️","🌩️","🌨️","❄️","☃️","⛄","🌬️","💨","🌊",
        "💧","💦","🌈","☔","⚡","🔥","🌪️","🌫️","🌁",
        // Comida
        "🍏","🍎","🍐","🍊","🍋","🍌","🍉","🍇","🍓","🫐","🍈","🍒","🍑",
        "🥭","🍍","🥥","🥝","🍅","🍆","🥑","🥦","🥬","🥒","🌶️","🫑","🌽",
        "🥕","🧄","🧅","🥔","🍠","🥐","🥯","🍞","🥖","🥨","🧀","🥚","🍳",
        "🧈","🥞","🧇","🥓","🥩","🍗","🍖","🦴","🌭","🍔","🍟","🍕","🫓",
        "🌮","🌯","🫔","🥙","🧆","🥚","🍳","🥘","🍲","🫕","🥣","🥗","🍿",
        "🧂","🥫","🍱","🍘","🍙","🍚","🍛","🍜","🍝","🍠","🍢","🍣","🍤",
        "🍥","🥮","🍡","🥟","🦪","🍦","🍧","🍨","🍩","🍪","🎂","🍰","🧁",
        "🥧","🍫","🍬","🍭","🍮","🍯","🍼","🥛","☕","🍵","🧃","🥤","🧋",
        "🍶","🍺","🍻","🥂","🍷","🥃","🍸","🍹","🧉","🍾","🧊","🥄","🍴",
        // Viajes y lugares
        "🚗","🚕","🚙","🚌","🚎","🏎️","🚓","🚑","🚒","🚐","🛻","🚚","🚛",
        "🚜","🏍️","🛵","🚲","🛴","🛹","🛼","🚏","🛣️","🛤️","⛽","🚧","⚓",
        "🪝","⛵","🚤","🛥️","🛳️","⛴️","🚢","✈️","🛩️","🛫","🛬","🪂","💺",
        "🚁","🚟","🚠","🚡","🛰️","🚀","🛸","🌍","🌎","🌏","🌐","🗺️","🧭",
        "🏔️","⛰️","🌋","🗻","🏕️","🏖️","🏜️","🏝️","🏞️","🏟️","🏛️","🏗️",
        "🧱","🏘️","🏚️","🏠","🏡","🏢","🏣","🏤","🏥","🏦","🏨","🏩","🏪",
        "🏫","🏬","🏭","🏯","🏰","💒","🗼","🗽","⛪","🕌","🛕","🕍","⛩️",
        "🕋","⛲","⛺","🌁","🌃","🏙️","🌄","🌅","🌆","🌇","🌉","♾️","🎠",
        "🎡","🎢","💈","🎪","🎭","🖼️","🎨","🎰","🚂","🚃","🚄","🚅","🚆",
        // Actividades
        "⚽","🏀","🏈","⚾","🥎","🎾","🏐","🏉","🥏","🎱","🪀","🏓","🏸",
        "🏒","🏑","🥍","🏏","🪃","🥅","⛳","🪁","🤿","🎣","🎽","🎿","🛷",
        "🥌","🎯","🪀","🪁","🎱","🔮","🧿","🎮","🕹️","🎲","♟️","🧩","🧸",
        "🪆","♠️","♥️","♦️","♣️","♟️","🃏","🀄","🎴","🎭","🎨","🧵","🪡",
        "🧶","🪢","👓","🕶️","🥽","🧥","🥼","🦺","👔","👕","👖","🧣","🧤",
        "🧦","🧢","👒","🎩","🎓","⛑️","📿","👛","👜","👝","🛍️","🎒","🧳",
        // Objetos
        "💼","📁","📂","🗂️","📅","📆","🗒️","🗓️","📇","📈","📉","📊","📋",
        "📌","📍","📎","🖇️","📏","📐","✂️","🗃️","🗄️","🗑️","🔒","🔓","🔏",
        "🔐","🔑","🗝️","🔨","🪓","⛏️","⚒️","🛠️","🗡️","⚔️","🔧","🪛","🔩",
        "⚙️","🗜️","⚖️","🦯","🔗","⛓️","🪝","🧲","🪜","💊","🩺","🩻","🩹",
        "🩼","🩺","🔭","🔬","🕳️","🪤","🧷","🧹","🧺","🧻","🪣","🧴","🪥",
        "🧼","🫧","🪒","🧽","🪠","🧯","🛒","🚪","🪑","🚽","🪠","🚿","🛁",
        "🪞","🪟","🛏️","🛋️","🪴","🚒","💡","🔦","🕯️","🪔","🧱","💰","💴",
        "💵","💶","💷","💸","💳","🧾","💹","✉️","📧","📨","📩","📤","📥",
        "📦","📫","📪","📬","📭","📮","🗳️","✏️","✒️","🖋️","🖊️","📝","💼",
        "📓","📔","📒","📕","📗","📘","📙","📚","📖","🔖","🏷️","💰","🔬",
        "🔭","📡","🛰️","💻","⌨️","🖥️","🖨️","🖱️","🖲️","💽","💾","💿","📀",
        "📱","☎️","📞","📟","📠","📺","📻","🧭","⏱️","⏲️","⏰","🕰️","⌚",
        "📷","📸","📹","🎥","📽️","🎞️","📞","☎️","📺","📻","🎙️","🎚️","🎛️",
        "🧭","💡","🔦","🕯️","🔋","🔌","💰","💳","💸","🏧",
        // Símbolos útiles
        "✅","❎","🔴","🟠","🟡","🟢","🔵","🟣","⚫","⚪","🟤","🔺","🔻",
        "🔷","🔶","🔹","🔸","♾️","✨","⚡","🌟","💫","⭐","🌈","🎯","🎀",
        "🎁","🎊","🎉","🎈","🔔","🔕","📢","📣","💬","💭","🗯️","🗨️",
    ]

    // Array deduplicado preservando orden
    private var uniqueEmojis: [String] {
        var seen = Set<String>()
        return allEmojis.filter { seen.insert($0).inserted }
    }

    private var filteredEmojis: [String] {
        guard !emojiSearch.isEmpty else { return uniqueEmojis }
        return uniqueEmojis.filter { $0.localizedCaseInsensitiveContains(emojiSearch) }
    }

    private var canConfirm: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !selectedEmoji.isEmpty
    }

    var body: some View {
        NavigationStack {
            // Parte fija (no scrollea)
            VStack(spacing: 0) {

                // Preview
                previewCircle
                    .padding(.top, 20)
                    .padding(.bottom, 20)

                // Nombre
                TextField("Nombre de la categoría", text: $name)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.finaForeground)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .background(Color.finaCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.finaBorder, lineWidth: 1))
                    .focused($nameFieldFocused)
                    .submitLabel(.done)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                // Colores — scroll horizontal
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(presetColors, id: \.self) { hex in
                            let selected = selectedColor == hex
                            Button {
                                withAnimation(.spring(duration: 0.2)) { selectedColor = hex }
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(.white, lineWidth: selected ? 2.5 : 0)
                                            .padding(2)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color(hex: hex), lineWidth: selected ? 1.5 : 0)
                                    )
                                    .shadow(color: selected ? Color(hex: hex).opacity(0.5) : .clear,
                                            radius: 6)
                                    .scaleEffect(selected ? 1.15 : 1)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                }
                .padding(.bottom, 16)

                // Buscador emoji
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.finaMutedForeground)
                    TextField("Buscar emoji…", text: $emojiSearch)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.finaForeground)
                        .focused($searchFocused)
                        .autocorrectionDisabled()
                    if !emojiSearch.isEmpty {
                        Button { emojiSearch = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.finaMutedForeground)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.finaCard)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.finaBorder, lineWidth: 1))
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // Grid emoji — card que llena hasta el borde inferior
                ScrollView(showsIndicators: false) {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 8),
                        spacing: 2
                    ) {
                        ForEach(Array(filteredEmojis.enumerated()), id: \.offset) { _, emoji in
                            let selected = selectedEmoji == emoji
                            Button {
                                withAnimation(.spring(duration: 0.2)) { selectedEmoji = emoji }
                                searchFocused    = false
                                nameFieldFocused = false
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 30))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(selected
                                        ? Color(hex: selectedColor).opacity(0.18)
                                        : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selected ? Color(hex: selectedColor) : Color.clear,
                                                    lineWidth: 1.5)
                                    )
                            }
                        }
                    }
                    .padding(12)
                    .padding(.bottom, 20)
                }
                .frame(maxHeight: .infinity)
                .background(Color.finaCard)
                .clipShape(
                    UnevenRoundedRectangle(
                        cornerRadii: RectangleCornerRadii(
                            topLeading: 14, bottomLeading: 0,
                            bottomTrailing: 0, topTrailing: 14
                        )
                    )
                )
                .ignoresSafeArea(.container, edges: .bottom)
            }
            .background(Color.finaBackground)
            .navigationTitle("Nueva categoría")
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
                    Button("Guardar") { confirm() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(canConfirm ? Color.finaForeground : Color.finaMutedForeground)
                        .disabled(!canConfirm)
                }
            }
        }
    }

    // MARK: - Preview circle
    private var previewCircle: some View {
        ZStack {
            Circle()
                .fill(Color(hex: selectedColor).opacity(0.18))
                .frame(width: 96, height: 96)
            if selectedEmoji.isEmpty {
                Image(systemName: "tag")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(Color(hex: selectedColor).opacity(0.5))
            } else {
                Text(selectedEmoji)
                    .font(.system(size: 50))
            }
        }
        .animation(.spring(duration: 0.3), value: selectedEmoji)
        .animation(.spring(duration: 0.3), value: selectedColor)
    }

    // MARK: - Confirm
    private func confirm() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !selectedEmoji.isEmpty else { return }
        onConfirm(trimmed, selectedEmoji, selectedColor)
        dismiss()
    }
}
