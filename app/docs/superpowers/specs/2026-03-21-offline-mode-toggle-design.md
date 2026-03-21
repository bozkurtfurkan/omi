# Offline Mode Toggle — Design Spec

**Date:** 2026-03-21
**Platform:** Flutter (iOS primary; Android path unchanged)
**Dependency:** No backend — BLE → Native iOS STT → SQLite

---

## 1. Overview

Add an "Offline Mode" toggle to the existing Omi Flutter app. When enabled:
- No backend WebSocket connection is established
- Audio from Devkit 2 BLE is fed directly to native iOS `SFSpeechRecognizer` via `SFSpeechAudioBufferRecognitionRequest`
- Transcription results are saved to local SQLite only

When disabled, the existing `CaptureProvider` flow is unchanged.

**Locale scope:** Turkish-only (`tr_TR`) for this iteration. Locale-awareness is deferred.

---

## 2. Architecture

### Approach: Provider Swap

The offline flag is persisted in `SharedPreferences`. On app start the flag is read; if `true`, `LocalCaptureProvider` is active and no backend connection is attempted. `CaptureProvider` and its entire downstream are untouched.

### Data Flow (offline mode on)

```
Devkit 2 (BLE)
  → Opus decode → PCM16 Uint8List chunks (16 kHz, mono)
  → MethodChannel "com.omi/ble_stt" sendBuffer(bytes)
  → Swift: AVAudioPCMBuffer (Float32, 16000 Hz, 1ch)
         → SFSpeechAudioBufferRecognitionRequest.append()
  → EventChannel "com.omi/ble_stt/results" onTranscript(text)
  → BleAudioSpeechServiceIos.transcribe() stream
  → LocalCaptureProvider.currentTranscript
  → UI display
  → stopRecording() → AppDatabase (SQLite)
```

### Why not `speech_to_text` package

`speech_to_text` wraps only the microphone path of `SFSpeechRecognizer`. `SFSpeechAudioBufferRecognitionRequest`, which accepts arbitrary PCM buffers, is not exposed. The limitation is in the package, not in iOS. A custom native plugin bypasses the package entirely.

---

## 3. Components

### 3.1 `SharedPreferencesUtil` — add flag

**File:** `lib/backend/preferences.dart`

```dart
bool get offlineModeEnabled => getBool('offlineModeEnabled');
Future<bool> setOfflineModeEnabled(bool v) => saveBool('offlineModeEnabled', v);
```

Use `saveBool` (the existing async wrapper) rather than `setBool` directly, consistent with every other setter in `preferences.dart`.

`getBool` already returns `false` by default when the key is absent — no `?? false` needed.

**Pre-condition:** `SharedPreferencesUtil.init()` is currently commented out in `main.dart` (`// TODO: service removed`). This must be restored **before** `SpeechServiceFactory.create()` is called in `_init()`. The two steps are order-dependent: `init()` must complete first so `_preferences` is non-null when the factory reads `offlineModeEnabled`.

### 3.2 `BleAudioSpeechServiceIos` — new class

**File:** `lib/services/speech/ble_audio_speech_service_ios.dart`

Implements `SpeechService`. Forwards `Stream<Uint8List>` chunks to Swift via `MethodChannel("com.omi/ble_stt")`. Receives finalized transcript segments from Swift via `EventChannel("com.omi/ble_stt/results")`.

**Note:** This is the first `SpeechService` implementation that actually uses the `audioStream` parameter of `transcribe()`. The class-level doc comment in `speech_service.dart` currently states the parameter is ignored by all platform implementations — that comment must be updated when this class is added.

Channel naming follows the existing convention in this codebase (`com.omi/` prefix, matching `com.omi/phone_calls`, `com.omi/environment`, etc.).

### 3.3 `BleAudioSttPlugin.swift` — new native plugin

**File:** `ios/Runner/BleAudioSttPlugin.swift`

Implements `FlutterPlugin` (same pattern as `PhoneCallsPlugin.swift`).

- `MethodChannel("com.omi/ble_stt")`: receives `sendBuffer(bytes: FlutterStandardTypedData)` calls; converts each to `AVAudioPCMBuffer` and appends to the active recognition request.
- `EventChannel("com.omi/ble_stt/results")`: emits finalized transcript strings to Flutter.
- `SFSpeechRecognizer(locale: Locale("tr", "TR"))` — Turkish only this iteration.
- `SFSpeechAudioBufferRecognitionRequest` — audio format: `AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)`. Incoming PCM16 bytes are converted to Float32 before appending.
- `shouldReportPartialResults = true` (improves final accuracy; partial results are received in Swift but only final results are forwarded to the EventChannel — see stream contract below).
- `endAudio()` must be called on the recognition request when the Dart side calls `stop()`, so the final segment is flushed before the recognition task closes.

**Stream contract:** `BleAudioSpeechServiceIos.transcribe()` emits only *finalized* segments (when `SFSpeechRecognitionResult.isFinal == true`), consistent with the `SpeechService` interface contract ("finalized transcript segments only"). Partial results are used internally by `SFSpeechRecognizer` for accuracy but are not forwarded to the Dart stream. This means `LocalCaptureProvider` can safely append each emission to `currentTranscript` without a replace-last-partial mechanism.

**Error handling:** Authorization denial and recognition task errors are sent as error events on the `EventChannel` so they propagate to `BleAudioSpeechServiceIos` and surface to the UI (see Section 3.7).

### 3.4 `AppDelegate.swift` — register plugin

**File:** `ios/Runner/AppDelegate.swift`

Add inside `application(_:didFinishLaunchingWithOptions:)`, following the existing `PhoneCallsPlugin` pattern:

```swift
BleAudioSttPlugin.register(with: self.registrar(forPlugin: "BleAudioSttPlugin")!)
```

### 3.5 `SpeechServiceFactory` — add offline branch

**File:** `lib/services/speech/speech_service_factory.dart`

```dart
static Future<SpeechService> create() async {
  final offlineMode = SharedPreferencesUtil().offlineModeEnabled;
  if (Platform.isIOS) {
    if (offlineMode) return BleAudioSpeechServiceIos();
    return PlatformSpeechServiceIos(); // existing microphone-based
  }
  // Android: existing path unchanged
  ...
}
```

Note: `BleAudioSpeechServiceIos` is returned without pre-calling `initialize()` at factory time. `SFSpeechRecognizer` authorization failures will surface on the first `startRecording()` call, which is acceptable because the UI handles `SpeechServiceException` there.

### 3.6 `LocalCaptureProvider` — inject into `main.dart`

**File:** `lib/main.dart`

`ChangeNotifierProvider.create` is synchronous and cannot `await`. Pattern: declare a module-level `late` variable before `main()`, resolve the service in `_init()`, then pass it synchronously into the provider.

Ordering in `_init()` (explicit, order-dependent):
1. `await SharedPreferencesUtil.init()` — must come before step 2; restores `_preferences` so the flag is readable
2. `_resolvedSpeechService = await SpeechServiceFactory.create()` — reads `offlineModeEnabled` from now-initialized prefs

`SharedPreferencesUtil.init()` is currently safe to restore at line 103 — `ServiceManager.init()` and `PlatformManager.initializeServices()` at lines 94 and 98 do not depend on `SharedPreferencesUtil` being initialized first.

```dart
// top-level, before main()
late SpeechService _resolvedSpeechService;

// inside _init(), after line 98:
await SharedPreferencesUtil.init();
_resolvedSpeechService = await SpeechServiceFactory.create();
```

Then in `MultiProvider`:

```dart
ChangeNotifierProvider(
  create: (_) => LocalCaptureProvider(
    speechService: _resolvedSpeechService,
    database: AppDatabase.instance,
  ),
),
```

### 3.7 `LocalCaptureProvider` — surface errors

**File:** `lib/providers/local_capture_provider.dart`

**Current state (not yet changed):** line 101 silently swallows errors:
```dart
onError: (_) => notifyListeners(),
```

**Must change during implementation:** add a `transcriptError` field and update the error handler:

```dart
String? transcriptError;

void _listenTranscript(Stream<Uint8List> audioStream) {
  _transcriptSub = _speechService.transcribe(audioStream).listen(
    (segment) { ... },
    onError: (e) {
      transcriptError = e.toString();
      notifyListeners();
    },
  );
}
```

The recording UI reads `transcriptError` and shows a snackbar/banner when non-null.

### 3.8 `TranscriptionSettingsPage` — add toggle

**File:** `lib/pages/settings/transcription_settings_page.dart`

Toggle at the top of the page:

- On: `await SharedPreferencesUtil().setOfflineModeEnabled(true)` (async setter, `await` in the `onChanged` handler).
- Off: `await SharedPreferencesUtil().setOfflineModeEnabled(false)`.
- **Takes effect on next app launch.** The `LocalCaptureProvider` and its injected `SpeechService` are created at startup; toggling at runtime does not swap the live provider. The UI should communicate this clearly.
- **Toggle is disabled while a recording is in progress** (check `CaptureProvider.isRecording || LocalCaptureProvider.isRecording`). This avoids mid-session state changes.
- All provider selection widgets below the toggle are wrapped in `IgnorePointer` + `Opacity(0.4)` when toggle is on.
- Description text: `"Offline mode uses Apple Speech Recognition. Recordings are stored only on this device. Restart the app to apply changes."`

### 3.9 `developer.dart` — update STT chip

**File:** `lib/pages/settings/developer.dart`

```dart
Widget _buildSttChip() {
  if (SharedPreferencesUtil().offlineModeEnabled) return _chip('Apple STT');
  // existing logic...
}
```

Note: `_buildSttChip()` reads `SharedPreferencesUtil()` directly (not via `ChangeNotifier`), matching the existing pattern in this file. The chip will not update reactively while the settings page is open; this is a known limitation consistent with the rest of the page's pattern.

### 3.10 Recording screen — consume `LocalCaptureProvider`

**File:** `lib/pages/conversation_capturing/page.dart`

- Add `context.watch<LocalCaptureProvider>()`.
- Read `SharedPreferencesUtil().offlineModeEnabled`.
- Offline mode on:
  - Obtain `bleStream` via a new public method on `DeviceProvider`: `Stream<Uint8List> getBleAudioStream()`. This method calls `ServiceManager.instance().device.ensureConnection(deviceId)` (same underlying mechanism as `CaptureProvider._getBleAudioBytesListener`) and wraps the callback in a `StreamController.broadcast()`. Adding this public method avoids duplicating the private BLE subscription logic and avoids a double-consume problem.
  - Call `LocalCaptureProvider.startRecording(audioStream: bleStream)`.
  - Display `LocalCaptureProvider.currentTranscript`.
  - Show `transcriptError` as a snackbar when non-null.
  - On stop: `LocalCaptureProvider.stopRecording()` → SQLite.
  - Status chip at top of screen: `"Offline · Apple STT"`.
- Offline mode off: existing flow, no changes.

---

## 4. Unchanged Components

- `CaptureProvider` — not touched
- `ConversationProvider` — not touched
- `AppDatabase` schema — sufficient as-is
- Android flow — not touched

---

## 5. Error Cases

| Condition | Behavior |
|-----------|----------|
| BLE not connected, offline mode on | `startRecording()` fails; UI shows "Devkit 2 not connected" |
| `SFSpeechRecognizer` permission denied | `SpeechServiceException` thrown; UI shows permission prompt |
| Turkish offline model not on device | `SFSpeechRecognizer` falls back to online recognition (must be disclosed in privacy policy) |
| SQLite write error | `stopRecording()` logs error; UI shows error banner |
| Toggle flipped during active recording | Toggle is disabled; user must stop recording first |
| EventChannel error from Swift | Propagates via `transcriptError`; shown as snackbar |

---

## 6. File Change Summary

| File | Change |
|------|--------|
| `lib/backend/preferences.dart` | Add `offlineModeEnabled` getter and async `setOfflineModeEnabled()` |
| `lib/main.dart` | Restore `SharedPreferencesUtil.init()`; add `late SpeechService _resolvedSpeechService`; resolve in `_init()`; inject `LocalCaptureProvider` |
| `lib/services/speech/ble_audio_speech_service_ios.dart` | **New** |
| `lib/services/speech/speech_service.dart` | Update class-level doc comment — `audioStream` is no longer ignored by all implementations |
| `lib/services/speech/speech_service_factory.dart` | Add offline branch |
| `lib/providers/local_capture_provider.dart` | Add `transcriptError` field; update `_listenTranscript` error handler |
| `lib/providers/device_provider.dart` | Add public `getBleAudioStream()` method |
| `ios/Runner/BleAudioSttPlugin.swift` | **New** |
| `ios/Runner/AppDelegate.swift` | Register `BleAudioSttPlugin` |
| `lib/pages/settings/transcription_settings_page.dart` | Add toggle |
| `lib/pages/settings/developer.dart` | Update `_buildSttChip()` |
| `lib/pages/conversation_capturing/page.dart` | Add offline mode branch |

---

## 7. Test Criteria

- Toggle on/off correctly persists `offlineModeEnabled` in `SharedPreferences`
- Toggle is disabled while recording is active
- No WebSocket connection attempt in offline mode
- BLE audio bytes reach Swift plugin; transcript returns to Flutter
- `stopRecording()` creates a new row in SQLite
- `transcriptError` surfaces as snackbar on STT failure
- Provider selection widgets are non-interactive when offline toggle is on
- `_buildSttChip()` shows `"Apple STT"` in offline mode
