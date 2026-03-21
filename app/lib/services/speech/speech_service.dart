import 'dart:typed_data';

/// Each emitted String is a finalized transcript segment.
/// Partial/interim results are NOT emitted.
/// The stream closes when the session ends.
abstract class SpeechService {
  /// Initialize the service and request permissions.
  /// Throws [SpeechServiceException] if unavailable.
  Future<void> initialize();

  /// Begin transcription. Returns a stream of finalized segments only
  /// (no partial/interim results are emitted).
  ///
  /// [audioStream]: BLE PCM audio bytes. Used by [BleAudioSpeechServiceIos]
  /// to feed audio to SFSpeechAudioBufferRecognitionRequest. Platform
  /// microphone implementations (iOS/Android) currently ignore this parameter
  /// and listen to the device mic directly.
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
