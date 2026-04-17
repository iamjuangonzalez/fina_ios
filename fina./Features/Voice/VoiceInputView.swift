import SwiftUI

// MARK: - VoiceInputView
// Full-screen con auroras animadas en naranja — marca de fina.

struct VoiceInputView: View {
    @Environment(\.dismiss)        private var dismiss
    @Environment(AuthManager.self) private var auth

    @State private var vm           = VoiceInputManager()
    @State private var phase        = Phase.idle
    @State private var parsed:        ParsedVoiceIntent? = nil
    @State private var showForm       = false
    @State private var anim           = false   // driver de las auroras

    private enum Phase { case idle, recording, done, error }

    // MARK: Body
    var body: some View {
        ZStack {
            // ── Fondo oscuro base ──────────────────────────────────
            Color(red: 0.06, green: 0.04, blue: 0.04)
                .ignoresSafeArea()

            // ── Auroras ───────────────────────────────────────────
            auroraLayer
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // ── Contenido ─────────────────────────────────────────
            VStack(spacing: 0) {
                Spacer()

                // Texto central
                centerText
                    .padding(.horizontal, 40)

                Spacer()

                // Botones inferiores
                bottomButtons
                    .padding(.horizontal, 28)
                    .padding(.bottom, 48)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                anim = true
            }
            startIfPermitted()
        }
        .onDisappear { vm.stopRecording() }
        .sheet(isPresented: $showForm) {
            if let p = parsed {
                NewTransactionView(voiceIntent: p)
                    .environment(auth)
                    .finaColorScheme()
            }
        }
        .animation(.spring(duration: 0.4), value: phase)
        .animation(.easeInOut(duration: 0.3), value: vm.transcript)
    }

    // MARK: - Aurora layer
    private var auroraLayer: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Blob 1 — naranja principal
                auroraBlob(
                    color: Color(red: 0.980, green: 0.451, blue: 0.086),  // #F97316
                    size: w * 0.90,
                    offset: CGSize(
                        width:  anim ? -w * 0.18 : w * 0.10,
                        height: anim ? -h * 0.22 : h * 0.05
                    ),
                    opacity: 0.55,
                    duration: 4.2
                )

                // Blob 2 — rojo coral
                auroraBlob(
                    color: Color(red: 0.937, green: 0.267, blue: 0.267),  // rojo
                    size: w * 0.80,
                    offset: CGSize(
                        width:  anim ? w * 0.22 : -w * 0.08,
                        height: anim ? h * 0.18 : -h * 0.15
                    ),
                    opacity: 0.40,
                    duration: 5.5
                )

                // Blob 3 — ámbar cálido
                auroraBlob(
                    color: Color(red: 0.984, green: 0.753, blue: 0.141),  // amber
                    size: w * 0.65,
                    offset: CGSize(
                        width:  anim ? w * 0.12 : -w * 0.20,
                        height: anim ? h * 0.28 : h * 0.10
                    ),
                    opacity: 0.30,
                    duration: 6.8
                )

                // Blob 4 — naranja oscuro (profundidad)
                auroraBlob(
                    color: Color(red: 0.800, green: 0.300, blue: 0.050),
                    size: w * 0.70,
                    offset: CGSize(
                        width:  anim ? -w * 0.25 : w * 0.15,
                        height: anim ? -h * 0.10 : h * 0.25
                    ),
                    opacity: 0.35,
                    duration: 7.5
                )
            }
            .frame(width: w, height: h)
            .blur(radius: 70)
        }
    }

    private func auroraBlob(color: Color, size: CGFloat, offset: CGSize,
                             opacity: Double, duration: Double) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .offset(offset)
            .opacity(opacity)
            .animation(
                .easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: anim
            )
    }

    // MARK: - Texto central
    private var centerText: some View {
        VStack(spacing: 20) {
            if vm.transcript.isEmpty {
                Text(LocalizedStringKey(phaseText))
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            } else {
                Text(vm.transcript)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.3), radius: 8)
            }

            // Error de permiso
            if let err = vm.permissionError {
                Text(err.localizedDescription)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.10))
                    .cornerRadius(12)
            }

            // Indicador de grabación
            if phase == .recording {
                recordingDots
            }
        }
    }

    private var phaseText: String {
        switch phase {
        case .idle:      return "Cuéntame todos los\ndetalles de tu\ntransacción"
        case .recording: return "Te escucho…"
        case .done:      return vm.transcript.isEmpty ? "No escuché nada" : ""
        case .error:     return "Algo salió mal"
        }
    }

    // Puntos animados de grabación
    private var recordingDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(.white.opacity(0.7))
                    .frame(width: 7, height: 7)
                    .scaleEffect(anim ? 1.4 : 0.7)
                    .animation(
                        .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.18),
                        value: anim
                    )
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Botones inferiores
    private var bottomButtons: some View {
        HStack {
            // X — cancelar
            Button { stopAndDismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(.white.opacity(0.15))
                    .clipShape(Circle())
            }

            Spacer()

            // Botón central mic (solo en idle/recording)
            if phase != .done {
                Button { handleMicTap() } label: {
                    Image(systemName: phase == .recording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 52, height: 52)
                        .background(.white.opacity(0.10))
                        .clipShape(Circle())
                }
            }

            Spacer()

            // ✓ — confirmar (siempre visible, deshabilitado si no hay transcript)
            Button { confirmAndOpenForm() } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(
                        vm.transcript.isEmpty
                            ? Color.white.opacity(0.15)
                            : Color(red: 0.980, green: 0.451, blue: 0.086)
                    )
                    .clipShape(Circle())
                    .shadow(
                        color: Color(red: 0.980, green: 0.451, blue: 0.086).opacity(
                            vm.transcript.isEmpty ? 0 : 0.5
                        ),
                        radius: 12, y: 4
                    )
            }
            .disabled(vm.transcript.isEmpty)
            .animation(.easeInOut(duration: 0.3), value: vm.transcript.isEmpty)
        }
    }

    // MARK: - Acciones
    private func startIfPermitted() {
        Task {
            let ok = await vm.requestPermissions()
            if ok { await beginRecording() }
            else   { phase = .error }
        }
    }

    private func handleMicTap() {
        if phase == .recording {
            vm.stopRecording()
            phase = .done
        } else {
            Task { await beginRecording() }
        }
    }

    private func beginRecording() async {
        phase = .recording
        await vm.startRecording()
        // Si se detuvo solo (silencio / error), pasar a done
        if phase == .recording { phase = .done }
    }

    private func confirmAndOpenForm() {
        guard !vm.transcript.isEmpty else { return }
        parsed   = VoiceParser.parse(vm.transcript)
        showForm = true
    }

    private func stopAndDismiss() {
        vm.stopRecording()
        dismiss()
    }
}
