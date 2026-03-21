import 'dart:typed_data';

/// Each emitted String is a finalized transcript segment.
/// Partial/interim results are NOT emitted.
/// The stream closes when the session ends.
abstract class SpeechService {
  /// Initialize the service and request permissions.
  /// Throws [SpeechServiceException] if unavailable.
  Future<void> initialize();

  /// Begin transcription. Returns a stream of finalized segments.
  /// Note: iOS/Android platform implementations use the device microphone
  /// via SFSpeechRecognizer / SpeechRecognizer. The [audioStream] parameter
  /// is accepted for API compatibility but is currently ignored by platform
  /// implementations — audio routing via BLE is deferred to the Whisper path.
  Stream<String> transcribe(Stream<Uint8List> audioStream);

  /// Stop transcription and close the stream.
  Future<void> stop();

  /// Release resources.
  Future<void> dispose();
}

class SpeechServiceException implements Exception {
  final String message;
  const SpeechServiceException(this.message);

  @override
  String toString() => 'SpeechServiceException: $message';
}
