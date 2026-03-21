import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:omi/services/speech/speech_service.dart';
import 'package:omi/providers/local_capture_provider.dart';

@GenerateMocks([SpeechService])
import 'local_capture_provider_test.mocks.dart';

void main() {
  late MockSpeechService mockSpeech;

  setUp(() {
    mockSpeech = MockSpeechService();
  });

  test('transcript segments are appended to currentTranscript', () async {
    final controller = StreamController<String>();
    when(mockSpeech.initialize()).thenAnswer((_) async {});
    when(mockSpeech.transcribe(any)).thenAnswer((_) => controller.stream);

    final provider = LocalCaptureProvider(speechService: mockSpeech);
    await provider.startRecording(audioStream: const Stream<Uint8List>.empty());

    controller.add('Merhaba');
    await Future.delayed(Duration.zero);
    controller.add('dünya');
    await Future.delayed(Duration.zero);

    expect(provider.currentTranscript, 'Merhaba dünya');
    await controller.close();
  });

  test('isRecording is true after startRecording', () async {
    final controller = StreamController<String>();
    when(mockSpeech.initialize()).thenAnswer((_) async {});
    when(mockSpeech.transcribe(any)).thenAnswer((_) => controller.stream);

    final provider = LocalCaptureProvider(speechService: mockSpeech);
    await provider.startRecording(audioStream: const Stream<Uint8List>.empty());

    expect(provider.isRecording, true);
    await controller.close();
  });

  test('stopRecording calls speechService.stop', () async {
    final controller = StreamController<String>();
    when(mockSpeech.initialize()).thenAnswer((_) async {});
    when(mockSpeech.transcribe(any)).thenAnswer((_) => controller.stream);
    when(mockSpeech.stop()).thenAnswer((_) async {});

    final provider = LocalCaptureProvider(speechService: mockSpeech);
    await provider.startRecording(audioStream: const Stream<Uint8List>.empty());
    await provider.stopRecording();

    verify(mockSpeech.stop()).called(1);
    expect(provider.isRecording, false);
    await controller.close();
  });
}
