import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:omi/services/speech/speech_service.dart';

/// Lightweight, fully local capture provider.
/// Uses [SpeechService] for on-device STT and stores results locally.
/// Does NOT depend on any backend, WebSocket, or cloud service.
class LocalCaptureProvider extends ChangeNotifier {
  final SpeechService _speechService;

  String currentTranscript = '';
  bool isRecording = false;
  bool isPaused = false;

  DateTime? _recordingStartTime;
  StreamSubscription<String>? _transcriptSub;

  LocalCaptureProvider({required SpeechService speechService}) : _speechService = speechService;

  Future<void> startRecording({required Stream<Uint8List> audioStream}) async {
    if (isRecording) return;
    await _speechService.initialize();
    currentTranscript = '';
    _recordingStartTime = DateTime.now();
    isRecording = true;
    isPaused = false;
    notifyListeners();

    _transcriptSub = _speechService.transcribe(audioStream).listen(
      (segment) {
        currentTranscript = currentTranscript.isEmpty ? segment : '$currentTranscript $segment';
        notifyListeners();
      },
      onError: (e) {
        notifyListeners();
      },
    );
  }

  Future<void> stopRecording() async {
    if (!isRecording) return;
    await _speechService.stop();
    await _transcriptSub?.cancel();
    _transcriptSub = null;
    isRecording = false;
    isPaused = false;
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    await stopRecording();
    await _speechService.dispose();
    super.dispose();
  }
}
