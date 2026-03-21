import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'speech_service.dart';

/// iOS implementation that feeds BLE PCM audio directly to
/// SFSpeechAudioBufferRecognitionRequest via a native plugin.
///
/// Unlike [PlatformSpeechServiceIos], this class actively uses the
/// [audioStream] parameter — each chunk is forwarded to the Swift plugin
/// via MethodChannel("com.omi/ble_stt"). Only finalized segments
/// (isFinal == true on the Swift side) are emitted from [transcribe].
class BleAudioSpeechServiceIos implements SpeechService {
  static const _method = MethodChannel('com.omi/ble_stt');
  static const _events = EventChannel('com.omi/ble_stt/results');

  StreamSubscription<Uint8List>? _audioSub;
  StreamController<String>? _transcriptController;

  @override
  Future<void> initialize() async {
    await _method.invokeMethod<void>('initialize');
  }

  @override
  Stream<String> transcribe(Stream<Uint8List> audioStream) {
    _transcriptController = StreamController<String>.broadcast();

    // Forward finalized transcripts from Swift
    _events.receiveBroadcastStream().listen(
      (event) {
        if (event is String && event.isNotEmpty) {
          _transcriptController?.add(event);
        }
      },
      onError: (e) {
        _transcriptController?.addError(
          SpeechServiceException(e.toString()),
        );
      },
    );

    // Stream BLE chunks to Swift
    _audioSub = audioStream.listen((bytes) {
      _method.invokeMethod<void>('sendBuffer', bytes);
    });

    return _transcriptController!.stream;
  }

  @override
  Future<void> stop() async {
    await _audioSub?.cancel();
    _audioSub = null;
    try {
      await _method.invokeMethod<void>('stop');
    } catch (_) {}
    await _transcriptController?.close();
    _transcriptController = null;
  }

  @override
  Future<void> dispose() async {
    await stop();
  }
}
