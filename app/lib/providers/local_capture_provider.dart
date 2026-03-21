import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:omi/services/speech/speech_service.dart';

/// Lightweight, fully local capture provider.
/// Uses [SpeechService] for on-device STT and stores results locally.
/// Does NOT depend on any backend, WebSocket, or cloud service.
class LocalCaptureProvider extends ChangeNotifier {
  final SpeechService _speechService;

  /// Silence duration before auto-stopping a recording (configurable).
  final Duration silenceTimeout;

  String currentTranscript = '';
  bool isRecording = false;
  bool isPaused = false;

  DateTime? _recordingStartTime;
  StreamSubscription<String>? _transcriptSub;
  Timer? _silenceTimer;

  LocalCaptureProvider({
    required SpeechService speechService,
    this.silenceTimeout = const Duration(seconds: 60),
  }) : _speechService = speechService;

  Future<void> startRecording({required Stream<Uint8List> audioStream}) async {
    if (isRecording) return;
    await _speechService.initialize();
    currentTranscript = '';
    _recordingStartTime = DateTime.now();
    isRecording = true;
    isPaused = false;
    notifyListeners();

    _listenTranscript(audioStream);
    _startSilenceTimer();
  }

  /// Called when BLE disconnects mid-recording.
  Future<void> pauseRecording() async {
    if (!isRecording || isPaused) return;
    isPaused = true;
    _silenceTimer?.cancel();
    await _speechService.stop();
    await _transcriptSub?.cancel();
    _transcriptSub = null;
    notifyListeners();
  }

  /// Called when BLE reconnects after a pause.
  Future<void> resumeRecording({required Stream<Uint8List> audioStream}) async {
    if (!isRecording || !isPaused) return;
    await _speechService.initialize();
    isPaused = false;
    notifyListeners();

    _listenTranscript(audioStream);
    _startSilenceTimer();
  }

  Future<void> stopRecording() async {
    if (!isRecording) return;
    _silenceTimer?.cancel();
    await _speechService.stop();
    await _transcriptSub?.cancel();
    _transcriptSub = null;
    isRecording = false;
    isPaused = false;
    notifyListeners();
  }

  void _listenTranscript(Stream<Uint8List> audioStream) {
    _transcriptSub = _speechService.transcribe(audioStream).listen(
      (segment) {
        currentTranscript = currentTranscript.isEmpty ? segment : '$currentTranscript $segment';
        notifyListeners();
      },
      onError: (_) => notifyListeners(),
    );
  }

  void _startSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(silenceTimeout, () async {
      if (isRecording && !isPaused) {
        await stopRecording();
      }
    });
  }

  @override
  Future<void> dispose() async {
    _silenceTimer?.cancel();
    await stopRecording();
    await _speechService.dispose();
    super.dispose();
  }
}
