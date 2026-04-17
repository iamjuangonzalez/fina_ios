import AVFoundation
import Speech
import SwiftUI

// MARK: - VoiceInputManager
// Gestiona grabación de audio y transcripción en tiempo real con SFSpeechRecognizer.
// Locale: es-CO (español colombiano). Fallback: es-ES.

@MainActor
@Observable
final class VoiceInputManager {

    // MARK: Estado público
    var transcript  = ""
    var isRecording = false
    var permissionError: PermissionError? = nil

    enum PermissionError: LocalizedError {
        case microphone, speech
        var errorDescription: String? {
            switch self {
            case .microphone:
                #if targetEnvironment(simulator)
                return "El simulador no tiene micrófono. Prueba en un iPhone real."
                #else
                return "Permite el acceso al micrófono en Ajustes"
                #endif
            case .speech:
                return "Permite el reconocimiento de voz en Ajustes"
            }
        }
    }

    // MARK: Privado
    private var audioEngine        = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask:    SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-CO"))
                          ?? SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))

    // MARK: - Permisos
    func requestPermissions() async -> Bool {
        // Micrófono
        let micOk = await AVAudioApplication.requestRecordPermission()
        guard micOk else { permissionError = .microphone; return false }

        // Reconocimiento de voz
        let speechOk = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
        guard speechOk else { permissionError = .speech; return false }
        return true
    }

    // MARK: - Grabación
    func startRecording() async {
        guard let recognizer, recognizer.isAvailable else {
            permissionError = .speech
            return
        }

        transcript  = ""
        isRecording = true

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let req = recognitionRequest else { isRecording = false; return }
            req.shouldReportPartialResults = true
            req.taskHint                   = .dictation

            let inputNode = audioEngine.inputNode
            let format    = inputNode.outputFormat(forBus: 0)

            // El simulador puede devolver un formato con 0 canales — lo detectamos
            guard format.channelCount > 0 else {
                isRecording = false
                permissionError = .microphone
                return
            }

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

            recognitionTask = recognizer.recognitionTask(with: req) { [weak self] result, error in
                guard let self else { return }
                if let result {
                    Task { @MainActor in
                        self.transcript = result.bestTranscription.formattedString
                    }
                }
                if error != nil || result?.isFinal == true {
                    Task { @MainActor in self.stopRecording() }
                }
            }
        } catch {
            isRecording    = false
            permissionError = .microphone
        }
    }

    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.finish()
        recognitionRequest = nil
        recognitionTask    = nil
        isRecording        = false
        try? AVAudioSession.sharedInstance().setActive(false,
             options: .notifyOthersOnDeactivation)
    }
}
