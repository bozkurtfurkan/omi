import 'package:flutter_test/flutter_test.dart';
import 'package:omi/services/speech/speech_service.dart';
import 'package:omi/services/speech/platform_speech_service_ios.dart';

void main() {
  test('PlatformSpeechServiceIos implements SpeechService', () {
    final service = PlatformSpeechServiceIos();
    expect(service, isA<SpeechService>());
  });

  test('transcribe method is callable (type contract)', () {
    final service = PlatformSpeechServiceIos();
    expect(service.transcribe, isNotNull);
  });
}
