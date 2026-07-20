# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Proje Özeti

**Kur'an'da ki Mesaj** — Kur'an okuma/anlama, günlük ibadet, öğrenme ve **ayetlerden paylaşılabilir kısa video üreten bir manevi içerik stüdyosu + topluluk akışını** tek bir mobil deneyimde birleştiren Flutter (iOS/Android) uygulaması. Ürünün çekirdek farklılaştırıcısı "**Anla → Düşün → Paylaş**" döngüsüdür: ayet → meal/tefsir → ruh haline göre içerik → video üretip toplulukla paylaşma.

**Önemli:** Proje şu anda **varsayılan Flutter boilerplate'inde** (`lib/main.dart` counter demo). Aşağıdaki mimari ve paket seti, kapsamlı bir tasarım+teknik planın (bkz. `Uygulama Planı.html` ve `Flutter Planı.html`) **henüz uygulanmamış hedef durumudur**. Yeni kod yazarken bu hedef yapıya göre ilerle.

`PROJECT_MEMORY.md` projenin canlı "beyni"dir — mimari karar verirken veya görev tamamlarken oku ve güncelle.

## Komutlar

```bash
flutter pub get                      # bağımlılıkları kur
flutter run                          # bağlı cihaz/emülatörde çalıştır
flutter analyze                      # statik analiz (flutter_lints kuralları)
flutter test                         # tüm testler
flutter test test/widget_test.dart   # tek bir test dosyası
flutter build apk / ios              # release build

# Kod üretimi (freezed, json_serializable, isar_generator hedef stack'te kullanılır)
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch          # geliştirme sırasında sürekli üretim
```

Dart SDK kısıtı: `^3.12.2` (pubspec.yaml).

## Hedef Mimari (plandan)

**Feature-first katmanlı mimari.** Durum yönetimi **Riverpod**, yönlendirme **go_router** (alt-sekmeler için `StatefulShellRoute`). Her özellik kendi klasöründe `data / domain / presentation` katmanlarıyla.

- **Sunum:** `ConsumerWidget` ekranlar; durum `StateNotifier`/`AsyncNotifier` içinde. **UI saf tutulur, tüm mantık notifier'da** — `setState`'ten kaçın.
- **Kalıcılık:** `shared_preferences` (ayar/sayaç) + `isar` (koleksiyon, ezber, çevrimdışı sure metni).
- **Çevrimdışı öncelikli:** Kur'an metni ve mealler uygulamayla paketlenip Isar'a seed edilir; dinamik içerik (namaz vakti, kampanya, akış) API'den (`dio`) beslenir.

Hedef klasör yapısı:
```
lib/
├── main.dart          # ProviderScope + KuranApp
├── app/               # app.dart (MaterialApp.router) + router.dart
├── core/
│   ├── theme/         # app_colors, app_typography, app_theme (Material 3)
│   ├── widgets/       # AppHeader, AppCard, GoldChip, HeroCard, AyetFrame...
│   └── utils/         # formatlama, hicri, mesafe
├── features/<özellik>/  # her biri data/domain/presentation
└── l10n/              # tr.arb (Türkçe metinler)
```

Hedef paket seti (henüz `pubspec.yaml`'da yok): `flutter_riverpod`, `go_router`, `freezed`/`json_serializable`, `dio`, `isar`, `adhan` (namaz vakti), `geolocator`/`flutter_qiblah`/`flutter_compass` (kıble), `hijri`, `just_audio`, `flutter_local_notifications`, `video_player`/`ffmpeg_kit_flutter` (ayet→video render), `share_plus`, `google_fonts`, `flutter_svg`, `flutter_animate`.

## Modüller

24 özellik, 4 modül: **İbadet & Günlük** (namaz vakti, zikirmatik, tesbihat, dua, Esmaü'l-Hüsna, oruç/imsakiye, dini günler, kıble) · **Kur'an & Öğrenme** (okuma, günlük ayet, konuya göre ayet, mucizeler, sure ezberi, cüz/hizb takip, kıssalar, tecvid) · **İçerik & Topluluk** (Video Edit+Meal, AI asistan, akış, hatim halkaları, koleksiyonlar) · **Araçlar** (zekât hesaplama, cami bul, bağış, rüya tabiri).

Önerilen lansman sırası: Faz 1 Temel (onboarding, okuma, namaz vakti, zikir, günün ayeti) → Faz 2 Stüdyo (video edit, AI, akış) → Faz 3 Öğrenme & Topluluk → Faz 4 Araçlar & Gelir.

## Tasarım Sistemi

Zümrüt & altın paleti, sıcak krem metin, karanlık temalar. Fontlar: **Cormorant Garamond** (başlık/serif), **DM Sans** (gövde/arayüz), **Amiri Quran** (Arapça hat). Köşe yarıçapları 12/18/28; ≥44px dokunma hedefi; tabular rakamlar.

## Domain Kuralları (asla çiğneme)

1. **Dini içerik doğruluğu kritiktir.** Meal/tefsir onaylı kaynaklardan (Diyanet, Elmalılı, TDV); hadiste sıhhat derecesi gösterilir. Rüya Tabiri ve Zekât ekranlarında "kesin hüküm değildir" uyarısı bulunmalı.
2. **Arapça metin** her zaman doğru yönde (RTL, `Directionality`) ve Amiri Quran fontuyla render edilmeli.
3. **Tüm kullanıcıya dönük metinler Türkçe ve tam ortografik doğrulukta** (ç, ğ, ı, ö, ş, ü). ASCII karşılıklarına asla düşürme.
4. API key/gizli bilgi koda gömülmez — güvenli storage kullan.
