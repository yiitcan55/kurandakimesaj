# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Proje Özeti

**Kur'an'da ki Mesaj** — Kur'an okuma/anlama, günlük ibadet, öğrenme ve **ayetlerden paylaşılabilir içerik üreten bir stüdyo + topluluk akışını** tek bir mobil deneyimde birleştiren Flutter (iOS/Android) uygulaması. Ürünün çekirdek farklılaştırıcısı "**Anla → Düşün → Paylaş**" döngüsüdür.

**Durum (2026-07-25, sürüm 1.0.1+3):** Aşağıdaki mimari **uygulanmış durumda** — 44 Dart dosyası, Riverpod + go_router + drift, Supabase backend (13 migration, 8 Edge Function). Bu bölüm bir hedef değil, mevcut yapının tarifidir.

> Bir dönem bu dosyada "proje varsayılan Flutter boilerplate'inde (counter demo)" yazıyordu; bu ifade uzun süredir bayattı ve yeni kod yazarken yanıltıcıydı. Atıf verdiği `Uygulama Planı.html` de silinmiş durumda.

**İçerik sistemi (K1/K2 kararları, sürüm 1.0.1):** Tek içerik sistemi vardır — **Reels**. `feed_posts.kind` yalnız iki değer alır: `'video'` (kullanıcının mp4'ü) ve `'still'` (stüdyo üretimi PNG). **Gerçek video render hattı kapsam dışıdır** (ffmpeg_kit emekli); stüdyo çıktısı `still` reel olarak yayınlanır. Kullanıcıya "video üretiyoruz" vaadi verilmez.

**Moderasyon (Apple Guideline 1.2 yanıtı):** Her içerik `status='pending'` başlar ve yayına girmeden önce yönetici onayından geçer. Kapı UI'da değil **veritabanında** zorlanır: RLS + `feed_posts_moderation_guard` trigger'ı. Bu mekanizmayı zayıflatan hiçbir değişiklik yapılmamalıdır — App Store onayı buna bağlıdır. Ayrıntı: `docs/APP_REVIEW_RESPONSE.md`.

`PROJECT_MEMORY.md` projenin canlı "beyni"dir — mimari karar verirken veya görev tamamlarken oku ve güncelle.

## Komutlar

```bash
flutter pub get                      # bağımlılıkları kur
flutter run                          # bağlı cihaz/emülatörde çalıştır
flutter analyze                      # statik analiz (flutter_lints kuralları)
flutter test                         # tüm testler
flutter test test/widget_test.dart   # tek bir test dosyası
flutter build apk / ios              # release build

# Kod üretimi (drift/freezed — şema veya model değiştiğinde)
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch          # geliştirme sırasında sürekli üretim

# Edge Function testleri (Deno)
deno test --allow-read --allow-net supabase/functions/ayah-finder/link_resolver.test.ts
deno test --allow-read supabase/functions/_shared/quran/matcher.test.ts
deno test --allow-read supabase/functions/ayah-finder-audio/segments.test.ts
```

Dart SDK kısıtı: `^3.12.2` (pubspec.yaml).
Yerel kalıcılık **drift** ile (`lib/data/local/app_database.dart`) — planda geçen `isar` kullanılmıyor.

## Mimari

**Feature-first katmanlı mimari.** Durum yönetimi **Riverpod**, yönlendirme **go_router** (alt-sekmeler için `StatefulShellRoute`). Her özellik kendi klasöründe `data / domain / presentation` katmanlarıyla.

- **Sunum:** `ConsumerWidget` ekranlar; durum `StateNotifier`/`AsyncNotifier` içinde. **UI saf tutulur, tüm mantık notifier'da** — `setState`'ten kaçın.
- **Kalıcılık:** `shared_preferences` (ayar/sayaç) + `drift` (koleksiyon, ezber, çevrimdışı sure metni).
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

Kullanılan paketler (`pubspec.yaml`): `flutter_riverpod`, `go_router`, `freezed`/`json_serializable`, `dio`, `drift`, `adhan` (namaz vakti), `geolocator`/`flutter_qiblah`/`flutter_compass` (kıble), `hijri`, `just_audio`, `flutter_local_notifications`, `video_player`, `share_plus`, `google_fonts`, `flutter_svg`, `flutter_animate`, `supabase_flutter`, `google_sign_in`, `sign_in_with_apple`, `image_picker`, `receive_sharing_intent`.

`ffmpeg_kit_flutter` **kullanılmıyor** (paket emekli) — bu yüzden gerçek video render kapsam dışıdır (K1).

## Modüller

**26 özellik**, 4 modül — tek kaynak `lib/app/feature_catalog.dart`, sayı ihtilafında **kod kazanır**:
**İbadet & Günlük (8)** namaz vakti, zikirmatik, tesbihat, dua, Esmaü'l-Hüsna, oruç/imsakiye, dini günler, kıble ·
**Kur'an & Öğrenme (10)** okuma, günlük ayet, konuya göre ayet, mucizeler, sure ezberi, cüz/hizb takip, kıssalar, tecvid, sure quiz, istatistikler ·
**İçerik & Topluluk (4)** ayet kartı stüdyosu, hatim halkaları, koleksiyonlar, Ayet Bul (AI) ·
**Araçlar (4)** zekât hesaplama, cami bul, bağış, rüya tabiri.

> Reels akışı ve Mesajlar katalog kaydı değil, alt-sekmedir — bu yüzden 26'ya dahil değiller.

Önerilen lansman sırası: Faz 1 Temel (onboarding, okuma, namaz vakti, zikir, günün ayeti) → Faz 2 Stüdyo (video edit, AI, akış) → Faz 3 Öğrenme & Topluluk → Faz 4 Araçlar & Gelir.

## Tasarım Sistemi

Zümrüt & altın paleti, sıcak krem metin, karanlık temalar. Fontlar: **Cormorant Garamond** (başlık/serif), **DM Sans** (gövde/arayüz), **Amiri Quran** (Arapça hat). Köşe yarıçapları 12/18/28; ≥44px dokunma hedefi; tabular rakamlar.

## Domain Kuralları (asla çiğneme)

1. **Dini içerik doğruluğu kritiktir.** Meal/tefsir onaylı kaynaklardan (Diyanet, Elmalılı, TDV); hadiste sıhhat derecesi gösterilir. Rüya Tabiri ve Zekât ekranlarında "kesin hüküm değildir" uyarısı bulunmalı.
2. **Arapça metin** her zaman doğru yönde (RTL, `Directionality`) ve Amiri Quran fontuyla render edilmeli.
3. **Tüm kullanıcıya dönük metinler Türkçe ve tam ortografik doğrulukta** (ç, ğ, ı, ö, ş, ü). ASCII karşılıklarına asla düşürme.
4. API key/gizli bilgi koda gömülmez — güvenli storage kullan.
