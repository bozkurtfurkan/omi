import 'dart:async';
import 'dart:typed_data';
import 'package:speech_to_text/speech_to_text.dart';
import 'speech_service.dart';

/// iOS implementation using SFSpeechRecognizer via the speech_to_text package.
///
/// Strategy A: The OS recognizer listens to the device microphone directly.
/// The [audioStream] BLE parameter is accepted but not used — audio must be
/// routed through the speaker for SFSpeechRecognizer to pick it up.
/// This is a known limitation; direct PCM injection is deferred to the
/// WhisperSpeechService path.
///
/// Privacy note: If the offline Turkish model is not cached on the device,
/// SFSpeechRecognizer falls back to online recognition. The app's privacy
/// policy must disclose this behaviour.
class PlatformSpeechServiceIos implements SpeechService {
  final SpeechToText _stt = SpeechToText();
  final StreamController<String> _controller = StreamController<String>.broadcast();
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    _initialized = await _stt.initialize(
      onError: (error) => _controller.addError(
        SpeechServiceException(error.errorMsg),
      ),
    );
    if (!_initialized) {
      throw const SpeechServiceException(
        'Speech recognition unavailable or permission denied',
      );
    }
  }

  @override
  Stream<String> transcribe(Stream<Uint8List> audioStream) {
    // audioStream is ignored — see class-level doc comment.
    _stt.listen(
      onResult: (result) {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          _controller.add(result.recognizedWords);
        }
      },
      localeId: 'tr_TR',
      listenMode: ListenMode.dictation,
      cancelOnError: false,
    );
    return _controller.stream;
  }

  @override
  Future<void> stop() async {
    await _stt.stop();
  }

  @override
  Future<void> dispose() async {
    await _stt.cancel();
    await _controller.close();
  }
}
