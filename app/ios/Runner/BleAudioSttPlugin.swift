import Flutter
import Speech
import AVFoundation

/// Native plugin that feeds BLE PCM audio to SFSpeechAudioBufferRecognitionRequest.
///
/// MethodChannel "com.omi/ble_stt":
///   - initialize()         → requests SFSpeechRecognizer authorization and starts a recognition task
///   - sendBuffer(bytes)    → converts PCM16 bytes to AVAudioPCMBuffer (Float32) and appends
///   - stop()               → calls endAudio() to flush final segment, then cancels task
///
/// EventChannel "com.omi/ble_stt/results":
///   - emits finalized transcript strings (isFinal == true only)
///   - emits FlutterError on authorization failure or recognition error
///
/// Audio format: 16 kHz, mono, Float32 (non-interleaved)
/// Locale: tr_TR (Turkish, this iteration only)
public class BleAudioSttPlugin: NSObject, FlutterPlugin {
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "tr_TR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private let audioFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 16000,
        channels: 1,
        interleaved: false
    )!

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = BleAudioSttPlugin()
        instance.methodChannel = FlutterMethodChannel(
            name: "com.omi/ble_stt",
            binaryMessenger: registrar.messenger()
        )
        instance.eventChannel = FlutterEventChannel(
            name: "com.omi/ble_stt/results",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: instance.methodChannel!)
        instance.eventChannel?.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            requestAuthorizationAndStart(result: result)
        case "sendBuffer":
            guard let data = call.arguments as? FlutterStandardTypedData else {
                result(FlutterError(code: "INVALID_ARGS", message: "Expected FlutterStandardTypedData", details: nil))
                return
            }
            appendBuffer(pcm16Bytes: data.data)
            result(nil)
        case "stop":
            stopRecognition()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func requestAuthorizationAndStart(result: @escaping FlutterResult) {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch status {
                case .authorized:
                    self.startRecognitionTask()
                    result(nil)
                default:
                    let error = FlutterError(
                        code: "PERMISSION_DENIED",
                        message: "Speech recognition permission not granted",
                        details: nil
                    )
                    self.eventSink?(error)
                    result(error)
                }
            }
        }
    }

    private func startRecognitionTask() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true

        recognitionTask = recognizer?.recognitionTask(with: recognitionRequest!) { [weak self] res, error in
            guard let self = self else { return }
            if let error = error {
                self.eventSink?(FlutterError(
                    code: "STT_ERROR",
                    message: error.localizedDescription,
                    details: nil
                ))
                return
            }
            if let res = res, res.isFinal, !res.bestTranscription.formattedString.isEmpty {
                self.eventSink?(res.bestTranscription.formattedString)
            }
        }
    }

    private func appendBuffer(pcm16Bytes: Data) {
        guard let request = recognitionRequest else { return }
        let frameCount = pcm16Bytes.count / 2  // 2 bytes per Int16 sample
        guard frameCount > 0 else { return }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(frameCount)) else { return }
        buffer.frameLength = AVAudioFrameCount(frameCount)

        // Convert PCM16 (Int16) → Float32
        pcm16Bytes.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            let int16Ptr = raw.bindMemory(to: Int16.self)
            let floatPtr = buffer.floatChannelData![0]
            for i in 0..<frameCount {
                floatPtr[i] = Float(int16Ptr[i]) / 32768.0
            }
        }
        request.append(buffer)
    }

    private func stopRecognition() {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }
}

// MARK: - FlutterStreamHandler
extension BleAudioSttPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}
