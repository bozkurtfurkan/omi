import 'dart:async';
import 'dart:typed_data';
import 'speech_service.dart';

/// Stub implementation — vosk_flutter is incompatible with http ^1.x.
/// Replace this with a real VOSK implementation once a compatible
/// version of vosk_flutter is available, or integrate vosk via FFI directly.
///
/// This stub is used as the Android fallback when the native on-device STT
/// (API 31+ Turkish language pack) is unavailable.
class VoskSpeechService implements SpeechService {
  @override
  Future<void> initialize() async {
    throw const SpeechServiceException(
      'VoskSpeechService is not yet implemented. '
      'Install the Turkish language pack in Android Settings to use on-device STT.',
    );
  }

  @override
  Stream<String> transcribe(Stream<Uint8List> audioStream) {
    return const Stream<String>.empty();
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
