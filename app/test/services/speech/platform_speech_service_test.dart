import 'package:flutter_test/flutter_test.dart';
import 'package:omi/services/speech/speech_service.dart';
import 'package:omi/services/speech/platform_speech_service_ios.dart';
import 'package:omi/services/speech/vosk_speech_service.dart';

void main() {
  test('PlatformSpeechServiceIos implements SpeechService', () {
    final service = PlatformSpeechServiceIos();
    expect(service, isA<SpeechService>());
  });

  test('transcribe method is callable (type contract)', () {
    final service = PlatformSpeechServiceIos();
    expect(service.transcribe, isNotNull);
  });

  test('VoskSpeechService implements SpeechService', () {
    final service = VoskSpeechService();
    expect(service, isA<SpeechService>());
  });

  test('VoskSpeechService.initialize throws SpeechServiceException', () async {
    final service = VoskSpeechService();
    expect(() => service.initialize(), throwsA(isA<SpeechServiceException>()));
  });
}
