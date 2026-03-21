import 'dart:async';
import 'dart:typed_data';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:omi/database/app_database.dart';
import 'package:omi/services/speech/speech_service.dart';

/// Lightweight, fully local capture provider.
/// Uses [SpeechService] for on-device STT and [AppDatabase] for local storage.
/// Does NOT depend on any backend, WebSocket, or cloud service.
class LocalCaptureProvider extends ChangeNotifier {
  final SpeechService _speechService;
  final AppDatabase? _database;

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
    AppDatabase? database,
    this.silenceTimeout = const Duration(seconds: 60),
  })  : _speechService = speechService,
        _database = database;

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
    final endTime = DateTime.now();
    _silenceTimer?.cancel();
    await _speechService.stop();
    await _transcriptSub?.cancel();
    _transcriptSub = null;
    isRecording = false;
    isPaused = false;

    if (_database != null && _recordingStartTime != null) {
      await _database!.into(_database!.conversations).insert(
            ConversationsCompanion.insert(
              id: const Uuid().v4(),
              startedAt: _recordingStartTime!,
              endedAt: endTime,
              durationSeconds: endTime.difference(_recordingStartTime!).inSeconds,
              transcript: currentTranscript,
              locale: const Value('tr_TR'),
            ),
          );
    }

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
