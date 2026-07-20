# H4-H10 Sprint Tasarım Spesifikasyonu
**Tarih:** 2026-06-20  
**Proje:** Kur'an'da ki Mesaj — Flutter (iOS/Android)  
**Kapsam:** 7 yeni özellik, 4 haftalık sprint

---

## Genel Mimari

### Prensipler
- Yeni servis sınıfları `lib/data/services.dart`'a eklenir (mevcut `PrayerTracker`/`ReadingGoalService` örüntüsü)
- Riverpod provider'lar `lib/data/repositories.dart`'ta tanımlanır
- H6+H7 aynı `NotificationService` altyapısını paylaşır
- H8+H10 Drift DB üzerinde çalışır (mevcut 13 tablo genişletilir)
- H9 dışındaki tüm özellikler tamamen yerel (SharedPrefs + Drift) — Supabase gerektirmez

### Yeni Paket
```yaml
flutter_tts: ^4.2.0   # H4 sesli tefsir için
```

### Yeni Rotalar
```
/quiz          → SurahQuizScreen    (H5)
/progress      → ProgressScreen     (H8)
/profile/:id   → UserProfileScreen  (H9, parametreli)
```

### Klasör Yapısı (değişen dosyalar)
```
lib/
├── data/
│   ├── services.dart          ← TtsService, NotificationService, StatsService eklenir
│   └── repositories.dart      ← yeni provider'lar
├── features/
│   ├── quran/                 ← H4 (sesli buton) + H10 (favori sure)
│   ├── learning/              ← H5 (SurahQuizScreen)
│   ├── dua/                   ← H6 (hatırlatıcı ayarları)
│   ├── holy_days/             ← H7 (takvim bildirimleri)
│   ├── progress/              ← H8 (ProgressScreen — yeni dosya)
│   └── community/             ← H9 (UserProfileScreen)
└── app/router.dart            ← /quiz, /progress, /profile/:id eklenir
pubspec.yaml                   ← flutter_tts eklenir
```

---

## Hafta 1 — H4 + H5

### H4: Sesli Tefsir

**Amaç:** Kullanıcı ayet mealini dinleyebilmeli (eller serbest, görme engeli desteği).

**`TtsService`** (`lib/data/services.dart`):
```dart
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;

  Future<void> init() async {
    await _tts.setLanguage('tr-TR');
    await _tts.setSpeechRate(0.85);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() => _speaking = false);
  }

  Future<void> speak(String text) async {
    if (_speaking) await stop();
    _speaking = true;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    _speaking = false;
    await _tts.stop();
  }

  bool get isSpeaking => _speaking;
}
```

**Provider:**
```dart
final ttsServiceProvider = Provider<TtsService>((ref) {
  final svc = TtsService();
  svc.init();
  ref.onDispose(svc.stop);
  return svc;
});
```

**UI entegrasyonu:**
- `QuranScreen` → her ayetin yanında `IconButton(Icons.volume_up_rounded)`
- `DailyAyahScreen` → meal metninin altında "Sesli Dinle" butonu
- Butona basınca `ttsService.speak(mealText)`, ikinci basışta `stop()`
- İkon durumu: `volume_up` (sessiz) / `stop_circle` (oynatılıyor)

**Hız ayarı:** `DuaScreen` veya Ayarlar'da `Slider(min: 0.5, max: 1.5)` — `ttsService.setRate(v)`

---

### H5: Sure Bilgisi Quiz

**Amaç:** Kullanıcı sure isimleri, ayet sayıları ve nüzul bilgisini test edebilmeli.

**`SurahQuizScreen`** (`lib/features/learning/learning_screens.dart`'a eklenir):

Soru havuzu `Surahs` Drift tablosundan türetilir (114 sure, mevcut seed):
```dart
// Soru tipleri
enum QuizType { nameToMeaning, surahToAyahCount, surahToReveal, orderToName }
```

**Akış:**
1. `SurahQuizScreen` açılır — "Başla" butonu
2. 10 soru, her soru: 1 doğru + 3 rastgele yanlış şık
3. Seçim anında renk feedback (yeşil/kırmızı), "İleri" butonu
4. Son ekran: `X/10 doğru`, yanlış cevaplanan soruların özeti

**Rota:** `/quiz` — `FeaturesCatalogScreen`'den ve `LearningScreen`'den erişilebilir

**Skor kaydı:** SharedPrefs'e `quiz_high_score` (en yüksek skor)

---

## Hafta 2 — H6 + H7

### H6: Dua Hatırlatıcısı

**Amaç:** Kullanıcı sabah/akşam duaları için günlük bildirim alabilmeli.

**`NotificationService`** (`lib/data/services.dart`):
```dart
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<void> scheduleDailyDua({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOf(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails('dua_channel', 'Dua Hatırlatıcısı'),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // her gün tekrar
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelAll() => _plugin.cancelAll();
}
```

**UI — `DuaScreen`'e "Hatırlatıcı" bölümü eklenir:**
- Sabah saati: `ListTile` → `TimePicker` dialog → saat kaydedilir
- Akşam saati: aynı şekilde
- Toggle: bildirim açık/kapalı
- Kaydedilen saatler SharedPrefs'e: `dua_morning_h`, `dua_morning_m`, `dua_evening_h`, `dua_evening_m`

**Bildirim içeriği:** `kDuaList`'ten rastgele kısa dua (ilk 5-10 sabah/akşam duası)

---

### H7: İslami Takvim Bildirimleri

**Amaç:** Kandil ve bayramlarda kullanıcıya bildirim gitsin.

**Sabit liste** (`lib/data/seed/seed_data.dart`'a eklenir):
> ⚠️ Aşağıdaki tarihler tahminidir — uygulama yayına girmeden önce Diyanet İşleri Başkanlığı'nın resmi takvimiyle doğrulanmalıdır.

```dart
const kIslamicDays2026 = [
  (name: 'Regaib Kandili', date: DateTime(2026, 1, 29)),
  (name: 'Miraç Kandili', date: DateTime(2026, 3, 19)),
  (name: 'Berat Kandili', date: DateTime(2026, 4, 2)),
  (name: 'Ramazan Başlangıcı', date: DateTime(2026, 2, 18)), // tahmini
  (name: 'Kadir Gecesi', date: DateTime(2026, 3, 14)),       // tahmini
  (name: 'Ramazan Bayramı', date: DateTime(2026, 3, 20)),    // tahmini
  (name: 'Arefe', date: DateTime(2026, 6, 5)),
  (name: 'Kurban Bayramı', date: DateTime(2026, 6, 6)),
  (name: 'Mevlid-i Nebi', date: DateTime(2026, 9, 13)),
];
```

**`HolyDaysScreen`'e "Tümü için Bildirim Al" toggle eklenir:**
- Açıksa: kalan tüm günler için 1 gün önce (saat 20:00) + gün sabahı (08:00) bildirim planlanır
- `NotificationService.scheduleExact()` — H6'daki aynı servis kullanılır
- ID aralığı: 100-200 (dua bildirimleri 1-10, çakışma önlenir)

---

## Hafta 3 — H8 + H10

### H8: Kur'an İstatistikleri

**Amaç:** Kullanıcı ne kadar okuduğunu görebilmeli.

**Yeni Drift tablosu:**
```dart
class ReadingEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get surahId => integer()();
  IntColumn get ayahCount => integer()();
  IntColumn get durationSeconds => integer()();
  DateTimeColumn get readAt => dateTime()();
}
```

**`StatsService`** (`lib/data/services.dart`):
```dart
Future<void> recordReading(int surahId, int ayahCount, int durationSec) async {
  await db.into(db.readingEvents).insert(
    ReadingEventsCompanion.insert(
      surahId: surahId, ayahCount: ayahCount,
      durationSeconds: durationSec, readAt: DateTime.now(),
    ),
  );
}

Future<Map<String, int>> getLifetimeStats() async {
  // toplam sure, ayet, dakika
}

Future<List<int>> getWeeklyAyahCounts() async {
  // son 7 güne göre ayet sayısı listesi [Pzt, Sal, ...]
}
```

**`ProgressScreen`** (`lib/features/progress/progress_screen.dart` — yeni dosya):
- Kart 1: Toplam sure / ayet / dakika (ömür boyu)
- Kart 2: Haftalık çubuk grafik — 7 sütun, `CustomPaint` (bağımlılıksız)
- Kart 3: En çok okunan 3 sure
- Kart 4: Mevcut streak (`ReadingGoalService.getStreak()`)

**QuranScreen entegrasyonu:** Sure okuma başlayınca `Stopwatch` başlar; `dispose()` metodunda veya `WillPopScope`/`PopScope` callback'inde `StatsService.recordReading()` çağrılır (en az 10 saniye okuma şartı — çok kısa geçişler kaydedilmez).

---

### H10: Offline Favori Sure

**Amaç:** Kullanıcı favori surelerini kolayca bulabilmeli (teknik olarak tüm sureler zaten offline).

**Yeni Drift tablosu:**
```dart
class FavoriteSurahs extends Table {
  IntColumn get surahId => integer()();
  DateTimeColumn get savedAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {surahId};
}
```

**UI — `QuranScreen` sure listesinde:**
- Her sure satırına yıldız `IconButton` eklenir
- Sarı yıldız = favori, gri = değil → toggle ile DB güncellenir
- Liste başında "Favorilerim" filtresi: `SegmentedButton` (Tümü / Favoriler)
- Favori sureler ayrıca `SurahListTile` ile gösterilir

---

## Hafta 4 — H9: Kullanıcı Profil Sayfası

**Amaç:** Kullanıcı profilini görüntüleyebilmeli, başkalarını takip edebilmeli.

### Supabase Şema Değişikliği
```sql
CREATE TABLE follows (
  follower_id  uuid REFERENCES auth.users NOT NULL,
  following_id uuid REFERENCES auth.users NOT NULL,
  created_at   timestamptz DEFAULT now(),
  PRIMARY KEY (follower_id, following_id)
);

-- RLS
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Herkes okuyabilir" ON follows FOR SELECT USING (true);
CREATE POLICY "Kendi takibini yönetir" ON follows
  FOR ALL USING (auth.uid() = follower_id);
```

### `UserProfileScreen` (`lib/features/community/community_screens.dart`'a eklenir)

**Parametreler:** `userId` (String) — `/profile` rotasında oturumdaki kullanıcının ID'si, `/profile/:id` rotasında parametre olarak gelen ID

**Bölümler:**
1. **Header:** Avatar (CircleAvatar, baş harf fallback) + display_name + düzenle butonu (kendi profilinde)
2. **İstatistik satırı:** `[Takipçi N] · [Takip N] · [Gönderi N]`
3. **Takip butonu:** Başka profil açıkken — "Takip Et" / "Takibi Bırak" (Supabase follows tablosu)
4. **Gönderi grid'i:** `feed_posts WHERE user_id = userId` — `GridView.builder`, 3 sütun, thumbnail

**Provider:**
```dart
final userProfileProvider = FutureProvider.family<Map<String, dynamic>?, String>(
  (ref, userId) => ref.watch(profileRepositoryProvider).getUserProfile(userId),
);

final userPostsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) => ref.watch(cloudPostsRepositoryProvider).getPostsByUser(userId),
);
```

**Rota:** `/profile` (kendi profili) + `/profile/:id` (başka kullanıcı)

---

## Hata Yönetimi

| Senaryo | Davranış |
|---------|---------|
| TTS dil desteklenmiyor | `SnackBar('Cihazınızda Türkçe TTS desteklenmiyor')` |
| Bildirim izni reddedildi | `AlertDialog` → Ayarlar'a yönlendirme |
| Supabase bağlantısı yok (H9) | Profil yüklenemedi hatası, yenile butonu |
| Quiz sorusu türetilemedi | Minimum 4 sure gerekli — Drift seed'den geldiği için bu senaryo imkânsız |

---

## Test Kontrol Listesi

- [ ] TTS Türkçe sesi cihazda çalışıyor
- [ ] Quiz 10 soru, her soru 4 şık, tekrar yok
- [ ] Dua bildirimi her gün aynı saatte geliyor
- [ ] İslami takvim bildirimleri geçmiş günler için planlanmıyor
- [ ] İstatistik ekranı boş durumda crash vermiyor
- [ ] Favori sure toggle DB'ye yazılıyor, uygulama yeniden açılınca korunuyor
- [ ] Profil sayfası giriş yapılmamışken "Giriş Yap" CTA gösteriyor
- [ ] `dart analyze lib/` → No issues found

---

## Uygulama Sırası

```
1. pubspec.yaml: flutter_tts ekle
2. Drift şeması: ReadingEvents + FavoriteSurahs tabloları (schemaVersion 3)
3. H4: TtsService + QuranScreen/DailyAyahScreen butonları
4. H5: SurahQuizScreen + /quiz rotası
5. H6: NotificationService + DuaScreen hatırlatıcı UI
6. H7: kIslamicDays2026 + HolyDaysScreen toggle
7. H8: StatsService + ProgressScreen + QuranScreen kayıt
8. H10: FavoriteSurahs + QuranScreen yıldız UI
9. H9: follows Supabase tablosu + UserProfileScreen + /profile/:id rotası
10. dart analyze + flutter test
```
