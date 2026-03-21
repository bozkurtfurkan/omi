import 'dart:async';
import 'dart:typed_data';
import 'package:speech_to_text/speech_to_text.dart';
import 'speech_service.dart';

/// Android implementation using createOnDeviceRecognitionIntent (API 31+).
/// Requires the Turkish language pack to be installed on the device.
/// Throws [SpeechServiceException] if on-device recognition is unavailable.
///
/// Strategy A (same as iOS): The OS recognizer listens to the device
/// microphone. The [audioStream] BLE parameter is accepted but ignored.
class PlatformSpeechServiceAndroid implements SpeechService {
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
        'On-device Turkish STT unavailable — language pack may not be installed',
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
  Future<void> stop() async => _stt.stop();

  @override
  Future<void> dispose() async {
    await _stt.cancel();
    await _controller.close();
  }
}
