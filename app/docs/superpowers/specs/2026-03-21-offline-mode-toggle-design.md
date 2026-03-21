# Offline Mod Toggle — Tasarım Dokümanı

**Tarih:** 2026-03-21
**Platform:** Flutter (iOS)
**Bağımlılık:** Backend yok — BLE → Native iOS STT → SQLite

---

## 1. Genel Bakış

Mevcut Omi Flutter uygulamasına "Offline Mod" toggle'ı eklenir. Toggle açıkken:
- Backend WebSocket bağlantısı kurulmaz
- Devkit 2'den gelen BLE sesi doğrudan native iOS `SFSpeechRecognizer`'a beslenir
- Transkripsiyon sonuçları yerel SQLite'a kaydedilir

Toggle kapalıyken mevcut akış hiç değişmez.

---

## 2. Mimari

### Yaklaşım: Provider Swap

Offline flag `SharedPreferences`'a yazılır. Uygulama başlarken flag okunur; `true` ise `LocalCaptureProvider` aktif edilir, backend'e bağlanılmaz. `CaptureProvider` ve mevcut akış dokunulmaz.

### Veri Akışı (offline mod açıkken)

```
Devkit 2 (BLE)
  → Opus decode → PCM16 Uint8List chunks
  → MethodChannel "omi/ble_stt" sendBuffer(bytes)
  → Swift: AVAudioPCMBuffer → SFSpeechAudioBufferRecognitionRequest.append()
  → EventChannel "omi/ble_stt/results" onTranscript(text)
  → BleAudioSpeechServiceIos.transcribe() stream
  → LocalCaptureProvider.currentTranscript
  → UI gösterimi
  → stopRecording() → SQLite (AppDatabase)
```

### Kısıt Notu

`speech_to_text` Flutter paketi yalnızca mikrofon yolunu sarıyor; `SFSpeechAudioBufferRecognitionRequest` API'sini açmıyor. Bu nedenle paketi bypass eden özel bir native plugin (`BleAudioSttPlugin.swift`) yazılır. iOS natively bu API'yi destekliyor; kısıt paketteydi, OS'ta değil.

---

## 3. Bileşenler

### 3.1 `SharedPreferencesUtil` — flag eklenir

```dart
// lib/backend/preferences.dart
bool get offlineModeEnabled => getBool('offlineModeEnabled') ?? false;
set offlineModeEnabled(bool v) => setBool('offlineModeEnabled', v);
```

### 3.2 `BleAudioSpeechServiceIos` — yeni sınıf

**Dosya:** `lib/services/speech/ble_audio_speech_service_ios.dart`

`SpeechService` interface'ini implement eder. BLE'den gelen `Stream<Uint8List>` chunk'larını `MethodChannel` üzerinden Swift'e iletir. Swift'ten gelen transkript sonuçlarını `EventChannel` üzerinden stream olarak döndürür.

### 3.3 `BleAudioSttPlugin.swift` — native iOS plugin

**Dosya:** `ios/Runner/BleAudioSttPlugin.swift`

- `MethodChannel("omi/ble_stt")`: `sendBuffer(bytes)` → `SFSpeechAudioBufferRecognitionRequest.append()`
- `EventChannel("omi/ble_stt/results")`: finalize edilmiş transkript segmentlerini Flutter'a gönderir
- `SFSpeechRecognizer(locale: Locale("tr", "TR"))` ile başlatılır
- Türkçe offline model cihazda yoksa online fallback yapar (privacy policy'de belirtilmeli)

### 3.4 `SpeechServiceFactory` — güncellenir

```dart
// lib/services/speech/speech_service_factory.dart
static Future<SpeechService> create() async {
  final offlineMode = SharedPreferencesUtil().offlineModeEnabled;
  if (Platform.isIOS) {
    return offlineMode
        ? BleAudioSpeechServiceIos()
        : PlatformSpeechServiceIos();  // mevcut, mikrofon tabanlı
  }
  // Android: mevcut akış değişmez
  ...
}
```

### 3.5 `LocalCaptureProvider` — `main.dart`'a inject edilir

```dart
// lib/main.dart — MultiProvider listesine eklenir
ChangeNotifierProvider(
  create: (_) => LocalCaptureProvider(
    speechService: await SpeechServiceFactory.create(),
    database: AppDatabase.instance,
  ),
),
```

`LocalCaptureProvider` koduna dokunulmaz; zaten `Stream<Uint8List>` alıp `SpeechService`'e veren doğru tasarımda.

### 3.6 `TranscriptionSettingsPage` — toggle eklenir

**Dosya:** `lib/pages/settings/transcription_settings_page.dart`

Sayfanın en üstüne offline mod toggle'ı eklenir:

- Toggle açılınca: `SharedPreferencesUtil().offlineModeEnabled = true`, mevcut WebSocket bağlantısı kapatılır
- Toggle kapanınca: `false`, normal akış devam eder
- Toggle açıkken altındaki tüm provider seçim alanları `IgnorePointer` + `Opacity(0.4)` ile devre dışı bırakılır
- Açıklama metni: `"Offline modda transkripsiyon Apple Konuşma Tanıma ile yapılır. Kayıtlar yalnızca bu cihazda saklanır."`

### 3.7 `developer.dart` — STT chip güncellenir

`_buildSttChip()` metodu offline mod açıkken `"Apple STT"` gösterir:

```dart
Widget _buildSttChip() {
  if (SharedPreferencesUtil().offlineModeEnabled) {
    return _chip('Apple STT');
  }
  // mevcut mantık...
}
```

### 3.8 Kayıt ekranı — `LocalCaptureProvider`'ı dinler

**Dosya:** `lib/pages/conversation_capturing/page.dart`

- `context.watch<LocalCaptureProvider>()` eklenir
- `offlineModeEnabled` flag'i okunur
- Offline modda:
  - `LocalCaptureProvider.startRecording(audioStream: bleStream)` çağrılır
  - `LocalCaptureProvider.currentTranscript` gösterilir
  - `LocalCaptureProvider.stopRecording()` → SQLite'a kaydeder
  - Ekranın üstünde chip: `"📴 Offline · Apple STT"`
- Normal modda: mevcut akış değişmez

---

## 4. Etkilenmeyen Bileşenler

- `CaptureProvider` — hiç değişmez
- `ConversationProvider` — hiç değişmez
- Mevcut SQLite şeması (`AppDatabase`) — yeterli, değişmez
- Android akışı — değişmez

---

## 5. Hata Durumları

| Durum | Davranış |
|-------|----------|
| BLE bağlantısı yok, offline mod açık | Kayıt başlatılamaz, kullanıcıya "Devkit 2 bağlı değil" mesajı |
| `SFSpeechRecognizer` izni yok | `SpeechServiceException` fırlatılır, kullanıcıya izin istenir |
| Türkçe offline model yüklü değil | SFSpeechRecognizer online fallback yapar (privacy note) |
| SQLite yazma hatası | `stopRecording()` hata loglar, kullanıcıya bildirim gösterir |

---

## 6. Dosya Değişiklik Özeti

| Dosya | Değişim |
|-------|---------|
| `lib/backend/preferences.dart` | `offlineModeEnabled` getter/setter eklenir |
| `lib/services/speech/ble_audio_speech_service_ios.dart` | **Yeni** |
| `ios/Runner/BleAudioSttPlugin.swift` | **Yeni** |
| `lib/services/speech/speech_service_factory.dart` | Offline mod dalı eklenir |
| `lib/main.dart` | `LocalCaptureProvider` inject edilir |
| `lib/pages/settings/transcription_settings_page.dart` | Toggle eklenir |
| `lib/pages/settings/developer.dart` | `_buildSttChip()` güncellenir |
| `lib/pages/conversation_capturing/page.dart` | Offline mod dalı eklenir |

---

## 7. Test Kriterleri

- Toggle açılıp kapatılınca `SharedPreferences` değeri doğru yazılıyor
- Offline modda WebSocket bağlantısı kurulmaya çalışılmıyor
- BLE'den gelen ses Swift plugin'e ulaşıyor, transkript Flutter'a dönüyor
- `stopRecording()` sonrası SQLite'ta yeni kayıt var
- Provider seçim alanları toggle açıkken tıklanamıyor
- `_buildSttChip()` offline modda `"Apple STT"` gösteriyor
