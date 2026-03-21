import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:omi/backend/preferences.dart';
import 'package:omi/services/speech/ble_audio_speech_service_ios.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('offlineModeEnabled', () {
    test('defaults to false', () async {
      await SharedPreferencesUtil.init();
      expect(SharedPreferencesUtil().offlineModeEnabled, false);
    });

    test('persists true after setOfflineModeEnabled(true)', () async {
      await SharedPreferencesUtil.init();
      await SharedPreferencesUtil().setOfflineModeEnabled(true);
      expect(SharedPreferencesUtil().offlineModeEnabled, true);
    });

    test('persists false after setOfflineModeEnabled(false)', () async {
      await SharedPreferencesUtil.init();
      await SharedPreferencesUtil().setOfflineModeEnabled(true);
      await SharedPreferencesUtil().setOfflineModeEnabled(false);
      expect(SharedPreferencesUtil().offlineModeEnabled, false);
    });
  });

  group('BleAudioSpeechServiceIos', () {
    late BleAudioSpeechServiceIos svc;

    setUp(() {
      svc = BleAudioSpeechServiceIos();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.omi/ble_stt'),
        (call) async => null,
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.omi/ble_stt'),
        null,
      );
    });

    test('initialize does not throw with stubbed channel', () async {
      await expectLater(svc.initialize(), completes);
    });

    test('stop does not throw before transcribe is called', () async {
      await svc.initialize();
      await expectLater(svc.stop(), completes);
    });
  });
}
