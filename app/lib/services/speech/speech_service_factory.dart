import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:omi/backend/preferences.dart';
import 'speech_service.dart';
import 'platform_speech_service_ios.dart';
import 'platform_speech_service_android.dart';
import 'vosk_speech_service.dart';
import 'ble_audio_speech_service_ios.dart';

class SpeechServiceFactory {
  /// Creates the appropriate SpeechService for the current platform.
  ///
  /// iOS   → PlatformSpeechServiceIos (SFSpeechRecognizer, tr_TR)
  /// Android API 31+ → PlatformSpeechServiceAndroid (native on-device STT)
  ///   └─ falls back to VoskSpeechService (stub) if native init throws
  /// Android API < 31 → VoskSpeechService (stub — deferred)
  static Future<SpeechService> create() async {
    if (Platform.isIOS) {
      if (SharedPreferencesUtil().offlineModeEnabled) {
        return BleAudioSpeechServiceIos();
      }
      return PlatformSpeechServiceIos();
    }

    // Android — check API level
    final info = await DeviceInfoPlugin().androidInfo;
    final sdkInt = info.version.sdkInt;

    if (sdkInt >= 31) {
      // Try native on-device first; fall back to VOSK stub if unavailable
      final native = PlatformSpeechServiceAndroid();
      try {
        await native.initialize();
        return native;
      } on SpeechServiceException {
        // Language pack not installed — fall back to VOSK stub
        return VoskSpeechService();
      }
    }

    // API < 31: native on-device STT not available
    return VoskSpeechService();
  }
}
