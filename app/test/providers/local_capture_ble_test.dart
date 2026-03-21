import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:omi/services/speech/speech_service.dart';
import 'package:omi/providers/local_capture_provider.dart';

// Reuse mocks from the other test file
import 'local_capture_provider_test.mocks.dart';

void main() {
  late MockSpeechService mockSpeech;

  setUp(() {
    mockSpeech = MockSpeechService();
  });

  test('pauseRecording sets isPaused and calls speechService.stop', () async {
    final controller = StreamController<String>();
    when(mockSpeech.initialize()).thenAnswer((_) async {});
    when(mockSpeech.transcribe(any)).thenAnswer((_) => controller.stream);
    when(mockSpeech.stop()).thenAnswer((_) async {});

    final provider = LocalCaptureProvider(speechService: mockSpeech);
    await provider.startRecording(audioStream: const Stream<Uint8List>.empty());
    expect(provider.isRecording, true);
    expect(provider.isPaused, false);

    await provider.pauseRecording();
    expect(provider.isPaused, true);
    verify(mockSpeech.stop()).called(1);
    await controller.close();
  });

  test('resumeRecording re-initializes and clears isPaused', () async {
    // Each transcribe call needs a fresh stream
    var callCount = 0;
    final controllers = [StreamController<String>(), StreamController<String>()];
    when(mockSpeech.initialize()).thenAnswer((_) async {});
    when(mockSpeech.transcribe(any)).thenAnswer((_) => controllers[callCount++].stream);
    when(mockSpeech.stop()).thenAnswer((_) async {});

    final provider = LocalCaptureProvider(speechService: mockSpeech);
    await provider.startRecording(audioStream: const Stream<Uint8List>.empty());
    await provider.pauseRecording();
    expect(provider.isPaused, true);

    await provider.resumeRecording(audioStream: const Stream<Uint8List>.empty());
    expect(provider.isPaused, false);
    expect(provider.isRecording, true);
    // initialize called twice: once on start, once on resume
    verify(mockSpeech.initialize()).called(2);
    for (final c in controllers) {
      await c.close();
    }
  });
}
