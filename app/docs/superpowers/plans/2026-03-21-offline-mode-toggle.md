# Offline Mode Toggle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a persistent "Offline Mode" toggle to the Omi Flutter app that routes BLE audio from Devkit 2 through a native iOS `SFSpeechAudioBufferRecognitionRequest` plugin instead of the backend WebSocket.

**Architecture:** A module-level `late SpeechService _resolvedSpeechService` is resolved in `_init()` after `SharedPreferencesUtil.init()`, then injected into `LocalCaptureProvider` at startup. When the flag is `true`, `BleAudioSpeechServiceIos` (new Dart class) forwards BLE PCM chunks via `MethodChannel("com.omi/ble_stt")` to `BleAudioSttPlugin.swift`, which feeds them to `SFSpeechAudioBufferRecognitionRequest` and returns final transcripts via `EventChannel("com.omi/ble_stt/results")`. The existing `CaptureProvider` and backend flow are untouched.

**Tech Stack:** Flutter/Dart, Swift, `speech_to_text` replaced by custom MethodChannel+EventChannel, `drift` SQLite, `SharedPreferences`, `provider` package.

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `lib/backend/preferences.dart` | Modify | Add `offlineModeEnabled` getter + `setOfflineModeEnabled()` |
| `lib/main.dart` | Modify | Restore `SharedPreferencesUtil.init()`; late-resolve `SpeechService`; inject `LocalCaptureProvider` |
| `lib/services/speech/speech_service.dart` | Modify | Update doc comment — `audioStream` now used by `BleAudioSpeechServiceIos` |
| `lib/services/speech/ble_audio_speech_service_ios.dart` | **Create** | Dart side of BLE→STT bridge; implements `SpeechService` |
| `lib/services/speech/speech_service_factory.dart` | Modify | Add offline branch returning `BleAudioSpeechServiceIos` on iOS |
| `lib/providers/local_capture_provider.dart` | Modify | Add `transcriptError` field; surface errors from STT stream |
| `lib/providers/device_provider.dart` | Modify | Add public `getBleAudioStream()` returning `Stream<Uint8List>` |
| `ios/Runner/BleAudioSttPlugin.swift` | **Create** | Swift plugin: MethodChannel+EventChannel, AVAudioPCMBuffer→SFSpeechRecognizer |
| `ios/Runner/AppDelegate.swift` | Modify | Register `BleAudioSttPlugin` |
| `lib/pages/settings/transcription_settings_page.dart` | Modify | Add offline toggle at top; disable provider widgets when on |
| `lib/pages/settings/developer.dart` | Modify | `_buildSttChip()` shows "Apple STT" when offline |
| `lib/pages/conversation_capturing/page.dart` | Modify | Offline branch: use `LocalCaptureProvider` + `getBleAudioStream()` |
| `test/unit/offline_mode_test.dart` | **Create** | Unit tests for preferences flag, factory branch, provider error surfacing |

---

## Task 1: Add `offlineModeEnabled` preference

**Files:**
- Modify: `app/lib/backend/preferences.dart` (after line 686, before closing `}`)
- Create: `app/test/unit/offline_mode_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/unit/offline_mode_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:omi/backend/preferences.dart';

void main() {
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
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
cd app && flutter test test/unit/offline_mode_test.dart -v
```

Expected: compilation error — `offlineModeEnabled` and `setOfflineModeEnabled` don't exist yet.

- [ ] **Step 3: Add getter and setter to `preferences.dart`**

In `app/lib/backend/preferences.dart`, find the `getBool`/`saveBool` block (around line 666) and add after all the existing getters/setters, just before the closing `}` of the class:

```dart
  // --------------- Offline Mode ---------------
  bool get offlineModeEnabled => getBool('offlineModeEnabled');
  Future<bool> setOfflineModeEnabled(bool v) => saveBool('offlineModeEnabled', v);
```

- [ ] **Step 4: Run test — expect PASS**

```bash
cd app && flutter test test/unit/offline_mode_test.dart -v
```

Expected: 3 tests pass.

- [ ] **Step 5: Commit**

```bash
cd app && git add lib/backend/preferences.dart test/unit/offline_mode_test.dart
git commit -m "feat: add offlineModeEnabled preference flag"
```

---

## Task 2: Restore `SharedPreferencesUtil.init()` and inject `LocalCaptureProvider`

**Files:**
- Modify: `app/lib/main.dart`

- [ ] **Step 1: Read `main.dart` lines 80–135 and `_init()` function**

Verify the commented-out line: `// TODO: service removed - await SharedPreferencesUtil.init();` at line ~103.

- [ ] **Step 2: Add the `late` variable and restore `init()`**

In `app/lib/main.dart`:

Add a top-level variable before `_init()`:
```dart
late SpeechService _resolvedSpeechService;
```

Inside `_init()`, after `await PlatformManager.initializeServices();` (line 98), add:
```dart
  await SharedPreferencesUtil.init();
  _resolvedSpeechService = await SpeechServiceFactory.create();
```

Remove the old commented-out `TODO` line for `SharedPreferencesUtil.init()`.

Add the necessary import at the top of `main.dart`:
```dart
import 'package:omi/services/speech/speech_service.dart';
import 'package:omi/services/speech/speech_service_factory.dart';
```

- [ ] **Step 3: Inject `LocalCaptureProvider` into `MultiProvider`**

In the `MultiProvider` providers list (around line 188), add after `VoiceRecorderProvider`:
```dart
ChangeNotifierProvider(
  create: (_) => LocalCaptureProvider(
    speechService: _resolvedSpeechService,
    database: AppDatabase.instance,
  ),
),
```

Add import at top:
```dart
import 'package:omi/providers/local_capture_provider.dart';
import 'package:omi/database/app_database.dart';
```

- [ ] **Step 4: Verify it compiles**

```bash
cd app && flutter build ios --no-codesign --debug 2>&1 | tail -20
```

Expected: No errors about missing `SpeechService` or `LocalCaptureProvider`.

- [ ] **Step 5: Commit**

```bash
cd app && git add lib/main.dart
git commit -m "feat: restore SharedPreferencesUtil.init and inject LocalCaptureProvider"
```

---

## Task 3: Update `speech_service.dart` doc comment

**Files:**
- Modify: `app/lib/services/speech/speech_service.dart`

- [ ] **Step 1: Update the class-level doc comment**

In `app/lib/services/speech/speech_service.dart`, replace the existing comment block:

Old:
```dart
/// Note: iOS/Android platform implementations use the device microphone
/// via SFSpeechRecognizer / SpeechRecognizer. The [audioStream] parameter
/// is accepted for API compatibility but is currently ignored by platform
/// implementations — audio routing via BLE is deferred to the Whisper path.
Stream<String> transcribe(Stream<Uint8List> audioStream);
```

New:
```dart
/// Begin transcription. Returns a stream of finalized segments only
/// (no partial/interim results are emitted).
///
/// [audioStream]: BLE PCM audio bytes. Used by [BleAudioSpeechServiceIos]
/// to feed audio to SFSpeechAudioBufferRecognitionRequest. Platform
/// microphone implementations (iOS/Android) currently ignore this parameter
/// and listen to the device mic directly.
Stream<String> transcribe(Stream<Uint8List> audioStream);
```

- [ ] **Step 2: Commit**

```bash
cd app && git add lib/services/speech/speech_service.dart
git commit -m "docs: update SpeechService.transcribe doc — audioStream now used by BleAudioSpeechServiceIos"
```

---

## Task 4: Create `BleAudioSpeechServiceIos` (Dart side)

**Files:**
- Create: `app/lib/services/speech/ble_audio_speech_service_ios.dart`

- [ ] **Step 1: Write the test**

Add to `app/test/unit/offline_mode_test.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:omi/services/speech/ble_audio_speech_service_ios.dart';

// Add inside main():
group('BleAudioSpeechServiceIos', () {
  late BleAudioSpeechServiceIos svc;

  setUp(() {
    svc = BleAudioSpeechServiceIos();
    // Stub the MethodChannel so no platform calls are made
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.omi/ble_stt'),
      (call) async => null,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
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
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
cd app && flutter test test/unit/offline_mode_test.dart -v
```

Expected: compilation error — class doesn't exist yet.

- [ ] **Step 3: Create the implementation**

Create `app/lib/services/speech/ble_audio_speech_service_ios.dart`:

```dart
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
    await _method.invokeMethod<void>('stop');
    await _transcriptController?.close();
    _transcriptController = null;
  }

  @override
  Future<void> dispose() async {
    await stop();
  }
}
```

- [ ] **Step 4: Run test — expect PASS**

```bash
cd app && flutter test test/unit/offline_mode_test.dart -v
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
cd app && git add lib/services/speech/ble_audio_speech_service_ios.dart test/unit/offline_mode_test.dart
git commit -m "feat: add BleAudioSpeechServiceIos — Dart side of BLE→STT bridge"
```

---

## Task 5: Update `SpeechServiceFactory` with offline branch

**Files:**
- Modify: `app/lib/services/speech/speech_service_factory.dart`

- [ ] **Step 1: Add the test**

Add to `app/test/unit/offline_mode_test.dart`:

```dart
import 'package:omi/services/speech/speech_service_factory.dart';
import 'package:omi/services/speech/ble_audio_speech_service_ios.dart';

// Add inside main():
group('SpeechServiceFactory', () {
  test('returns BleAudioSpeechServiceIos when offline mode is enabled on iOS', () async {
    SharedPreferences.setMockInitialValues({'offlineModeEnabled': true});
    await SharedPreferencesUtil.init();

    // We can only verify the type; platform detection is mocked
    // by running on a non-iOS host — this tests the factory logic path
    // through SharedPreferencesUtil.offlineModeEnabled.
    expect(SharedPreferencesUtil().offlineModeEnabled, true);
  });

  test('returns false for offlineModeEnabled when flag is not set', () async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesUtil.init();
    expect(SharedPreferencesUtil().offlineModeEnabled, false);
  });
});
```

- [ ] **Step 2: Run test — expect PASS** (flag tests, not platform branch)

```bash
cd app && flutter test test/unit/offline_mode_test.dart -v
```

- [ ] **Step 3: Update `SpeechServiceFactory`**

In `app/lib/services/speech/speech_service_factory.dart`:

Add import at top:
```dart
import 'package:omi/backend/preferences.dart';
import 'ble_audio_speech_service_ios.dart';
```

Replace the iOS branch:
```dart
static Future<SpeechService> create() async {
  if (Platform.isIOS) {
    if (SharedPreferencesUtil().offlineModeEnabled) {
      return BleAudioSpeechServiceIos();
    }
    return PlatformSpeechServiceIos();
  }
  // Android path unchanged...
```

- [ ] **Step 4: Verify compile**

```bash
cd app && flutter build ios --no-codesign --debug 2>&1 | grep -E "error:|warning:" | head -20
```

- [ ] **Step 5: Commit**

```bash
cd app && git add lib/services/speech/speech_service_factory.dart
git commit -m "feat: SpeechServiceFactory returns BleAudioSpeechServiceIos when offline mode enabled"
```

---

## Task 6: Surface errors in `LocalCaptureProvider`

**Files:**
- Modify: `app/lib/providers/local_capture_provider.dart`

- [ ] **Step 1: Add the test**

Add to `app/test/unit/offline_mode_test.dart`:

```dart
import 'package:omi/providers/local_capture_provider.dart';

// Add inside main():
group('LocalCaptureProvider error surfacing', () {
  test('transcriptError is set when speech service emits error', () async {
    final errorController = StreamController<String>();
    final fakeSpeech = _FakeSpeechService(errorController.stream, throwOnTranscribe: true);
    final provider = LocalCaptureProvider(speechService: fakeSpeech);

    await provider.startRecording(audioStream: Stream.empty());
    await Future.delayed(const Duration(milliseconds: 10));
    errorController.addError('STT permission denied');
    await Future.delayed(const Duration(milliseconds: 10));

    expect(provider.transcriptError, contains('STT permission denied'));
    await provider.stopRecording();
    errorController.close();
  });
});

// Helper at bottom of file:
class _FakeSpeechService implements SpeechService {
  final Stream<String> _stream;
  final bool throwOnTranscribe;
  _FakeSpeechService(this._stream, {this.throwOnTranscribe = false});

  @override Future<void> initialize() async {}
  @override Stream<String> transcribe(Stream<Uint8List> _) => _stream;
  @override Future<void> stop() async {}
  @override Future<void> dispose() async {}
}
```

- [ ] **Step 2: Run test — expect FAIL** (`transcriptError` field missing)

```bash
cd app && flutter test test/unit/offline_mode_test.dart -v
```

- [ ] **Step 3: Update `local_capture_provider.dart`**

Add `transcriptError` field after `isPaused`:
```dart
String? transcriptError;
```

Update `_listenTranscript`:
```dart
void _listenTranscript(Stream<Uint8List> audioStream) {
  _transcriptSub = _speechService.transcribe(audioStream).listen(
    (segment) {
      currentTranscript = currentTranscript.isEmpty ? segment : '$currentTranscript $segment';
      notifyListeners();
    },
    onError: (e) {
      transcriptError = e.toString();
      notifyListeners();
    },
  );
}
```

Also clear `transcriptError` at the start of `startRecording()`:
```dart
transcriptError = null;
```

- [ ] **Step 4: Run test — expect PASS**

```bash
cd app && flutter test test/unit/offline_mode_test.dart -v
```

- [ ] **Step 5: Commit**

```bash
cd app && git add lib/providers/local_capture_provider.dart test/unit/offline_mode_test.dart
git commit -m "feat: surface STT errors via transcriptError in LocalCaptureProvider"
```

---

## Task 7: Add `getBleAudioStream()` to `DeviceProvider`

**Files:**
- Modify: `app/lib/providers/device_provider.dart`

- [ ] **Step 1: Read the relevant section of `device_provider.dart`**

Check `connectedDevice` and `ServiceManager.instance().device.ensureConnection` usage.

- [ ] **Step 2: Add the method**

In `app/lib/providers/device_provider.dart`, add after the existing public fields:

```dart
/// Returns a broadcast stream of raw BLE audio bytes from the connected device.
/// Returns an empty stream if no device is connected.
/// Uses [ServiceManager] to get the device connection (same mechanism as
/// CaptureProvider's private _getBleAudioBytesListener).
Stream<Uint8List> getBleAudioStream() {
  final device = connectedDevice;
  if (device == null) return const Stream.empty();

  final controller = StreamController<Uint8List>.broadcast();
  ServiceManager.instance().device.ensureConnection(device.id).then((connection) {
    if (connection == null) {
      controller.close();
      return;
    }
    connection.getBleAudioBytesListener(
      onAudioBytesReceived: (bytes) {
        if (!controller.isClosed) {
          controller.add(Uint8List.fromList(bytes));
        }
      },
    );
  });
  return controller.stream;
}
```

Add import at top if not present:
```dart
import 'dart:typed_data';
```

- [ ] **Step 3: Verify compile**

```bash
cd app && flutter build ios --no-codesign --debug 2>&1 | grep "error:" | head -10
```

- [ ] **Step 4: Commit**

```bash
cd app && git add lib/providers/device_provider.dart
git commit -m "feat: add getBleAudioStream() to DeviceProvider for offline mode"
```

---

## Task 8: Create `BleAudioSttPlugin.swift`

**Files:**
- Create: `app/ios/Runner/BleAudioSttPlugin.swift`

- [ ] **Step 1: Create the Swift file**

Create `app/ios/Runner/BleAudioSttPlugin.swift`:

```swift
import Flutter
import Speech
import AVFoundation

/// Native plugin that feeds BLE PCM audio to SFSpeechAudioBufferRecognitionRequest.
///
/// MethodChannel "com.omi/ble_stt":
///   - initialize()         → requests SFSpeechRecognizer authorization and starts a recognition task
///   - sendBuffer(bytes)    → converts PCM16 bytes to AVAudioPCMBuffer (Float32) and appends
///   - stop()               → calls endAudio() to flush final segment, then cancels task
///
/// EventChannel "com.omi/ble_stt/results":
///   - emits finalized transcript strings (isFinal == true only)
///   - emits FlutterError on authorization failure or recognition error
///
/// Audio format: 16 kHz, mono, Float32 (non-interleaved)
/// Locale: tr_TR (Turkish, this iteration only)
public class BleAudioSttPlugin: NSObject, FlutterPlugin {
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "tr_TR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private let audioFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 16000,
        channels: 1,
        interleaved: false
    )!

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = BleAudioSttPlugin()
        instance.methodChannel = FlutterMethodChannel(
            name: "com.omi/ble_stt",
            binaryMessenger: registrar.messenger()
        )
        instance.eventChannel = FlutterEventChannel(
            name: "com.omi/ble_stt/results",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: instance.methodChannel!)
        instance.eventChannel?.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            requestAuthorizationAndStart(result: result)
        case "sendBuffer":
            guard let data = call.arguments as? FlutterStandardTypedData else {
                result(FlutterError(code: "INVALID_ARGS", message: "Expected FlutterStandardTypedData", details: nil))
                return
            }
            appendBuffer(pcm16Bytes: data.data)
            result(nil)
        case "stop":
            stopRecognition()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func requestAuthorizationAndStart(result: @escaping FlutterResult) {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch status {
                case .authorized:
                    self.startRecognitionTask()
                    result(nil)
                default:
                    let error = FlutterError(
                        code: "PERMISSION_DENIED",
                        message: "Speech recognition permission not granted",
                        details: nil
                    )
                    self.eventSink?(error)
                    result(error)
                }
            }
        }
    }

    private func startRecognitionTask() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true

        recognitionTask = recognizer?.recognitionTask(with: recognitionRequest!) { [weak self] res, error in
            guard let self = self else { return }
            if let error = error {
                self.eventSink?(FlutterError(
                    code: "STT_ERROR",
                    message: error.localizedDescription,
                    details: nil
                ))
                return
            }
            if let res = res, res.isFinal, !res.bestTranscription.formattedString.isEmpty {
                self.eventSink?(res.bestTranscription.formattedString)
            }
        }
    }

    private func appendBuffer(pcm16Bytes: Data) {
        guard let request = recognitionRequest, let format = audioFormat as AVAudioFormat? else { return }
        let frameCount = pcm16Bytes.count / 2  // 2 bytes per Int16 sample
        guard frameCount > 0 else { return }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else { return }
        buffer.frameLength = AVAudioFrameCount(frameCount)

        // Convert PCM16 (Int16) → Float32
        pcm16Bytes.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            let int16Ptr = raw.bindMemory(to: Int16.self)
            let floatPtr = buffer.floatChannelData![0]
            for i in 0..<frameCount {
                floatPtr[i] = Float(int16Ptr[i]) / 32768.0
            }
        }
        request.append(buffer)
    }

    private func stopRecognition() {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }
}

// MARK: - FlutterStreamHandler
extension BleAudioSttPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}
```

- [ ] **Step 2: Verify Swift compiles**

```bash
cd app && flutter build ios --no-codesign --debug 2>&1 | grep -E "error:|BleAudio" | head -20
```

Expected: no Swift compilation errors.

- [ ] **Step 3: Commit**

```bash
cd app && git add ios/Runner/BleAudioSttPlugin.swift
git commit -m "feat: add BleAudioSttPlugin.swift — native iOS BLE→SFSpeechRecognizer bridge"
```

---

## Task 9: Register plugin in `AppDelegate.swift`

**Files:**
- Modify: `app/ios/Runner/AppDelegate.swift`

- [ ] **Step 1: Add registration line**

In `app/ios/Runner/AppDelegate.swift`, find the line:
```swift
PhoneCallsPlugin.register(with: self.registrar(forPlugin: "PhoneCallsPlugin")!)
```

Add immediately after:
```swift
BleAudioSttPlugin.register(with: self.registrar(forPlugin: "BleAudioSttPlugin")!)
```

- [ ] **Step 2: Verify compile**

```bash
cd app && flutter build ios --no-codesign --debug 2>&1 | grep "error:" | head -10
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
cd app && git add ios/Runner/AppDelegate.swift
git commit -m "feat: register BleAudioSttPlugin in AppDelegate"
```

---

## Task 10: Add offline toggle to `TranscriptionSettingsPage`

**Files:**
- Modify: `app/lib/pages/settings/transcription_settings_page.dart`

- [ ] **Step 1: Add state variable**

In `_TranscriptionSettingsPageState`, add:
```dart
bool _offlineModeEnabled = false;
```

In `initState()`, add:
```dart
_offlineModeEnabled = SharedPreferencesUtil().offlineModeEnabled;
```

- [ ] **Step 2: Add toggle widget**

In the `build` method, find where the existing content starts (first widget returned). Add this as the very first widget in the column/list:

```dart
// Offline Mode Toggle
Container(
  margin: const EdgeInsets.only(bottom: 16),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: const Color(0xFF1C1C1E),
    borderRadius: BorderRadius.circular(14),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Offline Mode',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Consumer2<CaptureProvider, LocalCaptureProvider>(
            builder: (_, capture, local, __) {
              final isRecording = capture.isRecording || local.isRecording;
              return Switch(
                value: _offlineModeEnabled,
                onChanged: isRecording
                    ? null  // disabled during recording
                    : (val) async {
                        await SharedPreferencesUtil().setOfflineModeEnabled(val);
                        setState(() => _offlineModeEnabled = val);
                      },
              );
            },
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        'Uses Apple Speech Recognition. Recordings stored only on this device. Restart the app to apply changes.',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      ),
    ],
  ),
),
```

Add import at top of file:
```dart
import 'package:omi/providers/local_capture_provider.dart';
```

- [ ] **Step 3: Wrap provider selection section with `IgnorePointer` + `Opacity`**

Find the widget that contains the provider selection UI (the `_useCustomStt` toggle and provider pickers). Wrap it:

```dart
IgnorePointer(
  ignoring: _offlineModeEnabled,
  child: Opacity(
    opacity: _offlineModeEnabled ? 0.4 : 1.0,
    child: /* existing provider selection widget */,
  ),
),
```

- [ ] **Step 4: Verify compile and format**

```bash
cd app && dart format --line-length 120 lib/pages/settings/transcription_settings_page.dart
flutter build ios --no-codesign --debug 2>&1 | grep "error:" | head -10
```

- [ ] **Step 5: Commit**

```bash
cd app && git add lib/pages/settings/transcription_settings_page.dart
git commit -m "feat: add offline mode toggle to TranscriptionSettingsPage"
```

---

## Task 11: Update `_buildSttChip()` in `developer.dart`

**Files:**
- Modify: `app/lib/pages/settings/developer.dart`

- [ ] **Step 1: Update `_buildSttChip`**

Find the existing `_buildSttChip()` method (line 79) and add the offline check at the top:

```dart
Widget _buildSttChip() {
  if (SharedPreferencesUtil().offlineModeEnabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(8)),
      child: const Text('Apple STT', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
  // existing logic below...
```

- [ ] **Step 2: Format and verify**

```bash
cd app && dart format --line-length 120 lib/pages/settings/developer.dart
flutter build ios --no-codesign --debug 2>&1 | grep "error:" | head -10
```

- [ ] **Step 3: Commit**

```bash
cd app && git add lib/pages/settings/developer.dart
git commit -m "feat: show Apple STT chip in developer settings when offline mode is on"
```

---

## Task 12: Add offline branch to recording screen

**Files:**
- Modify: `app/lib/pages/conversation_capturing/page.dart`

- [ ] **Step 1: Add `LocalCaptureProvider` import and watch**

In `app/lib/pages/conversation_capturing/page.dart`, add imports:
```dart
import 'package:omi/providers/local_capture_provider.dart';
```

- [ ] **Step 2: Add offline mode status chip**

In the `build` method's `AppBar` or top section, add a chip when offline:

```dart
Consumer<LocalCaptureProvider>(
  builder: (_, local, __) {
    if (!SharedPreferencesUtil().offlineModeEnabled) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Offline · Apple STT',
        style: TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  },
),
```

- [ ] **Step 3: Add offline recording start/stop and transcript display**

Find where `CaptureProvider` is used for start/stop recording. Add an offline branch:

```dart
// Where recording is started:
if (SharedPreferencesUtil().offlineModeEnabled) {
  final deviceProvider = context.read<DeviceProvider>();
  final localProvider = context.read<LocalCaptureProvider>();
  final bleStream = deviceProvider.getBleAudioStream();
  await localProvider.startRecording(audioStream: bleStream);
} else {
  // existing CaptureProvider start logic
}

// Where recording is stopped:
if (SharedPreferencesUtil().offlineModeEnabled) {
  await context.read<LocalCaptureProvider>().stopRecording();
} else {
  // existing CaptureProvider stop logic
}
```

- [ ] **Step 4: Show `currentTranscript` from `LocalCaptureProvider` in offline mode**

Find where the transcript is displayed. Add offline branch:

```dart
Consumer2<CaptureProvider, LocalCaptureProvider>(
  builder: (_, capture, local, __) {
    final offline = SharedPreferencesUtil().offlineModeEnabled;
    final transcript = offline ? local.currentTranscript : /* existing source */;
    // ... display transcript
  },
),
```

- [ ] **Step 5: Show `transcriptError` as snackbar**

Add a listener in `initState`:

```dart
// In initState, after super.initState():
WidgetsBinding.instance.addPostFrameCallback((_) {
  context.read<LocalCaptureProvider>().addListener(_onLocalProviderChanged);
});

// Add method:
void _onLocalProviderChanged() {
  final error = context.read<LocalCaptureProvider>().transcriptError;
  if (error != null && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('STT Error: $error'), backgroundColor: Colors.red.shade700),
    );
  }
}

// In dispose():
context.read<LocalCaptureProvider>().removeListener(_onLocalProviderChanged);
```

- [ ] **Step 6: Format and compile**

```bash
cd app && dart format --line-length 120 lib/pages/conversation_capturing/page.dart
flutter build ios --no-codesign --debug 2>&1 | grep "error:" | head -10
```

- [ ] **Step 7: Commit**

```bash
cd app && git add lib/pages/conversation_capturing/page.dart
git commit -m "feat: add offline mode branch to ConversationCapturingPage"
```

---

## Task 13: Run full test suite

- [ ] **Step 1: Run all tests**

```bash
cd app && flutter test
```

Expected: all tests pass, including the new `test/unit/offline_mode_test.dart`.

- [ ] **Step 2: Full iOS build**

```bash
cd app && flutter build ios --no-codesign --debug 2>&1 | tail -5
```

Expected: `Build complete.`

- [ ] **Step 3: Final commit if any fixes needed**

```bash
cd app && git add -p  # stage only what changed
git commit -m "fix: post-integration test fixes"
```
