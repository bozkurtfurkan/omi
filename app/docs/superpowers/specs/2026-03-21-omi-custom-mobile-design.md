# Omi Özelleştirilmiş Mobil Uygulama — Tasarım Dokümanı

**Tarih:** 2026-03-21
**Proje:** [BasedHardware/omi](https://github.com/BasedHardware/omi) fork'u
**Platform:** Flutter (iOS + Android)
**Bağımlılık:** Backend yok — tamamen on-device

---

## 1. Genel Bakış

Omi'nin açık kaynaklı Flutter mobil uygulamasının sadeleştirilmiş bir fork'u. Yalnızca üç temel özelliği barındırır:

1. Devkit 2 cihazıyla BLE bağlantısı ve ses akışı alma
2. Gerçek zamanlı Türkçe transkripsiyon (on-device)
3. Konuşma geçmişi ve yerel depolama

Tüm işlem cihaz üzerinde gerçekleşir; backend API, Firebase sync veya cloud STT servisi kullanılmaz.

---

## 2. Mimari

### Tutulanlar (Omi'den)
- Devkit 2 BLE bağlantı ve audio stream kodu
- Opus ses decode pipeline
- Konuşma geçmişi UI ekranları
- Local SQLite depolama altyapısı (`drift` paketi ile)

### Çıkarılanlar (Omi'den)
- Tüm backend API çağrıları (FastAPI, Firebase Firestore sync)
- Plugin ve webhook sistemi
- AI özetleme ve aksiyon öğesi çıkarma
- AI persona ekranları
- Cloud STT entegrasyonları (Deepgram, Speechmatics, Soniox)
- Pinecone, Redis bağımlılıkları

### Eklenenler
- `SpeechService` soyutlama katmanı (on-device STT, Whisper'a geçişe hazır)

---

## 3. Ekranlar

| Ekran | Açıklama |
|---|---|
| Ana Ekran | Kayıt durumu, BLE bağlantı göstergesi, başlat/durdur; hata durumları (BLE koptu, STT başlatılamadı, depolama dolu) |
| Konuşmalar Listesi | Tüm kayıtlı konuşmalar, tarih ve süre bilgisi |
| Konuşma Detayı | Tam transkript metni |
| Cihaz Bağlantısı | Devkit 2 BLE tarama ve eşleştirme |
| Ayarlar | Depolama tercihleri (ses dosyası sakla / sadece transkript), depolama kullanım göstergesi |

**Konuşma başlama/bitiş semantiği:**
- Kullanıcı "başlat" düğmesine bastığında konuşma başlar.
- Kullanıcı "durdur" düğmesine bastığında konuşma biter ve kaydedilir.
- BLE bağlantısı koptuğunda kayıt otomatik duraklar ve kullanıcıya bildirim gösterilir; bağlantı yeniden kurulduğunda devam eder.
- 60 saniyelik sessizlik sonrası konuşma otomatik biter (yapılandırılabilir).

---

## 4. Veri Akışı

```
Devkit 2 (BLE)
    → Opus audio stream (BLE Notification, MTU 512 byte, Service UUID: Omi'nin mevcut kodu)
    → Flutter audio pipeline (Opus decode)
    → SpeechService
    → Transkript segmentleri (yalnızca finalize edilmiş)
    → Local SQLite
```

---

## 5. Veritabanı Şeması

```
Conversation
  - id               : UUID
  - started_at       : DateTime
  - ended_at         : DateTime
  - duration_seconds : int          (ended_at - started_at, listelerde kullanılır)
  - title            : String?      (kullanıcı düzenleyebilir; null ise ilk 60 karakter gösterilir)
  - transcript       : String       (tam transkript metni)
  - audio_path       : String?      (isteğe bağlı, uygulama documents dizininde AAC/M4A formatında saklanır)
  - locale           : String       (şimdilik "tr_TR", ileride genişletilebilir)
```

**Depolama tercihleri:**
- Varsayılan: yalnızca transkript (ses dosyası kaydedilmez).
- "Ses dosyasını sakla" açıksa ham ses uygulama documents dizinine yazılır.
- Kullanıcı tercihi "yalnızca transkript"e geri döndürdüğünde eski ses dosyaları silinmez; manuel temizleme ayarlar ekranından yapılır.

---

## 6. SpeechService Soyutlama Katmanı

```dart
/// Her event, finalize edilmiş bir transkript segmentidir.
/// Partial/interim sonuçlar emit edilmez.
/// Konuşma sona erdiğinde stream kapanır.
abstract class SpeechService {
  Stream<String> transcribe(Stream<Uint8List> audioStream);
}
```

**Platform implementasyonları:**

| Platform | Implementasyon | Durum |
|---|---|---|
| iOS 17+ | `SFSpeechRecognizer` (`tr_TR`, offline model önceden indirilmişse on-device, aksi halde online fallback — **gizlilik politikasında belirtilmeli**) | Başlangıç |
| Android 12+ (API 31+) | `SpeechRecognizer.createOnDeviceRecognitionIntent` — Türkçe dil paketi cihazda yüklü olmalı (kullanıcı ayarlardan indirir); yoksa hata gösterilir | Başlangıç |
| Android genel | `VoskSpeechService` (vosk-model-tr, ~50 MB, tamamen offline) — Android 11 ve altı ya da dil paketi yoksa otomatik fallback. Model ilk çalıştırmada indirilir; indirme progress UI gösterilir. İndirme başarısız olursa kullanıcıya hata mesajı verilir ve kayıt engellenir. | Fallback |
| Tüm platformlar | `WhisperSpeechService` — ileride eklenebilir | Gelecek |

**iOS uyarısı:** `SFSpeechRecognizer` ile offline Türkçe model garantili değildir; model cihazda yoksa online moduna düşer. Uygulama gizlilik politikası bu durumu açıkça belirtmelidir.

---

## 7. İzinler

### iOS (`Info.plist`)
```
NSMicrophoneUsageDescription
NSSpeechRecognitionUsageDescription
NSBluetoothAlwaysUsageDescription
```
- `SFSpeechRecognizer.requestAuthorization()` uygulama ilk açılışında çağrılır.

### Android (`AndroidManifest.xml`)
```
RECORD_AUDIO
BLUETOOTH_SCAN          (API 31+)
BLUETOOTH_CONNECT       (API 31+)
BLUETOOTH               (API 30 ve altı)
BLUETOOTH_ADMIN         (API 30 ve altı)
```
- Runtime permission: `RECORD_AUDIO` kayıt başlatılmadan önce istenir.
- Minimum SDK: **Android 10 (API 29)**. Android 12+ önerilen (native on-device STT için API 31).

### iOS Minimum Deployment Target
- **iOS 17** — iOS 17+ ile offline Türkçe model erişilebilirliği iOS 16'ya göre belirgin şekilde daha iyi; `SpeechTranscriber` (iOS 26+) kapsam dışı.

---

## 8. Teknik Riskler

| Risk | Azaltma |
|---|---|
| iOS offline Türkçe model cihazda yok → online fallback | Gizlilik politikasında belirt; `SpeechService` soyutlaması Whisper'a geçişi mekanik hale getirir |
| Android native offline Türkçe güvenilmez | VoskSpeechService otomatik fallback; dil paketi yoksa kullanıcıya yönlendirme gösterilir |
| STT kalitesi genel olarak yetersizse | Whisper tiny/small entegrasyonu — `SpeechService` arayüzü değişmez |
| BLE bağlantısı kayıt ortasında koparsa | Kayıt duraklar, sessizlik zamanlayıcısı da askıya alınır, kısmi transkript kaydedilir, kullanıcıya bildirim; bağlantı yeniden kurulduğunda kayıt devam eder |
| Devkit 2 BLE protokol değişiklikleri | Omi upstream'i takip et |
