# Omi Custom Mobile App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fork BasedHardware/omi and strip it down to a fully offline Flutter app with Devkit 2 BLE connection, on-device Turkish transcription, and local conversation history.

**Architecture:** Fork the Omi Flutter app, delete all backend/cloud/plugin code, replace cloud STT with a `SpeechService` abstraction backed by iOS `SFSpeechRecognizer` and Android `SpeechRecognizer` (VOSK fallback), and store conversations in local SQLite via `drift`.

**Tech Stack:** Flutter, Dart, drift (SQLite), flutter_blue_plus (BLE), flutter_opus (Opus decode), speech_to_text (iOS/Android STT), vosk_flutter (Android offline fallback), permission_handler.

---

## Pre-requisites

- Dart/Flutter SDK installed (`flutter doctor` clean)
- Xcode 15+ for iOS builds
- Android Studio for Android builds
- A GitHub account to fork the repo
- Physical Devkit 2 device for final integration testing

---

## Task 1: Fork & Clone the Repo

**Files:**
- Creates: `app/` (entire fork)

- [ ] **Step 1: Fork on GitHub**

  Go to https://github.com/BasedHardware/omi and click "Fork". Name it `omi-custom` or similar.

- [ ] **Step 2: Clone locally**

  ```bash
  git clone https://github.com/YOUR_USERNAME/omi-custom.git
  cd omi-custom/app
  flutter pub get
  flutter doctor
  ```

- [ ] **Step 3: Verify the app builds**

  ```bash
  flutter build ios --no-codesign   # or flutter run on a simulator
  flutter build apk --debug
  ```

  Expected: build completes (may have warnings — ignore for now).

- [ ] **Step 4: Set iOS minimum deployment target to iOS 17**

  Edit `ios/Podfile`:
  ```ruby
  platform :ios, '17.0'
  ```

  Edit `ios/Runner.xcodeproj/project.pbxproj` — find all occurrences of `IPHONEOS_DEPLOYMENT_TARGET` and set to `17.0`.

- [ ] **Step 5: Set Android minimum SDK to 29**

  Edit `android/app/build.gradle`:
  ```groovy
  minSdkVersion 29
  targetSdkVersion 34
  ```

- [ ] **Step 6: Commit**

  ```bash
  git add .
  git commit -m "chore: fork omi, set iOS 17 + Android API 29 minimums"
  ```

---

## Task 2: Remove Unused pubspec Dependencies

**Files:**
- Modify: `app/pubspec.yaml`

- [ ] **Step 1: Identify packages to remove**

  Open `pubspec.yaml`. Remove the following dependency groups (search by package name):
  - Firebase packages: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`, `firebase_analytics`
  - Cloud STT: `deepgram_sdk` or any deepgram/speechmatics/soniox package
  - In-app purchases: `purchases_flutter`, `in_app_purchase`
  - Push notifications: `flutter_local_notifications`, `awesome_notifications`
  - Calendar/tasks integrations: any Google Calendar, Tasks, Apple Reminders packages
  - Persona/AI: any LangChain, OpenAI client packages used only for personas
  - Analytics: `mixpanel_flutter`, `amplitude_flutter`, or similar

  **Keep:**
  - BLE: `flutter_blue_plus`
  - Opus decode: `flutter_opus` or `opus_dart`
  - State management: `provider` or `riverpod` (whatever Omi uses)
  - Navigation: `go_router` or equivalent
  - Storage: `drift`, `sqlite3_flutter_libs`, `path_provider`
  - Permissions: `permission_handler`
  - HTTP (if needed for VOSK model download): `dio` or `http`

- [ ] **Step 2: Run pub get and fix errors**

  ```bash
  flutter pub get
  ```

  Fix any import errors by deleting the import lines. Don't fix the callers yet — that happens in later tasks.

- [ ] **Step 3: Commit**

  ```bash
  git add pubspec.yaml pubspec.lock
  git commit -m "chore: remove cloud/firebase/plugin pubspec dependencies"
  ```

---

## Task 3: Delete Unused Pages

**Files:**
- Delete directories under `app/lib/pages/`:
  - `action_items/`
  - `announcements/`
  - `apps/` (plugin marketplace)
  - `chat/`
  - `payments/`
  - `persona/`
  - `phone_calls/`
  - `processing_conversations/`
  - `referral/`
  - `sdcard/`
  - `speech_profile/`

- Keep directories:
  - `capture/` or `conversation_capturing/` (recording screen)
  - `conversations/` (conversation list)
  - `conversation_detail/` (transcript view)
  - `onboarding/` (device pairing — keep only BLE pairing steps)
  - `settings/` (will be simplified in Task 9)
  - `home/` (if it acts as the app shell/navigation)

- [ ] **Step 1: Delete unwanted page directories**

  ```bash
  cd app/lib/pages
  rm -rf action_items announcements apps chat payments persona phone_calls processing_conversations referral sdcard speech_profile
  ```

- [ ] **Step 2: Fix broken imports**

  ```bash
  cd app
  flutter analyze 2>&1 | grep "error" | grep "import"
  ```

  For each broken import in routing/navigation files, delete the import line and any reference to the deleted page widget.

- [ ] **Step 3: Update router/navigation**

  Find the main router file (likely `lib/core/router.dart` or inside `lib/pages/home/`). Remove routes for all deleted pages. The remaining routes should be:
  - `/` → Home/Recording screen
  - `/conversations` → Conversation list
  - `/conversations/:id` → Conversation detail
  - `/device` → BLE device pairing
  - `/settings` → Settings

- [ ] **Step 4: Verify no compile errors**

  ```bash
  flutter analyze
  ```

  Expected: 0 errors (warnings are OK for now).

- [ ] **Step 5: Commit**

  ```bash
  git add -A
  git commit -m "chore: delete unused pages (plugins, persona, payments, etc.)"
  ```

---

## Task 4: Delete Unused Services

**Files:**
- Delete from `app/lib/services/`:
  - `agent_chat_service.dart`
  - `notifications.dart` + `notifications/`
  - `google_calendar_service.dart`
  - `google_tasks_service.dart`
  - `apple_reminders_service.dart`
  - `freemium_transcription_service.dart`
  - `custom_stt_log_service.dart`
  - `audio_download_service.dart`
  - `connectivity_service.dart`
  - Any Asana, Clickup, Todoist, Apple Health, auth service files

- Keep:
  - `devices.dart` + `devices/` (BLE + audio stream)
  - `sockets.dart` + `sockets/` (device audio framing)

- [ ] **Step 1: Delete service files**

  ```bash
  cd app/lib/services
  rm -f agent_chat_service.dart notifications.dart audio_download_service.dart \
        freemium_transcription_service.dart custom_stt_log_service.dart \
        google_calendar_service.dart google_tasks_service.dart \
        apple_reminders_service.dart connectivity_service.dart
  rm -rf notifications/
  # Delete any other integration service files found in this directory
  ```

- [ ] **Step 2: Delete backend/ directory contents**

  ```bash
  cd app/lib
  # Review backend/ — delete all API client files, keep nothing
  rm -rf backend/
  ```

- [ ] **Step 3: Fix broken imports**

  ```bash
  flutter analyze 2>&1 | grep "error"
  ```

  Delete broken import lines. For now, if a provider or widget references a deleted service, comment out or stub the reference with a `// TODO: removed` comment.

- [ ] **Step 4: Verify no compile errors**

  ```bash
  flutter analyze
  ```

- [ ] **Step 5: Commit**

  ```bash
  git add -A
  git commit -m "chore: delete unused services and backend/ API layer"
  ```

---

## Task 5: Remove Backend Calls from Providers & Models

**Files:**
- Modify: files under `app/lib/providers/`
- Modify: files under `app/lib/models/`

- [ ] **Step 1: Identify providers that call deleted services**

  ```bash
  grep -r "import.*backend\|ApiService\|FirebaseFirestore\|FirebaseAuth\|http.get\|http.post" app/lib/providers/ --include="*.dart" -l
  ```

- [ ] **Step 2: For each provider found, remove cloud sync calls**

  Pattern: keep local state mutations, delete any `await ApiService.xxx()` calls and Firebase listeners.

  Example — in a memory/conversation provider:
  ```dart
  // BEFORE:
  Future<void> loadConversations() async {
    final remote = await ApiService.getConversations(); // DELETE THIS
    final local = await _db.getAll();
    _conversations = remote + local; // CHANGE TO: _conversations = local
  }

  // AFTER:
  Future<void> loadConversations() async {
    _conversations = await _db.getAll();
    notifyListeners();
  }
  ```

- [ ] **Step 3: Remove auth providers**

  Delete or stub any `AuthProvider`, `UserProvider` that depend on Firebase Auth. The app needs no authentication.

- [ ] **Step 4: Verify no compile errors**

  ```bash
  flutter analyze
  ```

- [ ] **Step 5: Run app on simulator**

  ```bash
  flutter run
  ```

  Expected: app launches without crash. Some screens may look empty — that's OK.

- [ ] **Step 6: Commit**

  ```bash
  git add -A
  git commit -m "chore: strip backend calls from providers, app is now fully local"
  ```

---

## Task 6: Set Up Drift SQLite Database

**Files:**
- Create: `app/lib/database/app_database.dart`
- Create: `app/lib/database/app_database.g.dart` (generated)
- Create: `app/test/database/app_database_test.dart`

The `drift` package uses code generation. After writing the schema, run `build_runner` to generate the `.g.dart` file.

- [ ] **Step 1: Add drift dependencies (if not already in pubspec)**

  In `pubspec.yaml` under `dependencies`:
  ```yaml
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.9.0
  ```

  Under `dev_dependencies`:
  ```yaml
  drift_dev: ^2.18.0
  build_runner: ^2.4.0
  ```

  ```bash
  flutter pub get
  ```

- [ ] **Step 2: Write the failing test first**

  Create `app/test/database/app_database_test.dart`:
  ```dart
  import 'package:drift/native.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:your_app/database/app_database.dart';

  void main() {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async => await db.close());

    test('inserts and retrieves a conversation', () async {
      final id = const Uuid().v4();
      final now = DateTime.now();

      await db.into(db.conversations).insert(ConversationsCompanion.insert(
        id: id,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 5)),
        durationSeconds: 300,
        transcript: 'Merhaba dünya',
        locale: 'tr_TR',
      ));

      final results = await db.select(db.conversations).get();
      expect(results.length, 1);
      expect(results.first.transcript, 'Merhaba dünya');
      expect(results.first.durationSeconds, 300);
    });

    test('title defaults to null', () async {
      final id = const Uuid().v4();
      final now = DateTime.now();

      await db.into(db.conversations).insert(ConversationsCompanion.insert(
        id: id,
        startedAt: now,
        endedAt: now,
        durationSeconds: 0,
        transcript: '',
        locale: 'tr_TR',
      ));

      final result = (await db.select(db.conversations).get()).first;
      expect(result.title, isNull);
      expect(result.audioPath, isNull);
    });
  }
  ```

- [ ] **Step 3: Run test to verify it fails**

  ```bash
  flutter test test/database/app_database_test.dart
  ```

  Expected: FAIL — `AppDatabase` not found.

- [ ] **Step 4: Create the database schema**

  Create `app/lib/database/app_database.dart`:
  ```dart
  import 'dart:io';
  import 'package:drift/drift.dart';
  import 'package:drift/native.dart';
  import 'package:path_provider/path_provider.dart';
  import 'package:path/path.dart' as p;

  part 'app_database.g.dart';

  class Conversations extends Table {
    TextColumn get id => text()();
    DateTimeColumn get startedAt => dateTime()();
    DateTimeColumn get endedAt => dateTime()();
    IntColumn get durationSeconds => integer()();
    TextColumn get title => text().nullable()();
    TextColumn get transcript => text()();
    TextColumn get audioPath => text().nullable()();
    TextColumn get locale => text().withDefault(const Constant('tr_TR'))();

    @override
    Set<Column> get primaryKey => {id};
  }

  @DriftDatabase(tables: [Conversations])
  class AppDatabase extends _$AppDatabase {
    AppDatabase([QueryExecutor? executor])
        : super(executor ?? _openConnection());

    @override
    int get schemaVersion => 1;

    static LazyDatabase _openConnection() {
      return LazyDatabase(() async {
        final dir = await getApplicationDocumentsDirectory();
        final file = File(p.join(dir.path, 'omi_local.db'));
        return NativeDatabase.createInBackground(file);
      });
    }
  }
  ```

- [ ] **Step 5: Run code generation**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

  Expected: `app_database.g.dart` is created.

- [ ] **Step 6: Run test to verify it passes**

  ```bash
  flutter test test/database/app_database_test.dart
  ```

  Expected: PASS.

- [ ] **Step 7: Register database as a singleton in main.dart**

  In `lib/main.dart`, initialize AppDatabase and provide it via the DI mechanism Omi uses (Provider, GetIt, etc.):
  ```dart
  // If using Provider:
  runApp(
    Provider<AppDatabase>(
      create: (_) => AppDatabase(),
      dispose: (_, db) => db.close(),
      child: const MyApp(),
    ),
  );
  ```

- [ ] **Step 8: Commit**

  ```bash
  git add -A
  git commit -m "feat: add drift SQLite schema for Conversation"
  ```

---

## Task 7: Create SpeechService Abstraction + PlatformSpeechService (iOS)

**Files:**
- Create: `app/lib/services/speech/speech_service.dart`
- Create: `app/lib/services/speech/platform_speech_service_ios.dart`
- Create: `app/test/services/speech/platform_speech_service_test.dart`

- [ ] **Step 1: Add speech_to_text package**

  In `pubspec.yaml`:
  ```yaml
  speech_to_text: ^6.6.0
  ```
  ```bash
  flutter pub get
  ```

- [ ] **Step 2: Write the abstract interface**

  Create `app/lib/services/speech/speech_service.dart`:
  ```dart
  import 'dart:typed_data';

  /// Each emitted String is a finalized transcript segment.
  /// Partial/interim results are NOT emitted.
  /// The stream closes when the session ends.
  abstract class SpeechService {
    /// Initialize the service and request permissions.
    /// Throws [SpeechServiceException] if unavailable.
    Future<void> initialize();

    /// Begin transcription. Returns a stream of finalized segments.
    Stream<String> transcribe(Stream<Uint8List> audioStream);

    /// Stop transcription and close the stream.
    Future<void> stop();

    /// Release resources.
    Future<void> dispose();
  }

  class SpeechServiceException implements Exception {
    final String message;
    const SpeechServiceException(this.message);

    @override
    String toString() => 'SpeechServiceException: $message';
  }
  ```

- [ ] **Step 3: Write failing test for iOS platform service**

  Create `app/test/services/speech/platform_speech_service_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:your_app/services/speech/speech_service.dart';
  import 'package:your_app/services/speech/platform_speech_service_ios.dart';

  void main() {
    test('PlatformSpeechServiceIos implements SpeechService', () {
      final service = PlatformSpeechServiceIos();
      expect(service, isA<SpeechService>());
    });

    test('transcribe returns a Stream<String>', () {
      final service = PlatformSpeechServiceIos();
      // We cannot call initialize() in unit tests (requires device).
      // Just verify the type contract.
      expect(service.transcribe, isNotNull);
    });
  }
  ```

- [ ] **Step 4: Run test to verify it fails**

  ```bash
  flutter test test/services/speech/platform_speech_service_test.dart
  ```

  Expected: FAIL — class not found.

- [ ] **Step 5: Implement PlatformSpeechServiceIos**

  Create `app/lib/services/speech/platform_speech_service_ios.dart`:
  ```dart
  import 'dart:async';
  import 'dart:typed_data';
  import 'package:speech_to_text/speech_to_text.dart';
  import 'speech_service.dart';

  class PlatformSpeechServiceIos implements SpeechService {
    final SpeechToText _stt = SpeechToText();
    final StreamController<String> _controller = StreamController<String>();
    bool _initialized = false;

    @override
    Future<void> initialize() async {
      _initialized = await _stt.initialize(
        onError: (error) => _controller.addError(
          SpeechServiceException(error.errorMsg),
        ),
      );
      if (!_initialized) {
        throw const SpeechServiceException(
          'Speech recognition unavailable or permission denied',
        );
      }
    }

    @override
    Stream<String> transcribe(Stream<Uint8List> audioStream) {
      // speech_to_text uses the device microphone directly via SFSpeechRecognizer.
      // The audioStream from BLE is decoded Opus PCM — we feed it to
      // the STT via listenForWords using the audio source callback.
      // For the initial implementation, we use the default microphone source
      // and the BLE audio is handled at the capture layer.
      _stt.listen(
        onResult: (result) {
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            _controller.add(result.recognizedWords);
          }
        },
        localeId: 'tr_TR',
        listenMode: ListenMode.dictation,
        cancelOnError: false,
      );
      return _controller.stream;
    }

    @override
    Future<void> stop() async {
      await _stt.stop();
    }

    @override
    Future<void> dispose() async {
      await _stt.cancel();
      await _controller.close();
    }
  }
  ```

  > **Audio routing decision — read before implementing:** `SFSpeechRecognizer` (and the Android `SpeechRecognizer`) listen to the device microphone, not to an arbitrary PCM stream. The Devkit 2 BLE audio cannot be injected directly into these APIs. There are two valid implementation strategies:
  >
  > **Strategy A (recommended for this iteration):** Decode BLE Opus audio and route it to the device's audio output (speaker/earpiece). SFSpeechRecognizer then picks it up via the microphone. The `audioStream` parameter in `transcribe()` is not used by this implementation — the recognizer captures whatever is audible. This is simple but means the phone microphone also picks up ambient sound.
  >
  > **Strategy B (future/Whisper path):** Feed BLE PCM bytes directly to Whisper or VOSK for processing, bypassing the OS recognizer entirely. This is what `WhisperSpeechService` and `VoskSpeechService` (via `acceptWaveformBytes`) will do.
  >
  > **For this task, use Strategy A.** The `audioStream` parameter is accepted but ignored; the OS recognizer listens to the mic. Add a comment in the implementation to make this explicit. This is a known limitation to be resolved when Whisper is integrated.

- [ ] **Step 6: Run test to verify it passes**

  ```bash
  flutter test test/services/speech/platform_speech_service_test.dart
  ```

  Expected: PASS.

- [ ] **Step 7: Commit**

  ```bash
  git add -A
  git commit -m "feat: add SpeechService abstraction + PlatformSpeechServiceIos"
  ```

---

## Task 8: Implement VoskSpeechService (Android Offline Fallback)

**Files:**
- Create: `app/lib/services/speech/vosk_speech_service.dart`
- Create: `app/lib/services/speech/speech_service_factory.dart`
- Modify: `app/test/services/speech/platform_speech_service_test.dart`

- [ ] **Step 1: Add vosk_flutter and device_info_plus packages**

  In `pubspec.yaml`:
  ```yaml
  vosk_flutter: ^0.3.0
  device_info_plus: ^10.1.0
  ```
  ```bash
  flutter pub get
  ```

- [ ] **Step 2: Write failing test for factory**

  Add to `app/test/services/speech/platform_speech_service_test.dart`:
  ```dart
  import 'dart:io';
  import 'package:your_app/services/speech/speech_service_factory.dart';

  // ... existing tests above ...

  test('factory returns correct service type for platform', () {
    final service = SpeechServiceFactory.create();
    expect(service, isA<SpeechService>());
  });
  ```

- [ ] **Step 3: Run test to verify it fails**

  ```bash
  flutter test test/services/speech/platform_speech_service_test.dart
  ```

  Expected: FAIL — `SpeechServiceFactory` not found.

- [ ] **Step 4: Implement VoskSpeechService**

  > **Before writing this implementation:** Run `flutter pub deps | grep vosk` and open the `vosk_flutter` package README at pub.dev to confirm the exact API for your installed version. The method names below (`VoskFlutterPlugin.instance()`, `createModel`, `createRecognizer`, `acceptWaveformBytes`) match the `^0.3.x` API. If the version differs, adjust accordingly — do not copy verbatim without verifying.

  Create `app/lib/services/speech/vosk_speech_service.dart`:
  ```dart
  import 'dart:async';
  import 'dart:typed_data';
  import 'package:vosk_flutter/vosk_flutter.dart';
  import 'speech_service.dart';

  // vosk-model-small-tr-0.3 (~40 MB) — lightweight, lower accuracy
  // vosk-model-tr-0.3       (~1.8 GB) — full accuracy, too large for mobile
  // Recommendation: start with small model; switch if accuracy is insufficient
  const _modelUrl =
      'https://alphacephei.com/vosk/models/vosk-model-small-tr-0.3.zip';
  const _modelName = 'vosk-model-small-tr-0.3';

  class VoskSpeechService implements SpeechService {
    Model? _model;
    Recognizer? _recognizer;
    final StreamController<String> _controller = StreamController<String>();

    /// [onDownloadProgress] is called with values 0.0–1.0 during model download.
    final void Function(double progress)? onDownloadProgress;

    VoskSpeechService({this.onDownloadProgress});

    @override
    Future<void> initialize() async {
      final vosk = VoskFlutterPlugin.instance();

      // Load or download model — verify these method names against your vosk_flutter version
      _model = await vosk.createModel(_modelName).catchError((_) async {
        // Model not cached — download it
        await vosk.loadModelFromNetwork(
          _modelUrl,
          onProgress: onDownloadProgress,
        );
        return vosk.createModel(_modelName);
      });

      _recognizer = await vosk.createRecognizer(
        model: _model!,
        sampleRate: 16000,
      );
    }

    @override
    Stream<String> transcribe(Stream<Uint8List> audioStream) {
      audioStream.listen(
        (chunk) async {
          if (_recognizer == null) return;
          final resultJson = await _recognizer!.acceptWaveformBytes(chunk);
          if (resultJson != null) {
            // resultJson is {"text": "..."} — parse the text field
            final text = _parseVoskResult(resultJson);
            if (text.isNotEmpty) _controller.add(text);
          }
        },
        onDone: () async {
          final finalJson = await _recognizer?.getFinalResult();
          if (finalJson != null) {
            final text = _parseVoskResult(finalJson);
            if (text.isNotEmpty) _controller.add(text);
          }
          await _controller.close();
        },
        onError: (e) => _controller.addError(SpeechServiceException('$e')),
      );
      return _controller.stream;
    }

    String _parseVoskResult(String json) {
      // Simple JSON parse: {"text": "merhaba"}
      final match = RegExp(r'"text"\s*:\s*"([^"]*)"').firstMatch(json);
      return match?.group(1) ?? '';
    }

    @override
    Future<void> stop() async {
      await _recognizer?.reset();
    }

    @override
    Future<void> dispose() async {
      _recognizer?.free();
      _model?.free();
      await _controller.close();
    }
  }
  ```

- [ ] **Step 5: Implement PlatformSpeechServiceAndroid (API 31+ native)**

  Create `app/lib/services/speech/platform_speech_service_android.dart`:
  ```dart
  import 'dart:async';
  import 'dart:typed_data';
  import 'package:speech_to_text/speech_to_text.dart';
  import 'speech_service.dart';

  /// Uses Android's createOnDeviceRecognitionIntent (API 31+).
  /// Requires the Turkish language pack to be installed on the device.
  /// Throws SpeechServiceException if on-device recognition is unavailable.
  class PlatformSpeechServiceAndroid implements SpeechService {
    final SpeechToText _stt = SpeechToText();
    final StreamController<String> _controller = StreamController<String>();
    bool _initialized = false;

    @override
    Future<void> initialize() async {
      _initialized = await _stt.initialize(
        onError: (error) => _controller.addError(
          SpeechServiceException(error.errorMsg),
        ),
      );
      if (!_initialized) {
        throw const SpeechServiceException(
          'On-device Turkish STT unavailable — language pack may not be installed',
        );
      }
    }

    @override
    Stream<String> transcribe(Stream<Uint8List> audioStream) {
      _stt.listen(
        onResult: (result) {
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            _controller.add(result.recognizedWords);
          }
        },
        localeId: 'tr_TR',
        listenMode: ListenMode.dictation,
        cancelOnError: false,
      );
      return _controller.stream;
    }

    @override
    Future<void> stop() async => _stt.stop();

    @override
    Future<void> dispose() async {
      await _stt.cancel();
      await _controller.close();
    }
  }
  ```

- [ ] **Step 6: Implement SpeechServiceFactory (three-tier Android strategy)**

  Create `app/lib/services/speech/speech_service_factory.dart`:
  ```dart
  import 'dart:io';
  import 'package:device_info_plus/device_info_plus.dart';
  import 'speech_service.dart';
  import 'platform_speech_service_ios.dart';
  import 'platform_speech_service_android.dart';
  import 'vosk_speech_service.dart';

  class SpeechServiceFactory {
    /// Creates the appropriate SpeechService for the current platform.
    ///
    /// iOS   → PlatformSpeechServiceIos (SFSpeechRecognizer, tr_TR)
    /// Android API 31+ → PlatformSpeechServiceAndroid (native on-device STT)
    ///   └─ falls back to VoskSpeechService if native init throws
    /// Android API < 31 → VoskSpeechService directly
    static Future<SpeechService> create({
      void Function(double progress)? onVoskDownloadProgress,
    }) async {
      if (Platform.isIOS) {
        return PlatformSpeechServiceIos();
      }

      // Android — check API level
      final info = await DeviceInfoPlugin().androidInfo;
      final sdkInt = info.version.sdkInt;

      if (sdkInt >= 31) {
        // Try native on-device first; fall back to VOSK if unavailable
        final native = PlatformSpeechServiceAndroid();
        try {
          await native.initialize();
          return native;
        } on SpeechServiceException {
          // Language pack not installed or permission denied — use VOSK
          return VoskSpeechService(onDownloadProgress: onVoskDownloadProgress);
        }
      }

      // API < 31: native on-device STT not available
      return VoskSpeechService(onDownloadProgress: onVoskDownloadProgress);
    }
  }
  ```

  Add `device_info_plus` to `pubspec.yaml` if not already present:
  ```yaml
  device_info_plus: ^10.1.0
  ```

- [ ] **Step 7: Run tests to verify they pass**

  ```bash
  flutter test test/services/speech/platform_speech_service_test.dart
  ```

  Expected: PASS.

- [ ] **Step 8: Commit**

  ```bash
  git add -A
  git commit -m "feat: add VoskSpeechService and SpeechServiceFactory"
  ```

---

## Task 9: Wire SpeechService into the Recording/Capture Flow

**Files:**
- Modify: `app/lib/pages/capture/` or `app/lib/pages/conversation_capturing/` (recording page)
- Modify: `app/lib/providers/` (conversation/capture provider)

The Omi capture flow: BLE audio frames arrive → Opus decode → sent to STT. We replace the STT call with `SpeechService`.

- [ ] **Step 1: Find the capture provider**

  ```bash
  grep -r "Deepgram\|SpeechToText\|transcrib\|STT" app/lib/providers/ --include="*.dart" -l
  grep -r "Deepgram\|SpeechToText\|transcrib\|STT" app/lib/pages/ --include="*.dart" -l
  ```

  Open the identified file(s).

- [ ] **Step 2: Write a test for the capture provider**

  Create `app/test/providers/capture_provider_test.dart`:
  ```dart
  import 'dart:async';
  import 'dart:typed_data';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:mockito/annotations.dart';
  import 'package:mockito/mockito.dart';
  import 'package:your_app/services/speech/speech_service.dart';
  import 'package:your_app/providers/capture_provider.dart'; // adjust path
  import 'package:your_app/database/app_database.dart';

  @GenerateMocks([SpeechService, AppDatabase])
  import 'capture_provider_test.mocks.dart';

  void main() {
    test('transcript segments are appended to conversation', () async {
      final mockSpeech = MockSpeechService();
      final mockDb = MockAppDatabase();
      final controller = StreamController<String>();

      when(mockSpeech.initialize()).thenAnswer((_) async {});
      when(mockSpeech.transcribe(any)).thenAnswer((_) => controller.stream);

      final provider = CaptureProvider(
        speechService: mockSpeech,
        database: mockDb,
      );

      await provider.startRecording();
      controller.add('Merhaba');
      controller.add('dünya');
      await Future.delayed(Duration.zero);

      expect(provider.currentTranscript, 'Merhaba dünya');
    });
  }
  ```

  Run `build_runner` to generate mocks:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

- [ ] **Step 3: Run test to verify it fails**

  ```bash
  flutter test test/providers/capture_provider_test.dart
  ```

  Expected: FAIL — `CaptureProvider` constructor doesn't accept `speechService`.

- [ ] **Step 4: Refactor CaptureProvider to accept SpeechService**

  The Omi devices service exposes BLE audio as a stream. Locate the audio stream in the existing `DevicesService` (file: `app/lib/services/devices.dart`). It typically exposes a `Stream<List<int>>` or `Stream<Uint8List>` of decoded PCM audio frames. The field is usually named `audioStream`, `bleAudioStream`, or similar — run `grep -r "Stream" app/lib/services/devices.dart` to confirm the exact name.

  In the capture provider file, replace the existing STT/Deepgram initialization:
  ```dart
  import 'dart:typed_data';
  import 'package:your_app/services/devices.dart'; // Omi's existing BLE service

  class CaptureProvider extends ChangeNotifier {
    final SpeechService _speechService;
    final AppDatabase _database;
    final DevicesService _devicesService; // Omi's existing BLE devices service
    String currentTranscript = '';
    StreamSubscription<String>? _transcriptSub;
    DateTime? _recordingStartTime;

    CaptureProvider({
      required SpeechService speechService,
      required AppDatabase database,
      required DevicesService devicesService,
    })  : _speechService = speechService,
          _database = database,
          _devicesService = devicesService;

    Future<void> startRecording() async {
      await _speechService.initialize();
      currentTranscript = '';
      _recordingStartTime = DateTime.now();

      // _devicesService.audioStream is the Opus-decoded PCM stream from Devkit 2.
      // Confirm the exact property name in app/lib/services/devices.dart.
      final bleAudioStream = _devicesService.audioStream
          .map((frames) => Uint8List.fromList(frames));

      _transcriptSub = _speechService.transcribe(bleAudioStream).listen(
        (segment) {
          currentTranscript = currentTranscript.isEmpty
              ? segment
              : '$currentTranscript $segment';
          notifyListeners();
        },
        onError: (e) {
          // Show error to user — STT failed
          notifyListeners();
        },
      );
    }

    Future<void> stopRecording() async {
      await _speechService.stop();
      await _transcriptSub?.cancel();
      notifyListeners();
    }
  }
  ```

  > **Important:** The exact name and type of the audio stream on `DevicesService` must be confirmed by reading `app/lib/services/devices.dart` before this step. The property may be `audioStream`, `bleAudioStream`, `pcmStream`, or similar. Adjust the reference accordingly.

- [ ] **Step 5: Run test to verify it passes**

  ```bash
  flutter test test/providers/capture_provider_test.dart
  ```

  Expected: PASS.

- [ ] **Step 6: Inject SpeechService via factory in main.dart**

  `SpeechServiceFactory.create()` is async (returns `Future<SpeechService>`), so it must be awaited before `runApp`. Use one of these patterns:

  ```dart
  // Option A: await before runApp (simplest)
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    final speechService = await SpeechServiceFactory.create(
      onVoskDownloadProgress: (p) =>
          debugPrint('VOSK download: ${(p * 100).toInt()}%'),
    );
    runApp(
      Provider<SpeechService>.value(
        value: speechService,
        child: const MyApp(),
      ),
    );
  }

  // Option B: if using Provider package, use FutureProvider (shows loading UI)
  FutureProvider<SpeechService?>(
    create: (_) => SpeechServiceFactory.create(),
    initialData: null,
    child: ...,
  )
  ```

  Option A is recommended for simplicity. If VOSK model download is needed, show a splash/loading screen before `runApp` while the factory resolves.

  > **Execution order matters:** Always call `PermissionHelper.requestAll()` (Task 10) **before** `SpeechServiceFactory.create()`. The factory calls `native.initialize()` which may trigger an OS permission dialog — if permissions haven't been requested yet, this creates a duplicate or out-of-order prompt. The correct sequence in `main.dart` is:
  > 1. `WidgetsFlutterBinding.ensureInitialized()`
  > 2. `await PermissionHelper.requestAll()`
  > 3. `await SpeechServiceFactory.create(...)`
  > 4. `runApp(...)`

- [ ] **Step 7: Commit**

  ```bash
  git add -A
  git commit -m "feat: wire SpeechService into capture provider, remove cloud STT"
  ```

---

## Task 10: Configure Permissions

**Files:**
- Modify: `app/ios/Runner/Info.plist`
- Modify: `app/android/app/src/main/AndroidManifest.xml`
- Modify: `app/lib/` — permission request logic

- [ ] **Step 1: Update iOS Info.plist**

  Open `app/ios/Runner/Info.plist`. Ensure these keys are present:
  ```xml
  <key>NSMicrophoneUsageDescription</key>
  <string>Konuşmaları kaydetmek için mikrofon erişimi gereklidir.</string>

  <key>NSSpeechRecognitionUsageDescription</key>
  <string>Konuşmaları metne dönüştürmek için konuşma tanıma erişimi gereklidir.</string>

  <key>NSBluetoothAlwaysUsageDescription</key>
  <string>Omi cihazına bağlanmak için Bluetooth erişimi gereklidir.</string>
  ```

  Remove any existing keys for Firebase, push notifications, calendar, or contacts.

- [ ] **Step 2: Update Android AndroidManifest.xml**

  Open `app/android/app/src/main/AndroidManifest.xml`. Ensure:
  ```xml
  <!-- Microphone -->
  <uses-permission android:name="android.permission.RECORD_AUDIO" />

  <!-- Bluetooth — API 31+ -->
  <uses-permission android:name="android.permission.BLUETOOTH_SCAN"
      android:usesPermissionFlags="neverForLocation" />
  <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

  <!-- Bluetooth — API 30 and below -->
  <uses-permission android:name="android.permission.BLUETOOTH"
      android:maxSdkVersion="30" />
  <uses-permission android:name="android.permission.BLUETOOTH_ADMIN"
      android:maxSdkVersion="30" />
  ```

  Remove permissions for push notifications (if `RECEIVE_BOOT_COMPLETED`, `VIBRATE` etc. are only for notifications), calendar, contacts, internet (if no network calls remain), and Firebase services.

- [ ] **Step 3: Write test for permission request flow**

  Create `app/test/utils/permission_helper_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:permission_handler/permission_handler.dart';
  import 'package:mockito/annotations.dart';
  import 'package:mockito/mockito.dart';
  import 'package:your_app/utils/permission_helper.dart';

  @GenerateMocks([Permission])
  import 'permission_helper_test.mocks.dart';

  void main() {
    test('requestRequiredPermissions requests microphone and bluetooth', () async {
      // This is an integration concern — we just verify the helper
      // calls the right permissions. Full test requires a real device.
      expect(PermissionHelper.requiredPermissions, contains(Permission.microphone));
      expect(PermissionHelper.requiredPermissions, contains(Permission.bluetoothConnect));
    });
  }
  ```

- [ ] **Step 4: Create PermissionHelper**

  Create `app/lib/utils/permission_helper.dart`:
  ```dart
  import 'dart:io';
  import 'package:permission_handler/permission_handler.dart';

  class PermissionHelper {
    static List<Permission> get requiredPermissions => [
          Permission.microphone,
          if (Platform.isAndroid) ...[
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
          ],
          if (Platform.isIOS) Permission.speech,
        ];

    /// Request all required permissions.
    /// Returns true if all granted.
    static Future<bool> requestAll() async {
      final statuses = await requiredPermissions.request();
      return statuses.values.every((s) => s.isGranted);
    }
  }
  ```

- [ ] **Step 5: Call PermissionHelper.requestAll() on app start**

  In `main.dart` or the onboarding flow, before the recording screen is accessible:
  ```dart
  final granted = await PermissionHelper.requestAll();
  if (!granted) {
    // Show a dialog explaining why permissions are required
  }
  ```

- [ ] **Step 6: Run test**

  ```bash
  flutter test test/utils/permission_helper_test.dart
  ```

  Expected: PASS.

- [ ] **Step 7: Commit**

  ```bash
  git add -A
  git commit -m "feat: configure iOS/Android permissions, add PermissionHelper"
  ```

---

## Task 11: Simplify Settings Screen

**Files:**
- Modify: `app/lib/pages/settings/` (delete cloud/plugin sections, add storage prefs)
- Create: `app/lib/utils/storage_preferences.dart`

- [ ] **Step 1: Remove cloud settings sections**

  In the settings page, delete any sections for:
  - Account / sign in
  - Plugins / integrations
  - Notification settings
  - Webhook configuration
  - Speech profile

  Keep:
  - App version info
  - Storage preferences section (added in Steps 6–7 below)
  - Storage usage indicator (added in Steps 6–7 below)

- [ ] **Step 2: Write test for storage preferences**

  Create `app/test/utils/storage_preferences_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:your_app/utils/storage_preferences.dart';

  void main() {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saveAudio defaults to false', () async {
      final prefs = await StoragePreferences.load();
      expect(prefs.saveAudio, false);
    });

    test('can persist saveAudio = true', () async {
      await StoragePreferences.setSaveAudio(true);
      final prefs = await StoragePreferences.load();
      expect(prefs.saveAudio, true);
    });
  }
  ```

- [ ] **Step 3: Run test to verify it fails**

  ```bash
  flutter test test/utils/storage_preferences_test.dart
  ```

  Expected: FAIL.

- [ ] **Step 4: Implement StoragePreferences**

  Create `app/lib/utils/storage_preferences.dart`:
  ```dart
  import 'package:shared_preferences/shared_preferences.dart';

  const _keySaveAudio = 'save_audio';

  class StoragePreferences {
    final bool saveAudio;
    const StoragePreferences({required this.saveAudio});

    static Future<StoragePreferences> load() async {
      final prefs = await SharedPreferences.getInstance();
      return StoragePreferences(
        saveAudio: prefs.getBool(_keySaveAudio) ?? false,
      );
    }

    static Future<void> setSaveAudio(bool value) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySaveAudio, value);
    }
  }
  ```

- [ ] **Step 5: Run test to verify it passes**

  ```bash
  flutter test test/utils/storage_preferences_test.dart
  ```

  Expected: PASS.

- [ ] **Step 6: Add storage pref toggle to settings UI**

  In the settings page widget. The toggle is disabled (greyed out) in this iteration since audio file saving is not yet implemented — it will be enabled when audio buffering is added in a future task:
  ```dart
  SwitchListTile(
    title: const Text('Ses dosyasını kaydet'),
    subtitle: const Text('Yakında — şu an yalnızca transkript kaydedilir'),
    value: false,
    onChanged: null, // disabled until audio buffering is implemented
  ),
  ```

- [ ] **Step 7: Add storage usage indicator**

  In the settings page, show total space used by audio files:
  ```dart
  FutureBuilder<int>(
    future: _calculateAudioDirSize(),
    builder: (context, snapshot) {
      final mb = ((snapshot.data ?? 0) / 1024 / 1024).toStringAsFixed(1);
      return ListTile(
        title: const Text('Depolama kullanımı'),
        subtitle: Text('$mb MB (ses dosyaları)'),
        trailing: TextButton(
          onPressed: _clearAudioFiles,
          child: const Text('Temizle'),
        ),
      );
    },
  ),
  ```

- [ ] **Step 8: Commit**

  ```bash
  git add -A
  git commit -m "feat: simplify settings screen, add storage preferences and usage indicator"
  ```

---

## Task 12: BLE Disconnect Recovery During Recording

**Files:**
- Modify: `app/lib/providers/` (capture provider)
- Modify: `app/lib/services/devices.dart` (BLE connection state stream)

The spec requires: when BLE disconnects mid-recording → pause recording, suspend silence timer, notify user, resume on reconnect.

- [ ] **Step 1: Write failing test**

  Add to `app/test/providers/capture_provider_test.dart`:
  ```dart
  test('pauses recording on BLE disconnect and resumes on reconnect', () async {
    final mockSpeech = MockSpeechService();
    final mockDb = MockAppDatabase();
    final mockDevices = MockDevicesService();
    final transcriptController = StreamController<String>();
    final connectionController = StreamController<bool>(); // true=connected

    when(mockSpeech.initialize()).thenAnswer((_) async {});
    when(mockSpeech.transcribe(any)).thenAnswer((_) => transcriptController.stream);
    when(mockSpeech.stop()).thenAnswer((_) async {});
    when(mockDevices.connectionStateStream).thenAnswer((_) => connectionController.stream);

    final provider = CaptureProvider(
      speechService: mockSpeech,
      database: mockDb,
      devicesService: mockDevices,
    );

    await provider.startRecording();
    expect(provider.isRecording, true);
    expect(provider.isPaused, false);

    // Simulate BLE disconnect
    connectionController.add(false);
    await Future.delayed(Duration.zero);
    expect(provider.isPaused, true);
    verify(mockSpeech.stop()).called(1);

    // Simulate BLE reconnect
    connectionController.add(true);
    await Future.delayed(Duration.zero);
    expect(provider.isPaused, false);
    verify(mockSpeech.initialize()).called(2); // initialized again on resume
  });
  ```

- [ ] **Step 2: Run test to verify it fails**

  ```bash
  flutter test test/providers/capture_provider_test.dart
  ```

  Expected: FAIL — `isPaused`, `connectionStateStream` not found.

- [ ] **Step 3: Confirm DevicesService exposes a connection state stream**

  Open `app/lib/services/devices.dart` and find the connection state stream. It likely looks like:
  ```dart
  Stream<bool> get connectionStateStream => ...; // true = connected
  // or
  Stream<DeviceConnectionState> get connectionStream => ...;
  ```

  If it emits `DeviceConnectionState` enum values, adapt the listener below accordingly.

- [ ] **Step 4: Add BLE disconnect handling to CaptureProvider**

  Add to `CaptureProvider`:
  ```dart
  bool isRecording = false;
  bool isPaused = false;
  Timer? _silenceTimer;
  StreamSubscription<bool>? _connectionSub;

  Future<void> startRecording() async {
    // ... existing init code ...
    isRecording = true;
    isPaused = false;
    _startSilenceTimer();

    // Listen for BLE connection state changes
    _connectionSub = _devicesService.connectionStateStream.listen(
      (connected) async {
        if (!isRecording) return;
        if (!connected && !isPaused) {
          await _pauseRecording();
        } else if (connected && isPaused) {
          await _resumeRecording();
        }
      },
    );
  }

  Future<void> _pauseRecording() async {
    isPaused = true;
    _silenceTimer?.cancel(); // suspend silence timer
    await _speechService.stop();
    await _transcriptSub?.cancel();
    notifyListeners(); // triggers UI notification banner
  }

  Future<void> _resumeRecording() async {
    isPaused = false;
    await _speechService.initialize();
    final bleAudioStream = _devicesService.audioStream
        .map((frames) => Uint8List.fromList(frames));
    _transcriptSub = _speechService.transcribe(bleAudioStream).listen(
      (segment) {
        currentTranscript = currentTranscript.isEmpty
            ? segment
            : '$currentTranscript $segment';
        notifyListeners();
      },
    );
    _startSilenceTimer(); // restart silence countdown from zero
    notifyListeners();
  }

  void _startSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 60), () async {
      if (isRecording && !isPaused) {
        await stopRecording();
      }
    });
  }

  // In stopRecording(), add:
  // _connectionSub?.cancel();
  // _silenceTimer?.cancel();
  ```

- [ ] **Step 5: Run test to verify it passes**

  ```bash
  flutter test test/providers/capture_provider_test.dart
  ```

  Expected: PASS.

- [ ] **Step 6: Update UI to show disconnect notification**

  In the recording screen widget, listen to `provider.isPaused` and show a banner:
  ```dart
  if (provider.isPaused)
    Container(
      color: Colors.orange,
      padding: const EdgeInsets.all(8),
      child: const Text(
        'Cihaz bağlantısı kesildi. Yeniden bağlanılıyor...',
        textAlign: TextAlign.center,
      ),
    ),
  ```

- [ ] **Step 7: Commit**

  ```bash
  git add -A
  git commit -m "feat: handle BLE disconnect/resume during recording with silence timer"
  ```

---

## Task 13: Connect Conversation Storage to Recording Flow

**Files:**
- Modify: `app/lib/providers/` (capture/conversation provider)

This task ensures that when a recording stops, the `Conversation` row is inserted into drift with all required fields.

- [ ] **Step 1: Write failing test**

  Add to `app/test/providers/capture_provider_test.dart`:
  ```dart
  test('stopRecording saves conversation to database', () async {
    final mockSpeech = MockSpeechService();
    final mockDb = MockAppDatabase();
    final controller = StreamController<String>();

    when(mockSpeech.initialize()).thenAnswer((_) async {});
    when(mockSpeech.transcribe(any)).thenAnswer((_) => controller.stream);
    when(mockSpeech.stop()).thenAnswer((_) async {});
    when(mockDb.into(any)).thenReturn(MockInsertStatement());

    final provider = CaptureProvider(speechService: mockSpeech, database: mockDb);
    await provider.startRecording();
    controller.add('Test transkript');
    await Future.delayed(Duration.zero);

    await provider.stopRecording();

    verify(mockDb.into(mockDb.conversations).insert(any)).called(1);
  });
  ```

- [ ] **Step 2: Run test to verify it fails**

  ```bash
  flutter test test/providers/capture_provider_test.dart
  ```

- [ ] **Step 3: Implement stopRecording with DB insert**

  In `CaptureProvider.stopRecording()`:
  ```dart
  Future<void> stopRecording() async {
    final endTime = DateTime.now();
    await _speechService.stop();
    await _transcriptSub?.cancel();

    final prefs = await StoragePreferences.load();
    // Audio file saving is out of scope for this iteration.
    // When "save audio" is enabled (prefs.saveAudio == true),
    // raw PCM frames from the BLE stream would need to be buffered
    // during recording and written to an AAC/M4A file here.
    // For now, audio_path is always null.
    const String? audioPath = null;

    await _database.into(_database.conversations).insert(
      ConversationsCompanion.insert(
        id: const Uuid().v4(),
        startedAt: _recordingStartTime!,
        endedAt: endTime,
        durationSeconds:
            endTime.difference(_recordingStartTime!).inSeconds,
        transcript: currentTranscript,
        locale: 'tr_TR',
        audioPath: Value(audioPath),
      ),
    );

    currentTranscript = '';
    notifyListeners();
  }
  ```

- [ ] **Step 4: Run test to verify it passes**

  ```bash
  flutter test test/providers/capture_provider_test.dart
  ```

  Expected: PASS.

- [ ] **Step 5: Commit**

  ```bash
  git add -A
  git commit -m "feat: persist conversation to SQLite on recording stop"
  ```

---

## Task 14: Final Integration Test on Device

This is a manual test — automated device/BLE testing is not in scope.

- [ ] **Step 1: Run all unit tests**

  ```bash
  flutter test
  ```

  Expected: all tests pass.

- [ ] **Step 2: Build and install on iOS device**

  ```bash
  flutter run --release
  ```

  Verify:
  - App launches without crash
  - Permission prompts appear for microphone, speech recognition, and Bluetooth
  - All permissions can be granted

- [ ] **Step 3: Test Devkit 2 BLE pairing**

  - Open the device pairing screen
  - Power on Devkit 2
  - Verify device appears in scan results
  - Pair and confirm connection indicator shows "connected"

- [ ] **Step 4: Test recording and transcription**

  - Tap "Başlat" on the main screen
  - Speak Turkish sentences: "Merhaba, bu bir test kaydıdır."
  - Verify transcript text appears on screen in real time (finalized segments)
  - Tap "Durdur"
  - Verify conversation is saved and appears in the conversations list

- [ ] **Step 5: Test conversation history**

  - Open conversations list
  - Verify recorded conversation shows correct date, duration, and title preview
  - Open conversation detail — verify full transcript is displayed

- [ ] **Step 6: Test BLE disconnect recovery**

  - Start a recording
  - Turn off Devkit 2 mid-recording
  - Verify app shows disconnect notification and pauses recording
  - Turn on Devkit 2
  - Verify recording resumes

- [ ] **Step 7: Test silence auto-end**

  - Start a recording
  - Stay silent for 60 seconds
  - Verify conversation is automatically saved and ends

- [ ] **Step 8: Final commit**

  ```bash
  git add -A
  git commit -m "chore: final cleanup after integration testing"
  ```

---

## Notes for Implementers

- **Package names in import paths:** Replace `your_app` with the actual package name from `pubspec.yaml` (`name:` field).
- **Omi's existing BLE code:** `lib/services/devices.dart` and `lib/services/devices/` are kept as-is. Do not modify them unless they directly import deleted files.
- **Mockito code generation:** Run `dart run build_runner build` whenever you add a `@GenerateMocks` annotation.
- **VOSK model download:** The first run on Android devices without native offline Turkish STT will trigger a ~50 MB download. Ensure network is available for the first use. Subsequent runs use the cached model.
- **shared_preferences package:** Task 11 uses `SharedPreferences`. Confirm it is already in `pubspec.yaml` (Omi likely includes it); if not, add `shared_preferences: ^2.3.0` and run `flutter pub get`.
- **iOS online fallback:** If `SFSpeechRecognizer` falls back to online mode (when the offline Turkish model is absent), audio is sent to Apple's servers. **Before releasing, add a privacy policy disclosure:** "Bu uygulama konuşma tanıma için cihazınızdaki Türkçe dil modeli kullanır. Model mevcut değilse ses verisi Apple sunucularına gönderilebilir." Include this in the App Store privacy nutrition labels under "Data Used to Track You → Audio Data".
