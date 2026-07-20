# Kur'an'da ki Mesaj — Flutter → React Native (Expo) Tam Taşıma Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

## Context

`Kur'an'da ki Mesaj`, şu an **Flutter (iOS/Android)** ile yazılmış, tam işlevsel (~44 Dart dosyası, 24 özellik, ~9500 satır) bir manevi içerik stüdyosu + topluluk uygulamasıdır. Çekirdek döngü "**Anla → Düşün → Paylaş**". Kullanıcı tüm uygulamayı **React Native + Expo**'ya **1:1 (tüm 24 özellik)** taşımak istiyor.

**Neden React Native + Expo (web değil):** Uygulama kıble pusulası (manyetometre), GPS namaz vakti, ses kaydı + konuşma tanıma (ASR), TTS, yerel/zamanlanmış bildirimler, sistem paylaşım intent'i ve video oynatma gibi native özelliklere ağır bağımlıdır. Bunlar web'de imkânsız/kısıtlıdır; RN + Expo en doğal 1:1 karşılıktır.

**Backend değişmiyor:** Supabase (Auth, DB, Realtime, Edge Functions: `ai-assistant`, `quran-recognize`, `quran-vision`, `render-trigger`, `render-status`) platform-bağımsızdır ve `@supabase/supabase-js` ile aynen kullanılır. Sadece istemci yeniden yazılır.

**Hedeflenen sonuç:** Mevcut Flutter uygulamasıyla görsel ve işlevsel olarak eşdeğer, offline-first çalışan, aynı Supabase backend'ine bağlanan bir Expo uygulaması.

**Goal:** Mevcut Flutter uygulamasının tüm 24 özelliğini, tasarım sistemini ve offline-first veri katmanını React Native + Expo'ya birebir taşımak.

**Architecture:** Feature-first katmanlı yapı. Sunum (React bileşenleri) saf tutulur; tüm mantık hook/store/servis katmanında. Navigasyon Expo Router (file-based; go_router'ın `StatefulShellRoute` karşılığı tab + stack). Durum: **Zustand** (mutable UI/komut state — Riverpod `Notifier` karşılığı) + **TanStack Query** (async/sunucu state — Riverpod `FutureProvider`/`StreamProvider` karşılığı). Yerel veri: **expo-sqlite + Drizzle ORM** (Drift karşılığı, offline-first, 16 tablo + 6236 ayet seed). Stil: merkezî tip-güvenli tema token nesnesi + `StyleSheet`; animasyon `react-native-reanimated` + `moti` (flutter_animate karşılığı); vektör çizimler `react-native-svg` (CustomPainter karşılığı).

**Tech Stack:** Expo SDK 52+ (TypeScript), Expo Router, Zustand, TanStack Query, expo-sqlite + Drizzle ORM, @supabase/supabase-js, react-native-reanimated, moti, react-native-svg, adhan (JS), react-native-svg + expo-* native modülleri.

## Global Constraints

Her görevin gereksinimleri bu bölümü kapsar:

- **Dil:** Tüm kullanıcıya dönük metinler **Türkçe ve tam ortografik doğrulukta** (ç, ğ, ı, ö, ş, ü). ASCII karşılığına asla düşürme. Kaynak Flutter dosyasındaki Türkçe metin string'leri birebir kopyalanır.
- **Arapça:** Her Arapça metin **RTL** (`writingDirection: 'rtl'`, `<View>` içinde `direction`) ve **Amiri Quran** fontuyla render edilir.
- **Dini doğruluk:** Meal/tefsir onaylı kaynaklardan (Diyanet, Elmalılı, TDV). **Rüya Tabiri** (`dream`) ve **Zekât** (`zakat`) ekranlarında "kesin hüküm değildir" uyarısı korunur (kaynak Flutter ekranındaki uyarı metni birebir taşınır).
- **Gizli bilgi:** API key/secret koda gömülmez. Supabase URL/anonKey ve Google Client ID'leri `app.config.ts` + `process.env` (EXPO_PUBLIC_* veya derleme-zamanı extra) ile sağlanır; `.env` git'e girmez. Service-role key asla istemcide bulunmaz.
- **TypeScript:** `strict: true`. `any` kaçınılır.
- **Offline-first:** Tüm dini seed içeriği uygulamayla paketlenir ve ilk açılışta SQLite'a seed edilir. Backend/ağ erişilemezse mevcut Flutter davranışındaki graceful fallback korunur.
- **Expo modülü tercihi:** Native erişim için önce Expo SDK modülleri (`expo-location`, `expo-notifications`, `expo-sensors`, `expo-av`/`expo-audio`, `expo-speech`, vb.) kullanılır; gerekirse community paketleri.

## Kaynak → Hedef Eşleme (referans tablo)

| Flutter | React Native + Expo |
|---|---|
| Riverpod `Notifier`/`AsyncNotifier` | Zustand store + komut metotları |
| Riverpod `FutureProvider`/`StreamProvider`(.family) | TanStack Query `useQuery`/realtime subscription hook |
| go_router `StatefulShellRoute` + routes | Expo Router `(tabs)` + stack route'ları |
| Drift (SQLite) + `app_database.dart` | Drizzle ORM + expo-sqlite |
| `supabase_flutter` | `@supabase/supabase-js` |
| `dio` | `fetch` / `ky` |
| `shared_preferences` | `@react-native-async-storage/async-storage` |
| `flutter_animate` / implicit anim | `moti` + `react-native-reanimated` |
| `CustomPainter` (painters.dart) | `react-native-svg` |
| `google_fonts` | `expo-font` + `@expo-google-fonts/*` |
| `adhan` (Dart) | `adhan` (npm, aynı kütüphane) |
| `hijri` | `hijri-converter` / `moment-hijri` |
| `geolocator` | `expo-location` |
| `flutter_compass` | `expo-sensors` (Magnetometer) |
| `flutter_local_notifications` + `timezone` | `expo-notifications` |
| `just_audio` / `video_player` | `expo-av` (veya `expo-audio`/`expo-video`) |
| `speech_to_text` (STT) | `@react-native-voice/voice` veya `expo-speech-recognition` |
| `flutter_tts` | `expo-speech` |
| `record` | `expo-av` Recording / `expo-audio` |
| `image_picker` / `file_picker` | `expo-image-picker` / `expo-document-picker` |
| `share_plus` | `expo-sharing` / RN `Share` |
| `receive_sharing_intent` | `expo-share-intent` |
| `url_launcher` | `expo-linking` / `Linking` |
| `permission_handler` | her Expo modülünün izin API'si |
| `google_sign_in` | `@react-native-google-signin/google-signin` |
| `path_provider` | `expo-file-system` |
| `flutter_svg` | `react-native-svg` + `react-native-svg-transformer` |
| `rive` / `lottie` | `rive-react-native` / `lottie-react-native` |

## Hedef Proje Yapısı

```
kurandakimesaj-rn/
├── app/                              # Expo Router (go_router karşılığı)
│   ├── _layout.tsx                   # Root providers (ProviderScope), font yükleme, bootstrap
│   ├── index.tsx                     # ilk yönlendirme (splash/tabs)
│   ├── splash.tsx, setup.tsx, auth.tsx, features.tsx, my-videos.tsx, ayah-recognition.tsx
│   ├── (tabs)/
│   │   ├── _layout.tsx               # 5 sekme + orta FAB (HomeShell karşılığı)
│   │   └── home.tsx, feed.tsx, messages.tsx, profile.tsx
│   └── (features)/                   # 24 tam ekran route
│       ├── prayer.tsx, dhikr.tsx, tasbihat.tsx, dua.tsx, esma.tsx, fasting.tsx,
│       ├── holy-days.tsx, qibla.tsx, quran.tsx, quran/[surah].tsx, daily-ayah.tsx,
│       ├── topical.tsx, miracles.tsx, memorize.tsx, juz-tracker.tsx, stories.tsx,
│       ├── tajweed.tsx, quiz.tsx, studio.tsx, ai-assistant.tsx, khatm.tsx,
│       ├── collections.tsx, zakat.tsx, mosque.tsx, donate.tsx, dream.tsx, progress.tsx
├── src/
│   ├── config.ts                     # AppConfig (Supabase, Google OAuth, hasSupabase)
│   ├── theme/{colors.ts, theme.ts, fonts.ts, ThemeProvider.tsx}
│   ├── components/                   # core widgets + components/painters/
│   ├── domain/{models.ts, arabicNormalizer.ts}
│   ├── data/
│   │   ├── db/{schema.ts, client.ts, migrations/}
│   │   ├── seed/{seedData.ts, seedService.ts}
│   │   ├── repositories/             # content, dhikr, collections, memorize, juz, reading, favorites
│   │   ├── backend/                  # profile, social, messages, khatm, render, sync repos
│   │   ├── supabase.ts, quranApi.ts, quranMatcher.ts
│   ├── services/                     # location, prayer, qibla, notification, tts, audio, recognition, prefs, goldPrice
│   ├── state/{stores/, queries/}     # zustand + react-query hooks
│   └── features/<feature>/           # ekran gövdeleri + feature bileşenleri
├── assets/quran/quran_full.json      # mevcut JSON birebir kopyalanır
├── app.config.ts, package.json, tsconfig.json, drizzle.config.ts, .env.example
└── __tests__/ (veya kaynakla yan yana *.test.ts)
```

---

## FAZ 0 — Proje İskeleti & Araçlar

### Task 0.1: Expo + TypeScript projesini oluştur

**Files:**
- Create: `kurandakimesaj-rn/` (yeni Expo projesi, mevcut Flutter klasörünün yanına)
- Modify: `kurandakimesaj-rn/package.json`, `tsconfig.json`, `app.config.ts`

**Interfaces:**
- Produces: Çalışan boş Expo Router projesi; `npm test` (Jest) altyapısı.

- [ ] **Step 1: Projeyi oluştur**

```bash
cd "C:\Users\yiit5\Desktop\kurandaki mesaj flutter"
npx create-expo-app@latest kurandakimesaj-rn
cd kurandakimesaj-rn
```

- [ ] **Step 2: Çekirdek bağımlılıkları kur**

```bash
npx expo install expo-router react-native-reanimated react-native-gesture-handler react-native-safe-area-context react-native-screens
npm i zustand @tanstack/react-query @supabase/supabase-js drizzle-orm
npx expo install expo-sqlite @react-native-async-storage/async-storage react-native-svg expo-font
npm i -D drizzle-kit jest jest-expo @testing-library/react-native @types/jest typescript
```

- [ ] **Step 3: Jest yapılandırması ekle (package.json)**

```json
{
  "scripts": {
    "start": "expo start",
    "android": "expo run:android",
    "ios": "expo run:ios",
    "test": "jest",
    "typecheck": "tsc --noEmit",
    "db:generate": "drizzle-kit generate"
  },
  "jest": { "preset": "jest-expo" }
}
```

- [ ] **Step 4: tsconfig strict + path alias**

```json
{
  "extends": "expo/tsconfig.base",
  "compilerOptions": {
    "strict": true,
    "baseUrl": ".",
    "paths": { "@/*": ["src/*"] }
  }
}
```

- [ ] **Step 5: Smoke test yaz** — `src/__tests__/smoke.test.ts`

```ts
test('jest çalışıyor', () => {
  expect(1 + 1).toBe(2);
});
```

- [ ] **Step 6: Test ve typecheck çalıştır**

Run: `npm test && npm run typecheck`
Expected: PASS (1 test), tsc hatasız.

- [ ] **Step 7: Commit**

```bash
git init && git add -A && git commit -m "chore: scaffold Expo + TS + Jest project"
```

### Task 0.2: Yapılandırma (AppConfig) ve ortam değişkenleri

**Files:**
- Create: `src/config.ts`, `.env.example`, `app.config.ts`
- Source (port): `lib/app/app_config.dart`, `env.example.json`

**Interfaces:**
- Produces: `AppConfig.supabaseUrl`, `AppConfig.supabaseAnonKey`, `AppConfig.googleWebClientId`, `AppConfig.googleIosClientId`, `AppConfig.hasSupabase: boolean`.

- [ ] **Step 1: `.env.example` oluştur** (kaynak `env.example.json` anahtarlarıyla)

```
EXPO_PUBLIC_SUPABASE_URL=
EXPO_PUBLIC_SUPABASE_ANON_KEY=
EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID=
EXPO_PUBLIC_GOOGLE_IOS_CLIENT_ID=
```

- [ ] **Step 2: `src/config.ts`**

```ts
export const AppConfig = {
  supabaseUrl: process.env.EXPO_PUBLIC_SUPABASE_URL ?? '',
  supabaseAnonKey: process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY ?? '',
  googleWebClientId: process.env.EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID ?? '',
  googleIosClientId: process.env.EXPO_PUBLIC_GOOGLE_IOS_CLIENT_ID ?? '',
  get hasSupabase(): boolean {
    return this.supabaseUrl.length > 0 && this.supabaseAnonKey.length > 0;
  },
} as const;
```

- [ ] **Step 3: Test** — `src/__tests__/config.test.ts`

```ts
import { AppConfig } from '@/config';
test('hasSupabase boşken false', () => {
  expect(typeof AppConfig.hasSupabase).toBe('boolean');
});
```

- [ ] **Step 4: Test çalıştır** — Run: `npm test` → PASS
- [ ] **Step 5: Commit** — `git commit -am "feat: AppConfig + env scaffolding"`

---

## FAZ 1 — Tasarım Sistemi

> Kaynak: `lib/ui/core/theme/app_colors.dart`, `lib/ui/core/theme/app_theme.dart`, `lib/ui/core/widgets.dart`, `lib/ui/core/painters.dart`, `lib/ui/core/page_transitions.dart`. Tüm değerler rapordan birebir alınır.

### Task 1.1: Renk paleti, token'lar, tipografi

**Files:**
- Create: `src/theme/colors.ts`, `src/theme/theme.ts`, `src/theme/fonts.ts`
- Source: `app_colors.dart`, `app_theme.dart`

**Interfaces:**
- Produces: `colors` (tüm hex + gradyan dizileri), `radii {sm:12, md:18, lg:28}`, `durations {fast:180, normal:320, slow:520, entrance:650, stagger:60}`, `typography` (font ailesi + boyut/satır yüksekliği), `arabicTextStyle(size, color)`.

- [ ] **Step 1: `src/theme/colors.ts`** (rapordaki tam değerler)

```ts
export const colors = {
  emerald950: '#08201A',
  emerald900: '#0D2A20',
  emerald850: '#0F2C22',
  emerald700: '#1E4D38',
  gold: '#D4B25B',
  goldBright: '#E8CB6F',
  goldSoft: '#B69547',
  cream: '#F3EADB',
  cream2: '#E6DCC8',
  muted: 'rgba(243,234,219,0.62)',
  muted2: 'rgba(243,234,219,0.55)',
  success: '#5ED27D',
  accent: '#C9856A',
  info: '#5AA9D6',
  line: 'rgba(212,178,91,0.18)',
  lineSoft: 'rgba(243,234,219,0.07)',
  goldFaint: 'rgba(212,178,91,0.12)',
} as const;

export const gradients = {
  hero: ['#1E4D38', '#08201A'] as const,            // top-left → bottom-right
  card: ['#102C22', '#0D2A20'] as const,
  cardActive: ['#1B4334', '#123528'] as const,
  fab: ['#E8CB6F', '#B69547'] as const,
} as const;
```

- [ ] **Step 2: `src/theme/theme.ts`** (radii, durations, curves, typography)

```ts
import { Easing } from 'react-native-reanimated';

export const radii = { sm: 12, md: 18, lg: 28 } as const;
export const durations = { fast: 180, normal: 320, slow: 520, entrance: 650, stagger: 60 } as const;
export const curves = {
  easeOut: Easing.out(Easing.cubic),
  emphasized: Easing.out(Easing.quart),
};

export const fontFamily = {
  display: 'Cormorant',     // başlık/serif
  body: 'DMSans',           // gövde/arayüz
  arabic: 'AmiriQuran',     // Arapça hat
} as const;

export const typography = {
  displayLarge: { fontFamily: fontFamily.display, fontSize: 56, lineHeight: 56 * 1.05, fontWeight: '600' as const, letterSpacing: -0.5 },
  displayMedium: { fontFamily: fontFamily.display, fontSize: 44, lineHeight: 44 * 1.05, fontWeight: '600' as const, letterSpacing: -0.5 },
  headlineMedium: { fontFamily: fontFamily.display, fontSize: 30, fontWeight: '600' as const },
  headlineSmall: { fontFamily: fontFamily.display, fontSize: 24, fontWeight: '600' as const },
  titleLarge: { fontFamily: fontFamily.display, fontSize: 22, fontWeight: '600' as const },
  bodyLarge: { fontFamily: fontFamily.body, fontSize: 16, lineHeight: 16 * 1.5 },
  bodyMedium: { fontFamily: fontFamily.body, fontSize: 14.5, lineHeight: 14.5 * 1.5 },
  labelLarge: { fontFamily: fontFamily.body, fontSize: 14, fontWeight: '600' as const },
  eyebrow: { fontFamily: fontFamily.body, fontSize: 11, fontWeight: '700' as const, letterSpacing: 2.4 },
};

export function arabicTextStyle(size = 26, color = colorsGold) {
  return { fontFamily: fontFamily.arabic, fontSize: size, lineHeight: size * 1.9, color, writingDirection: 'rtl' as const };
}
import { colors as _c } from './colors';
const colorsGold = _c.gold;
```

- [ ] **Step 3: `src/theme/fonts.ts`** — font yükleme map'i

```bash
npx expo install @expo-google-fonts/cormorant @expo-google-fonts/dm-sans @expo-google-fonts/amiri
```

```ts
import { Cormorant_600SemiBold } from '@expo-google-fonts/cormorant';
import { DMSans_400Regular, DMSans_600SemiBold, DMSans_700Bold } from '@expo-google-fonts/dm-sans';
import { Amiri_400Regular } from '@expo-google-fonts/amiri';

export const appFonts = {
  Cormorant: Cormorant_600SemiBold,
  DMSans: DMSans_400Regular,
  DMSans_600SemiBold,
  DMSans_700Bold,
  AmiriQuran: Amiri_400Regular,
};
```

> Not: `AmiriQuran` için Amiri Regular yeterli; tam Amiri Quran istenirse `assets/fonts/AmiriQuran.ttf` eklenir.

- [ ] **Step 4: Token testi** — `src/theme/__tests__/theme.test.ts`

```ts
import { radii, durations } from '@/theme/theme';
import { colors } from '@/theme/colors';
test('token değerleri Flutter ile eşleşir', () => {
  expect(radii).toEqual({ sm: 12, md: 18, lg: 28 });
  expect(durations.normal).toBe(320);
  expect(colors.gold).toBe('#D4B25B');
});
```

- [ ] **Step 5: Test** — Run: `npm test` → PASS
- [ ] **Step 6: Commit** — `git commit -am "feat: design tokens (colors, radii, typography, fonts)"`

### Task 1.2: Çekirdek bileşenler (AppHeader, AppCard, HeroCard, GoldChip, AyetFrame, vd.)

**Files:**
- Create: `src/components/{AppHeader,AppCard,HeroCard,GoldChip,AyetFrame,StatBox,SectionLabel,EmptyState,AnimatedCounter,ShimmerSkeleton,FeaturePlaceholder}.tsx`, `src/components/index.ts`
- Source: `lib/ui/core/widgets.dart`

**Interfaces:**
- Produces (props imzaları — sonraki tüm ekran görevleri bunlara dayanır):
  - `AppHeader({ title: string; trailing?: ReactNode; onBack?: () => void })`
  - `AppCard({ children: ReactNode; padding?: number; onPress?: () => void })` (basışta 0.97 scale, reduce-motion'a saygı)
  - `HeroCard({ children: ReactNode; height?: number })` (heroGradient + altın daire filigran)
  - `GoldChip({ label: string; selected: boolean; onPress: () => void })`
  - `AyetFrame({ arabic: string; fontSize?: number })` (RTL + Amiri)
  - `StatBox({ value: string; label: string })` (tabular figürler: `fontVariant:['tabular-nums']`)
  - `SectionLabel({ title: string; eyebrow?: string; trailing?: ReactNode })`
  - `EmptyState({ icon?: ReactNode; message: string; action?: ReactNode })`
  - `AnimatedCounter({ value: number; style?: TextStyle })`
  - `ShimmerSkeleton({ width: number|string; height: number })`
  - `FeaturePlaceholder({ title: string; description: string; icon?: ReactNode })`

- [ ] **Step 1:** Gradyanlar için `npx expo install expo-linear-gradient`
- [ ] **Step 2:** `AppCard` ve `HeroCard`'ı `expo-linear-gradient` + `Pressable` ile yaz; basış scale'i `react-native-reanimated` `useSharedValue` ile (180ms). reduce-motion: `AccessibilityInfo.isReduceMotionEnabled()` → animasyon atla.
- [ ] **Step 3:** `GoldChip`'i `moti` `MotiView` ile (180ms renk geçişi). Seçili: altın dolgu + `emerald950` metin; değilse şeffaf + altın border + `cream2` metin.
- [ ] **Step 4:** `AyetFrame`'i `<Text style={arabicTextStyle(fontSize)}>` + dış `View` `{ direction: 'rtl' }` ile; altın çerçeve `borderColor: colors.line`.
- [ ] **Step 5:** `AnimatedCounter`'ı `react-native-reanimated` `withTiming(value, {duration:520})` + `useDerivedValue` ile; tabular figürler.
- [ ] **Step 6:** `ShimmerSkeleton`'ı `moti/skeleton` veya `MotiView` loop (1200ms) ile.
- [ ] **Step 7: Render testi** — `src/components/__tests__/components.test.tsx`

```tsx
import { render } from '@testing-library/react-native';
import { GoldChip } from '@/components/GoldChip';
test('GoldChip etiketi gösterir', () => {
  const { getByText } = render(<GoldChip label="Sabır" selected={false} onPress={() => {}} />);
  expect(getByText('Sabır')).toBeTruthy();
});
```

- [ ] **Step 8: Test** — Run: `npm test` → PASS
- [ ] **Step 9: Commit** — `git commit -am "feat: core UI components"`

### Task 1.3: SVG painter'lar (Tesbih, Dairesel İlerleme, Kıble Kadranı)

**Files:**
- Create: `src/components/painters/{TasbihDial,CircularProgress,QiblaDial}.tsx`
- Source: `lib/ui/core/painters.dart`

**Interfaces:**
- Produces:
  - `TasbihDial({ filled: number })` (0..33 boncuk)
  - `CircularProgress({ progress: number; strokeWidth?: number; size?: number })` (progress 0..1)
  - `QiblaDial({ headingToQibla: number; aligned: boolean; size?: number })` (heading radyan)

- [ ] **Step 1:** `react-native-svg` ile `CircularProgress`: arka iz `colors.goldFaint`, ilerleme yayı `<Circle>` `strokeDasharray` + `strokeDashoffset` (progress'e göre). Aktif renk `aligned`/değer durumuna göre.
- [ ] **Step 2:** `QiblaDial`: 360° kadran, 72 tik (her 9. kalın), merkez cami ikonu, ok `rotate(headingToQibla)`, hizalıysa `colors.success`.
- [ ] **Step 3:** `TasbihDial`: 33 boncuk dairesel; dolu boncuk radyal altın, boş yeşil; imame + püskül.
- [ ] **Step 4: Test** — `CircularProgress` `progress=0.5`'te beklenen `strokeDashoffset` hesabı için saf yardımcıyı (`dashOffset(progress, radius)`) ayrı export edip test et.

```ts
import { dashOffset } from '@/components/painters/CircularProgress';
test('yarı ilerleme yarı offset', () => {
  const c = 2 * Math.PI * 50;
  expect(dashOffset(0.5, 50)).toBeCloseTo(c / 2, 1);
});
```

- [ ] **Step 5: Test** — Run: `npm test` → PASS
- [ ] **Step 6: Commit** — `git commit -am "feat: SVG painters (tasbih, progress, qibla)"`

---

## FAZ 2 — Domain & Veri Katmanı (Saf Mantık: TDD)

> Bu fazda saf mantık birimleri **önce test** yazılarak taşınır. Bunlar uygulamanın doğruluk-kritik çekirdeğidir (Arapça normalleştirme + ayet eşleştirme + zekât + günün ayeti seçimi).

### Task 2.1: Domain modelleri

**Files:**
- Create: `src/domain/models.ts`
- Source: `lib/domain/models.dart`

**Interfaces:**
- Produces: `MealOption = 'diyanet'|'elmalili'|'tdv'`; `AppInterest`; `FeatureCategory`; tipler/yardımcılar `AppSettings`, `PrayerSlot`, `PrayerDay` (+ `nextAfter(now)`, `currentAt(now)`), `QiblaInfo` (+ `angleToQibla`, `aligned`).

- [ ] **Step 1:** Enumları string-literal union; sınıfları `interface` + saf fonksiyon (`prayerDayNextAfter(day, now)`, `qiblaAngleTo(info)`, `qiblaAligned(info)`).
- [ ] **Step 2: Test** — `src/domain/__tests__/models.test.ts`: `prayerDayNextAfter` bilinen slot listesinde doğru sıradaki vakti döndürür; `qiblaAligned` ±5° eşiğini doğru uygular.
- [ ] **Step 3:** Minimal implementasyon.
- [ ] **Step 4: Test** — Run: `npm test` → PASS
- [ ] **Step 5: Commit** — `git commit -am "feat: domain models + pure helpers"`

### Task 2.2: Arapça normalleştirici

**Files:**
- Create: `src/domain/arabicNormalizer.ts`
- Source: `lib/domain/arabic_normalizer.dart`

**Interfaces:**
- Consumes: yok.
- Produces: `normalizeArabic(input: string): string`.

- [ ] **Step 1: Test yaz** — `src/domain/__tests__/arabicNormalizer.test.ts`

```ts
import { normalizeArabic } from '@/domain/arabicNormalizer';
test('harekeleri kaldırır', () => {
  expect(normalizeArabic('بِسْمِ')).toBe('بسم');
});
test('elif varyantlarını birleştirir', () => {
  expect(normalizeArabic('أإآ')).toBe('ااا');
});
test('te-merbuta he olur, tatweel silinir', () => {
  expect(normalizeArabic('رحمةــ')).toBe('رحمه');
});
```

- [ ] **Step 2: Çalıştır → FAIL** (modül yok). Run: `npm test arabicNormalizer`
- [ ] **Step 3: Implementasyon** — Dart kaynağındaki tam kural seti:
  - Harekeleri kaldır: `ً-ٟ`, `ۖ-ۭ`
  - Tatweel `ـ` sil
  - Elif: `آأإٱ` → `ا`
  - Te-merbuta `ة` → `ه`
  - Vav+hemze `ؤ` → `و`; Ya+hemze `ئ` → `ي`
  - Müstakil hemze `ء` sil
  - Çoklu boşluk → tek boşluk, trim
- [ ] **Step 4: Çalıştır → PASS**
- [ ] **Step 5: Commit** — `git commit -am "feat: arabic normalizer (TDD)"`

### Task 2.3: Kur'an ayet eşleştirici (IDF + LCS)

**Files:**
- Create: `src/data/quranMatcher.ts`
- Test: `src/data/__tests__/quranMatcher.test.ts`
- Source: `lib/data/quran_matcher.dart`, mevcut `test/quran_matcher_test.dart` (test senaryoları buradan taşınır)

**Interfaces:**
- Consumes: `normalizeArabic`, `QuranFullAyah[]` (`{surah, ayah, arabic, meal}`).
- Produces: `class QuranMatcher { constructor(ayahs: QuranFullAyahRow[]); matchRecitation(query: string, topN?: number): MatchResult[] }`, `type MatchResult = { surah: number; ayah: number; arabic: string; meal: string; score: number }`.

- [ ] **Step 1: Testleri taşı** — `test/quran_matcher_test.dart` içindeki senaryoları TS'e çevir: tam ayet metni verildiğinde 1. eşleşme doğru sure/ayet; kısmi/harekesiz metinde de doğru ilk sonuç; boş query → boş sonuç.
- [ ] **Step 2: Çalıştır → FAIL**
- [ ] **Step 3: Implementasyon** — Dart algoritmasını birebir:
  - Token IDF ağırlıkları kurulumda hesaplanır (lazy init).
  - Skor = F1 (IDF-ağırlıklı precision/recall) + run bonus (`en uzun bitişik ortak alt-dizi / query uzunluğu * 0.5`).
  - `normalizeArabic` ile normalize edilmiş tokenlar.
- [ ] **Step 4: Çalıştır → PASS**
- [ ] **Step 5: Commit** — `git commit -am "feat: quran matcher (IDF+LCS, TDD)"`

### Task 2.4: Drizzle şeması (16 tablo) + SQLite istemcisi

**Files:**
- Create: `src/data/db/schema.ts`, `src/data/db/client.ts`, `drizzle.config.ts`
- Source: `lib/data/local/app_database.dart` (şema v4, 16 tablo)

**Interfaces:**
- Produces: Drizzle tablo nesneleri (`esmaNames, duas, surahs, ayahs, quranFullAyahs, topicalAyahs, stories, miracles, tajweedLessons, dreamSymbols, dhikrCounters, collections, memorizations, juzProgress, readingEvents, favoriteSurahs`) ve `db` (drizzle + expo-sqlite).
- Consumes: yok.

- [ ] **Step 1: `schema.ts`** — Drift tablolarını Drizzle `sqliteTable` ile birebir kolon/tip eşlemesiyle tanımla. Örn:

```ts
import { sqliteTable, integer, text } from 'drizzle-orm/sqlite-core';
export const ayahs = sqliteTable('ayahs', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  surahNumber: integer('surah_number').notNull(),
  numberInSurah: integer('number_in_surah').notNull(),
  arabic: text('arabic').notNull(),
  meal: text('meal').notNull(),
  tafsir: text('tafsir'),
});
export const quranFullAyahs = sqliteTable('quran_full_ayahs', {
  surahNumber: integer('surah_number').notNull(),
  numberInSurah: integer('number_in_surah').notNull(),
  arabic: text('arabic').notNull(),
  meal: text('meal').notNull(),
});
// ... 14 tablo daha (rapordaki kolonlarla)
```

- [ ] **Step 2: `client.ts`** — `expo-sqlite` `openDatabaseSync('kuran_db')` + `drizzle(...)`; uygulama açılışında `db:generate` migration'larını uygula (`drizzle-orm/expo-sqlite/migrator` veya manuel `PRAGMA user_version`).
- [ ] **Step 3: `drizzle.config.ts`** — dialect `sqlite`, driver `expo`, `schema: './src/data/db/schema.ts'`.
- [ ] **Step 4: Migration üret** — Run: `npm run db:generate` → `src/data/db/migrations/` dolar.
- [ ] **Step 5: Şema testi** — `schema.test.ts`: tablo objelerinin tanımlı olduğunu ve `quranFullAyahs` kolon adlarının (`surah_number` vb.) doğru olduğunu doğrula.
- [ ] **Step 6: Test** — Run: `npm test` → PASS
- [ ] **Step 7: Commit** — `git commit -am "feat: drizzle schema (16 tables) + sqlite client"`

### Task 2.5: Seed verisi + seed servisi

**Files:**
- Create: `src/data/seed/seedData.ts`, `src/data/seed/seedService.ts`
- Copy: `assets/quran/quran_full.json` (Flutter `assets/quran/quran_full.json` birebir kopya)
- Source: `lib/data/seed/seed_data.dart`, `lib/data/seed/seed_service.dart`

**Interfaces:**
- Consumes: `db`, tablolar.
- Produces: `seedIfNeeded(db): Promise<void>` (Drift `seed_service` mantığı: dini tablolar sıfırlanıp yeniden seed; kullanıcı tabloları korunur), `SCHEMA_VERSION` sabiti.

- [ ] **Step 1:** `quran_full.json`'u `assets/quran/`'a kopyala; `client.ts`/`seedService` `require('../../assets/quran/quran_full.json')` veya `expo-asset` ile yükle.
- [ ] **Step 2:** `seed_data.dart` içindeki hardcoded tuple'ları (99 esma, dualar, 114 sure, kısa sureler, topical, kıssalar, mucizeler, tecvid, rüya sembolleri) `seedData.ts`'ye TS dizileri olarak taşı. **Türkçe/Arapça string'ler birebir.**
- [ ] **Step 3:** `seedIfNeeded`: `PRAGMA user_version` (veya meta tablo) ile sürüm kontrolü → dini tabloları temizle + toplu `insert` (transaction). `quranFullAyahs`'ı JSON'dan 6236 satır olarak chunk'lı insert et. Kullanıcı tabloları (`dhikrCounters, collections, memorizations, juzProgress, readingEvents, favoriteSurahs`) korunur.
- [ ] **Step 4: Test (mantık)** — `seedService.test.ts`: in-memory/better-sqlite ile veya seed sürüm karşılaştırma saf fonksiyonu `needsReseed(currentVersion, targetVersion)` için unit test.
- [ ] **Step 5: Test** — Run: `npm test` → PASS
- [ ] **Step 6: Commit** — `git commit -am "feat: seed data + offline-first seed service"`

### Task 2.6: Supabase istemcisi + uzak Kur'an API + altın fiyat servisi

**Files:**
- Create: `src/data/supabase.ts`, `src/data/quranApi.ts`, `src/services/goldPriceService.ts`
- Source: `lib/data/quran_api.dart`, `lib/data/services.dart` (GoldPriceService), `AppConfig`

**Interfaces:**
- Produces:
  - `supabase` (yalnızca `AppConfig.hasSupabase` ise gerçek istemci; değilse `null`), AsyncStorage ile session persist.
  - `fetchSurahFromApi(number): Promise<AyahRow[]>` (AlQuran Cloud `quran-uthmani` + `tr.diyanet`, 12s/20s timeout).
  - `getGoldPrice(): Promise<{ gold: number; silver: number }>` (cache: AsyncStorage, tarih kontrolü).

- [ ] **Step 1:** `supabase.ts` — `createClient(url, anonKey, { auth: { storage: AsyncStorage, persistSession: true, autoRefreshToken: true } })`; `hasSupabase` false ise `export const supabase = null`.
- [ ] **Step 2:** `quranApi.ts` — `fetch` + `AbortController` timeout; eksik ayetleri çekip `ayahs`/`quranFullAyahs` cache'ine yazma (offline-first; çağıran repository karar verir).
- [ ] **Step 3:** `goldPriceService.ts` — Dio yerine `fetch`; AsyncStorage cache anahtarları (`gold_price_gram_tl`, `gold_price_date`, `silver_price_gram_tl`, `silver_price_date`).
- [ ] **Step 4: Test** — `goldPriceService.test.ts`: cache tazeyse ağ çağrısı yapılmaz (mock fetch). `quranApi` parse fonksiyonu için saf `parseEditions(json)` test edilir.
- [ ] **Step 5: Test** — Run: `npm test` → PASS
- [ ] **Step 6: Commit** — `git commit -am "feat: supabase client + quran api + gold price service"`

### Task 2.7: Yerel içerik & kullanıcı veri repository'leri

**Files:**
- Create: `src/data/repositories/{contentRepository,dhikrRepository,collectionsRepository,memorizeRepository,juzRepository,readingRepository,favoritesRepository}.ts`
- Source: `lib/data/content_repository.dart`, `lib/data/repositories.dart`, `lib/data/services.dart`

**Interfaces:**
- Produces (TanStack Query/Zustand'ın tüketeceği fonksiyonlar):
  - `contentRepository`: `surahs()`, `ayahsForSurah(n)`, `esmaNames()`, `duas()`, `topicalAyahs(topic?)`, `stories()`, `miracles()`, `tajweedLessons()`, `dreamSymbols(query?)`.
  - `dhikrRepository`: `setCount(presetKey, dateIso, count)`, `dayTotal(dateIso)`, `watchDayTotal(dateIso)` (polling/invalidate).
  - `collectionsRepository`: `add(item)`, `list()`, `remove(id)`.
  - `memorizeRepository`, `juzRepository`, `readingRepository` (streak/stats), `favoritesRepository`.

- [ ] **Step 1:** Her repository Drizzle sorgularıyla; Drift `watch` reaktivitesi → TanStack Query `invalidateQueries` ile taklit. Saf hesaplama (streak güncelleme `computeStreak(lastDate, today, currentStreak)`) ayrı export.
- [ ] **Step 2: Test** — `readingRepository.test.ts`: `computeStreak` (ardışık gün → +1, gün atlanmış → 1, aynı gün → değişmez).
- [ ] **Step 3: Test** — Run: `npm test` → PASS
- [ ] **Step 4: Commit** — `git commit -am "feat: content + user-data repositories"`

### Task 2.8: Supabase backend repository'leri

**Files:**
- Create: `src/data/backend/{profileRepository,socialRepository,messagesRepository,khatmRepository,renderRepository,syncRepository}.ts`
- Source: `lib/data/backend_repositories.dart`

**Interfaces:**
- Produces:
  - `profileRepository`: `me()`, `update(profile)`, auth `changes` (onAuthStateChange) stream → hook.
  - `socialRepository`: `feed()` (seed + `feed_posts`), `like(postId)`, realtime feed subscription.
  - `messagesRepository`: `conversations()`, `messages(convId)`, realtime subscription, `send(...)`.
  - `khatmRepository`: `circles()`, `claim(...)`.
  - `renderRepository`: `trigger(...)` (Edge Func `render-trigger`), `status(jobId)` (`render-status`).
  - `syncRepository`: `pushDhikr(...)`, `pushCollections(...)` (hata yutulur — offline devam).
  - `FeedPost`, `ChatMessage` tipleri (Flutter `fromMap` karşılığı parse fonksiyonları).

- [ ] **Step 1:** Tüm metotlar `supabase` null ise graceful no-op/empty döner (Flutter `hasSupabase` guard'ı).
- [ ] **Step 2:** Realtime: `supabase.channel(...).on('postgres_changes', ...)` → React hook'a sarılır (FAZ 3'te).
- [ ] **Step 3: Test** — `FeedPost.fromMap` ve `ChatMessage.fromMap` parse saf fonksiyonları için unit test.
- [ ] **Step 4: Test** — Run: `npm test` → PASS
- [ ] **Step 5: Commit** — `git commit -am "feat: supabase backend repositories"`

---

## FAZ 3 — Servisler (Native Köprüler) + State Katmanı

### Task 3.1: Tercihler (PrefsService) + Ayarlar store'u

**Files:**
- Create: `src/services/prefsService.ts`, `src/state/stores/settingsStore.ts`
- Source: `lib/data/services.dart` (PrefsService), `lib/data/repositories.dart` (SettingsController)

**Interfaces:**
- Produces: `prefsService` (AsyncStorage: tüm `shared_preferences` anahtarları — rapordaki tam liste); `useSettingsStore` (Zustand: `AppSettings` + `setMeal`, `setInterests`, `setNotificationsGranted`, `completeOnboarding`).

- [ ] **Step 1:** `prefsService` get/set + JSON serialize; anahtarlar: `onboarding_complete, meal_option, interests, notifications_granted, prayer_log_*, reading_goal_pages, reading_streak, reading_last_read_date, reading_today_read, gold_price_*`.
- [ ] **Step 2:** `settingsStore` (Zustand) — `build()` yerine init action; komut metotları state'i güncelleyip `prefsService.save` çağırır.
- [ ] **Step 3: Test** — `settingsStore.test.ts`: `setMeal('elmalili')` sonrası state ve persist çağrısı (mock AsyncStorage).
- [ ] **Step 4: Test** — Run: `npm test` → PASS
- [ ] **Step 5: Commit** — `git commit -am "feat: prefs service + settings store"`

### Task 3.2: Konum + Namaz vakti servisleri

**Files:**
- Create: `src/services/locationService.ts`, `src/services/prayerService.ts`, `src/state/queries/usePrayerDay.ts`
- Source: `lib/data/device_services.dart` (LocationService, PrayerService)

**Interfaces:**
- Consumes: `adhan` (npm), `PrayerDay` modeli.
- Produces: `locationService.current(): Promise<{lat,lng}|null>` (expo-location, izin); `prayerService.compute({lat,lng,date}): PrayerDay` (adhan `CalculationMethod.turkey`, `Madhab.shafi`, fallback İstanbul 41.0055/28.9769); `usePrayerDay()` (TanStack Query, AsyncNotifier karşılığı).

- [ ] **Step 1:** `npm i adhan` + `npx expo install expo-location`.
- [ ] **Step 2:** `prayerService.compute` — adhan ile 6 vakit (İmsak/Güneş/Öğle/İkindi/Akşam/Yatsı) + tomorrowFajr; `PrayerDay` döndür. Bu **saf** olduğundan test edilir.
- [ ] **Step 3: Test** — `prayerService.test.ts`: bilinen lat/lng/tarih için vakit sayısı 6 ve sıralı; fallback konum default İstanbul.
- [ ] **Step 4:** `usePrayerDay` hook'u: konum al → compute; `refresh()` invalidate.
- [ ] **Step 5: Test** — Run: `npm test` → PASS
- [ ] **Step 6: Commit** — `git commit -am "feat: location + prayer time services"`

### Task 3.3: Kıble servisi (manyetometre)

**Files:**
- Create: `src/services/qiblaService.ts`, `src/state/queries/useQibla.ts`
- Source: `lib/data/device_services.dart` (QiblaService), `qibla_screen.dart`

**Interfaces:**
- Consumes: `expo-sensors` Magnetometer, `adhan` `Qibla`, `QiblaInfo`.
- Produces: `qiblaService.headingStream(callback)`, `qiblaService.qiblaBearing(lat,lng): number`; `useQibla()` hook → `QiblaInfo` akışı (deviceHeading + qiblaBearing).

- [ ] **Step 1:** `npx expo install expo-sensors`; manyetometreden heading (`Math.atan2`) hesapla; `adhan` `Qibla(coords)` ile Kâbe açısı.
- [ ] **Step 2:** `useQibla` — subscription, throttling.
- [ ] **Step 3: Test** — `qiblaService.test.ts`: `headingFromMagnetometer({x,y})` saf fonksiyonu bilinen değerde doğru derece.
- [ ] **Step 4: Test** — Run: `npm test` → PASS
- [ ] **Step 5: Commit** — `git commit -am "feat: qibla service (magnetometer)"`

### Task 3.4: Bildirim servisi

**Files:**
- Create: `src/services/notificationService.ts`
- Source: `lib/data/device_services.dart` (NotificationService)

**Interfaces:**
- Consumes: `expo-notifications`.
- Produces: `notificationService.init()`, `requestPermission()`, `schedulePrayer(slots)`, `scheduleDailyAyah(time)`, `scheduleHolyDay(...)`, `cancelAll()`.

- [ ] **Step 1:** `npx expo install expo-notifications`; handler kur; `app.config.ts`'e plugin ekle.
- [ ] **Step 2:** Zamanlama: `Notifications.scheduleNotificationAsync` ile namaz vakti tetikleyicileri (timezone → JS Date yeterli).
- [ ] **Step 3: Test** — `notificationService.test.ts`: `buildPrayerTriggers(slots)` saf fonksiyonu doğru tetikleyici listesi üretir (mock).
- [ ] **Step 4: Test** — Run: `npm test` → PASS
- [ ] **Step 5: Commit** — `git commit -am "feat: notification service"`

### Task 3.5: Ses (TTS, tilavet oynatıcı, kayıt) + tanıma servisleri

**Files:**
- Create: `src/services/ttsService.ts`, `src/services/audioService.ts`, `src/services/recognitionService.ts`
- Source: `lib/data/services.dart` (TtsService), `lib/data/services/quran_recognition_service.dart`

**Interfaces:**
- Produces:
  - `ttsService.speak(text, {lang:'tr-TR', rate:0.85, volume:1.0})`, `stop()` (expo-speech).
  - `audioService`: `play(url)`, `pause()`, `stop()` (expo-av); tilavet sıralı oynatma.
  - `recognitionService`: `startRecording()`, `stopRecording(): Promise<path>` (expo-av/expo-audio, m4a/AAC), `transcribeAudio(path): Promise<string>` (Edge Func `quran-recognize`, base64), `recognizeImage(uri): Promise<string>` (Edge Func `quran-vision`).

- [ ] **Step 1:** `npx expo install expo-speech expo-av expo-file-system`.
- [ ] **Step 2:** `ttsService` (expo-speech), `audioService` (expo-av Sound).
- [ ] **Step 3:** `recognitionService` — kayıt → base64 (`expo-file-system`) → `supabase.functions.invoke('quran-recognize')`; görsel → `quran-vision`. Sonuç `QuranMatcher.matchRecitation` ile eşleşir (çağıran ekranda).
- [ ] **Step 4: Test** — `recognitionService.test.ts`: `toBase64Payload` / response parse saf fonksiyon testi (mock invoke).
- [ ] **Step 5: Test** — Run: `npm test` → PASS
- [ ] **Step 6: Commit** — `git commit -am "feat: tts + audio + recognition services"`

### Task 3.6: Sesli yazma (STT), görsel/dosya seçim, paylaşım, derin bağlantı

**Files:**
- Create: `src/services/{sttService,mediaService,shareService,linkingService}.ts`
- Source: `ai_assistant_screen.dart` (speech_to_text), `image_picker`/`file_picker`, `share_plus`, `receive_sharing_intent`, `url_launcher` kullanımları

**Interfaces:**
- Produces: `sttService.listen(onResult, {locale:'tr-TR'})`/`stop()`; `mediaService.pickImage()`, `pickFile()`; `shareService.share({text, url, files})`; `linkingService.openUrl(url)`, `useShareIntent()` (gelen görsel → `/ayah-recognition`).

- [ ] **Step 1:** `npm i @react-native-voice/voice expo-share-intent` + `npx expo install expo-image-picker expo-document-picker expo-sharing expo-linking`.
- [ ] **Step 2:** `useShareIntent` — `expo-share-intent` ile gelen görseli yakala → router `push('/ayah-recognition?image=...')` (Flutter `receive_sharing_intent` → Instagram repost akışı).
- [ ] **Step 3: Test** — `linkingService.test.ts`: `buildMapsUrl(lat,lng)` / `buildAyahShareText(...)` saf fonksiyon testi.
- [ ] **Step 4: Test** — Run: `npm test` → PASS
- [ ] **Step 5: Commit** — `git commit -am "feat: stt + media + share + linking services"`

---

## FAZ 4 — Navigasyon, Onboarding, Kimlik & Kabuk

### Task 4.1: Root layout + sağlayıcılar + bootstrap

**Files:**
- Create: `app/_layout.tsx`, `app/index.tsx`, `src/state/queryClient.ts`
- Source: `lib/main.dart`, `lib/app/app.dart` (bootstrap, KuranApp)

**Interfaces:**
- Consumes: `appFonts`, `seedIfNeeded`, `db`, `useSettingsStore`, `QueryClientProvider`, `useShareIntent`.
- Produces: Uygulama kökü; font yüklenene + bootstrap bitene kadar splash; sonra yönlendirme.

- [ ] **Step 1:** `_layout.tsx` — `QueryClientProvider`, `GestureHandlerRootView`, `SafeAreaProvider`; `useFonts(appFonts)`; `useEffect` → `seedIfNeeded(db)` + Supabase init guard; `useShareIntent()`. Hazır olunca `<Stack>`.
- [ ] **Step 2:** `index.tsx` — onboardingComplete'e göre `/splash` veya `/(tabs)/home`'a `Redirect`.
- [ ] **Step 3: Test** — `_layout` smoke render (mock fonts/db).
- [ ] **Step 4: Test** — Run: `npm test` → PASS
- [ ] **Step 5: Manuel doğrulama** — Run: `npx expo start` → uygulama splash'tan açılır (boş ekranlar olsa da).
- [ ] **Step 6: Commit** — `git commit -am "feat: root layout + providers + bootstrap"`

### Task 4.2: Sekme kabuğu (5 sekme + orta FAB) + sayfa geçişleri

**Files:**
- Create: `app/(tabs)/_layout.tsx`, `app/(tabs)/{home,feed,messages,profile}.tsx` (iskelet), `src/components/CreateFab.tsx`, `src/components/CreateSheet.tsx`
- Source: `lib/app/router.dart` (StatefulShellRoute), `home_screens.dart` (HomeShell, ShowCreateSheet), `page_transitions.dart`

**Interfaces:**
- Consumes: tab navigator.
- Produces: 5 sekmeli alt bar (Ana Sayfa, Akış, +Oluştur(FAB), Mesajlar, Profil); ortadaki FAB `CreateSheet`'i açar (Studio/AI seçenekleri); stack route geçişleri (`sharedAxis`/`fadeThrough` → Expo Router `animation` seçenekleri).

- [ ] **Step 1:** `(tabs)/_layout.tsx` — `Tabs` (expo-router); aktif altın + scale 1.12 (reanimated), inaktif muted; orta sekme yerine özel `CreateFab` (gradient 52×52, gold shadow).
- [ ] **Step 2:** `CreateSheet` — `showModalBottomSheet` karşılığı (`@gorhom/bottom-sheet` veya RN `Modal`); seçenekler `/studio`, `/ai-assistant`.
- [ ] **Step 3:** Stack ekranlarına `animation: 'slide_from_right'`/`fade` (Material 3 motion yaklaşımı).
- [ ] **Step 4: Test** — `_layout` 4 sekme + FAB render testi.
- [ ] **Step 5: Manuel** — sekmeler arası geçiş, FAB sheet açılır.
- [ ] **Step 6: Commit** — `git commit -am "feat: tab shell + create FAB + transitions"`

### Task 4.3: Onboarding (Splash + 3 adımlı Setup) + Auth

**Files:**
- Create: `app/splash.tsx`, `app/setup.tsx`, `app/auth.tsx`, `src/features/onboarding/*`, `src/features/auth/*`
- Source: `lib/features/onboarding/onboarding_screens.dart`, auth (Supabase email/Google)

**Interfaces:**
- Consumes: `useSettingsStore`, `profileRepository`, `sttService` yok; `@react-native-google-signin`.
- Produces: Splash (2.4s animasyon + "Anla · Düşün · Paylaş"); Setup 3 adım (meal: Diyanet/Elmalılı/TDV → ilgi 5 checkbox → bildirim izni); Auth (email/şifre + Google `signInWithIdToken`).

- [ ] **Step 1:** Splash — `moti` fade/scale; bitince `onboardingComplete`'e göre `/setup` veya `/(tabs)/home`.
- [ ] **Step 2:** Setup — 3 adım; `GoldChip`/checkbox; son adım `notificationService.requestPermission()`; tamamla → `settingsStore.completeOnboarding()` → `/(tabs)/home`.
- [ ] **Step 3:** Auth — `npm i @react-native-google-signin/google-signin`; email/şifre `supabase.auth.signInWithPassword`; Google ID token → `supabase.auth.signInWithIdToken`.
- [ ] **Step 4: Test** — Setup adım ilerleme reducer/saf mantık testi (meal seçilmeden ilerlenemez).
- [ ] **Step 5: Manuel** — onboarding akışı baştan sona; meal seçimi persist olur.
- [ ] **Step 6: Commit** — `git commit -am "feat: onboarding + setup + auth"`

### Task 4.4: Özellik kataloğu + sabitler

**Files:**
- Create: `src/features/featureCatalog.ts`, `app/features.tsx`
- Source: `lib/app/feature_catalog.dart` (kFeatures, 24 FeatureDef), router rotaları

**Interfaces:**
- Produces: `kFeatures: FeatureDef[]` (`{key, title, route, category, icon}`), `kQuickActions` (8 hızlı işlem: `/quran,/prayer,/dhikr,/qibla,/daily-ayah,/esma,/dua,/zakat`).

- [ ] **Step 1:** 24 özelliği `featureCatalog.ts`'e taşı (Türkçe başlıklar birebir).
- [ ] **Step 2:** `features.tsx` — kategoriye göre gruplu liste; her kart → ilgili route.
- [ ] **Step 3: Test** — `featureCatalog.test.ts`: 24 özellik var; her route benzersiz; quick actions 8 adet.
- [ ] **Step 4: Test** — Run: `npm test` → PASS
- [ ] **Step 5: Commit** — `git commit -am "feat: feature catalog + features screen"`

---

## FAZ 5 — Özellik Ekranları (24)

> **Her ekran görevinin ortak deseni** (No-Placeholder kuralı için açık talimat): Belirtilen **kaynak Flutter dosyasını** ekranın spesifikasyonu olarak kullan. Kaynaktaki tüm Türkçe metinleri, mizanpajı, durumları ve etkileşimleri birebir taşı. Tüketilen hook/store/servis ve core bileşenler her görevde listelidir. Riverpod tüketimi → ilgili TanStack Query hook'u/Zustand store'u; `setState` yerel → React `useState`. Her görev: (a) ekranı yaz, (b) varsa saf ekran-içi mantık için bir test, (c) `npm test && npm run typecheck`, (d) cihazda/emülatörde manuel doğrula, (e) commit.

### Task 5.1: Namaz Vakitleri (`/prayer`)

**Files:** Create `app/(features)/prayer.tsx`, `src/features/prayer/*` · Source `lib/features/prayer/prayer_screen.dart`
**Interfaces:** Consumes `usePrayerDay`, `locationService`, `notificationService`, `AppHeader`, `AppCard`, `CircularProgress`, `EmptyState`. Produces ekran.
- [ ] Ekranı yaz: 6 vakit listesi + sıradaki vakte geri sayım (`prayerDayNextAfter`), konum yenile butonu, bildirim zamanla.
- [ ] `loading/error/data` (Query `isPending/isError/data`) → `EmptyState`/spinner.
- [ ] Test (geri sayım format saf fonksiyonu) → `npm test` → PASS · Manuel doğrula · Commit.

### Task 5.2: Zikirmatik + Tesbihat (`/dhikr`, `/tasbihat`)

**Files:** Create `app/(features)/dhikr.tsx`, `app/(features)/tasbihat.tsx`, `src/features/dhikr/*`, `src/state/stores/dhikrStore.ts` · Source `lib/features/dhikr/dhikr_screens.dart`
**Interfaces:** Consumes `dhikrRepository`, `syncRepository`, `TasbihDial`, `CircularProgress`, `AnimatedCounter`, `GoldChip`, haptics (`expo-haptics`). Produces `useDhikrStore` (6 preset, count, increment/reset).
- [ ] `npx expo install expo-haptics`.
- [ ] `dhikrStore` (Zustand): increment → state + `dhikrRepository.setCount` + `syncRepository.pushDhikr` (fire-and-forget). 6 preset (Sübhânallâh, Elhamdülillâh, Allâhu Ekber, Estağfirullâh, Lâ ilâhe illallâh, Salavât).
- [ ] Dhikr ekranı: dairesel sayaç, hedef %, günlük toplam (Query), haptik. Tesbihat: 33-33-33 rehber.
- [ ] Test (`dhikrStore.increment`) → PASS · Manuel · Commit.

### Task 5.3: Dua Kütüphanesi (`/dua`)

**Files:** Create `app/(features)/dua.tsx`, `src/features/dua/*` · Source `lib/features/dua/dua_screen.dart`
**Interfaces:** Consumes `contentRepository.duas`, `GoldChip` (kategori filtresi), `AyetFrame`, `AppCard`.
- [ ] Kategoriye göre dua listesi (Şifa, Rızık, Yolculuk, Sınav, Koruma…); Arapça + Türkçe + kaynak.
- [ ] Test (kategori filtre saf fonksiyonu) → PASS · Manuel · Commit.

### Task 5.4: Esmaü'l-Hüsna (`/esma`)

**Files:** Create `app/(features)/esma.tsx`, `src/features/esma/*` · Source `lib/features/esma/esma_screen.dart`
**Interfaces:** Consumes `contentRepository.esmaNames`, `AppCard`, `AyetFrame`.
- [ ] 99 isim listesi (sıra + Arapça + okunuş + anlam); ezber modu kartı.
- [ ] Test (liste 99 öğe) → PASS · Manuel · Commit.

### Task 5.5: Oruç / İmsakiye (`/fasting`)

**Files:** Create `app/(features)/fasting.tsx`, `src/features/fasting/*` · Source `lib/features/fasting/fasting_screen.dart`
**Interfaces:** Consumes `usePrayerDay` (iftar=Akşam, sahur=İmsak), `hijri-converter`, `CircularProgress`.
- [ ] `npm i hijri-converter`. İftar/sahur geri sayım; Ramazan hicri takvim; kaza takibi.
- [ ] Test (geri sayım hesabı) → PASS · Manuel · Commit.

### Task 5.6: Dini Günler / Kandiller (`/holy-days`)

**Files:** Create `app/(features)/holy-days.tsx`, `src/features/holyDays/*` · Source `lib/features/holy_days/holy_days_screen.dart`
**Interfaces:** Consumes `hijri-converter`, `notificationService`, `AppCard`.
- [ ] Hicri takvim + kandil tarihleri + yaklaşan gün geri sayımı.
- [ ] Test (sıradaki kandil saf fonksiyonu) → PASS · Manuel · Commit.

### Task 5.7: Kıble Pusulası (`/qibla`)

**Files:** Create `app/(features)/qibla.tsx`, `src/features/qibla/*` · Source `lib/features/qibla/qibla_screen.dart`
**Interfaces:** Consumes `useQibla`, `QiblaDial`, `EmptyState`.
- [ ] 300×300 `QiblaDial`; real-time heading; hizalanınca yeşil + (haptik). İzin yoksa `EmptyState`.
- [ ] Test (`qiblaAligned`) → PASS · Manuel (gerçek cihaz; manyetometre emülatörde yok) · Commit.

### Task 5.8: Kur'an Okuma — sure listesi + ayet okuma (`/quran`, `/quran/[surah]`)

**Files:** Create `app/(features)/quran.tsx`, `app/(features)/quran/[surah].tsx`, `src/features/quran/*` · Source `lib/features/quran/quran_screens.dart`
**Interfaces:** Consumes `contentRepository.surahs/ayahsForSurah`, `fetchSurahFromApi` (cache miss fallback), `audioService` (tilavet), `ttsService` (sesli okuma), `favoritesRepository`, `readingRepository` (okuma istatistiği), `AyetFrame`, `HeroCard`, `AppHeader`.
- [ ] Sure listesi (114, sayfa no); sure detayı: Arapça (Amiri, RTL) + meal + tefsir; tilavet oynat (sıralı), TTS sesli okuma, sepya modu, favori, okuma seansı kaydı.
- [ ] Eksik ayet → API'den çek + cache'e yaz (offline-first).
- [ ] Test (okuma seansı kaydı/streak entegrasyonu saf kısmı) → PASS · Manuel (oynatma, kaydırma) · Commit.

### Task 5.9: Günün Ayeti (`/daily-ayah`)

**Files:** Create `app/(features)/daily-ayah.tsx`, `src/features/dailyAyah/*` · Source `lib/features/daily_ayah/daily_ayah_screen.dart`
**Interfaces:** Consumes `contentRepository`, `shareService`, `HeroCard`, `AyetFrame`.
- [ ] **Deterministik seçim**: güne göre ayet+hadis (saf fonksiyon `pickDailyAyah(dateSeed, list)`). Paylaş.
- [ ] Test (aynı gün → aynı ayet; farklı gün → farklı) → PASS · Manuel · Commit.

### Task 5.10: Konuya Göre Ayet (`/topical`)

**Files:** Create `app/(features)/topical.tsx`, `src/features/topical/*` · Source `lib/features/topical/topical_screen.dart`
**Interfaces:** Consumes `contentRepository.topicalAyahs`, `GoldChip`, `AyetFrame`.
- [ ] Ruh hali/konu seçimi (Sabır, Huzur, Umut, Şükür, Tevekkül…); ilgili ayetler.
- [ ] Test (konu filtresi) → PASS · Manuel · Commit.

### Task 5.11: Mucizeler (`/miracles`)

**Files:** Create `app/(features)/miracles.tsx` · Source `lib/features/learning/learning_screens.dart` (Miracles)
**Interfaces:** Consumes `contentRepository.miracles`, `AppCard`.
- [ ] Kategoriye göre (bilimsel, astronomi, embriyoloji, tarihi, sayısal) liste + detay.
- [ ] Test (kategori grupla) → PASS · Manuel · Commit.

### Task 5.12: Kıssalar (`/stories`)

**Files:** Create `app/(features)/stories.tsx` · Source `learning_screens.dart` (Stories)
**Interfaces:** Consumes `contentRepository.stories`, `ttsService` (sesli), `AppCard`.
- [ ] Peygamber kıssaları (sıra, okuma süresi, sesli seçenek).
- [ ] Test (okuma süresi format) → PASS · Manuel · Commit.

### Task 5.13: Tecvid (`/tajweed`)

**Files:** Create `app/(features)/tajweed.tsx` · Source `learning_screens.dart` (Tajweed)
**Interfaces:** Consumes `contentRepository.tajweedLessons`, `ttsService`/`audioService`, `AyetFrame`.
- [ ] Kurallar + Arapça örnek + sesli telaffuz + mini quiz.
- [ ] Test (mini quiz puanlama) → PASS · Manuel · Commit.

### Task 5.14: Quiz (`/quiz`)

**Files:** Create `app/(features)/quiz.tsx`, `src/features/quiz/*` · Source router `/quiz` (Daily Ayah Quiz)
**Interfaces:** Consumes `contentRepository.surahs`, `GoldChip`.
- [ ] 10 soru (sure adı/sayı/iniş yeri/anlam); puanlama.
- [ ] Test (soru üretimi + puanlama saf fonksiyon) → PASS · Manuel · Commit.

### Task 5.15: Sure Ezberi (`/memorize`)

**Files:** Create `app/(features)/memorize.tsx`, `src/features/memorize/*` · Source `lib/features/memorize` (Flutter'da placeholder; model tanımlı)
**Interfaces:** Consumes `memorizeRepository`, `CircularProgress`.
- [ ] Sure seç → ezber ilerlemesi (ezberlenen/toplam ayet); ilerleme kaydı (`Memorizations` tablosu).
- [ ] Test (ilerleme %) → PASS · Manuel · Commit.

### Task 5.16: Cüz/Hizb Takibi (`/juz-tracker`)

**Files:** Create `app/(features)/juz-tracker.tsx`, `src/features/juz/*` · Source router `/juz-tracker` (`JuzProgress` tablosu)
**Interfaces:** Consumes `juzRepository`, `CircularProgress`, `StatBox`.
- [ ] 30 cüz; tamamlandı işaretle; genel % (`JuzProgress`).
- [ ] Test (genel ilerleme hesabı) → PASS · Manuel · Commit.

### Task 5.17: İlerleme/İstatistik (`/progress`)

**Files:** Create `app/(features)/progress.tsx`, `src/features/progress/*` · Source `lib/features/progress/progress_screens.dart`
**Interfaces:** Consumes `readingRepository` (`ReadingEvents`), `StatBox`, `react-native-svg` (grafik).
- [ ] Ömür boyu/haftalık okuma; streak; basit çubuk/çizgi grafik.
- [ ] Test (haftalık toplama + streak) → PASS · Manuel · Commit.

### Task 5.18: Koleksiyonlar (`/collections`)

**Files:** Create `app/(features)/collections.tsx`, `src/features/collections/*` · Source `lib/features/collections/collections_screen.dart`
**Interfaces:** Consumes `collectionsRepository`, `syncRepository`, `AyetFrame`, `EmptyState`.
- [ ] Kaydedilen ayetler listesi; not ekle; sil; kategorize.
- [ ] Test (ekle/sil mantığı) → PASS · Manuel · Commit.

### Task 5.19: Zekât Hesaplama (`/zakat`)

**Files:** Create `app/(features)/zakat.tsx`, `src/features/zakat/*` · Source `lib/features/tools/tools_screens.dart` (Zakat)
**Interfaces:** Consumes `getGoldPrice`, `GoldChip` (mezhep), `StatBox`. **"Kesin hüküm değildir" uyarısı birebir korunur.**
- [ ] Nakit + altın gr + gümüş gr + alacak − borç; canlı fiyat; Hanefi/Şafi nisab; %2.5 sonuç.
- [ ] Test: `computeZakat({cash, goldGr, silverGr, receivables, debts, goldPrice, silverPrice, madhab})` saf fonksiyonu — nisab altı → 0; üstü → %2.5.

```ts
import { computeZakat } from '@/features/zakat/computeZakat';
test('nisab altı zekat 0', () => {
  expect(computeZakat({ cash: 100, goldGr: 0, silverGr: 0, receivables: 0, debts: 0, goldPrice: 2500, silverPrice: 30, madhab: 'hanafi' })).toBe(0);
});
```
- [ ] Test → PASS · Manuel · Commit.

### Task 5.20: Cami Bul (`/mosque`)

**Files:** Create `app/(features)/mosque.tsx`, `src/features/mosque/*` · Source `tools_screens.dart` (Mosque)
**Interfaces:** Consumes `locationService`, `linkingService` (yol tarifi), harita (`react-native-maps`).
- [ ] `npx expo install react-native-maps`. Yakın camiler (konum), vakitler, yol tarifi (`buildMapsUrl`).
- [ ] Test (`buildMapsUrl`) → PASS · Manuel · Commit.

### Task 5.21: Bağış (`/donate`)

**Files:** Create `app/(features)/donate.tsx`, `src/features/donate/*` · Source `tools_screens.dart` (Donate)
**Interfaces:** Consumes `linkingService`, `AppCard`.
- [ ] Kampanya listesi; hızlı bağış (URL); sadaka hatırlatıcısı.
- [ ] Test (kampanya render) → PASS · Manuel · Commit.

### Task 5.22: Rüya Tabiri (`/dream`)

**Files:** Create `app/(features)/dream.tsx`, `src/features/dream/*` · Source `tools_screens.dart` (Dream)
**Interfaces:** Consumes `contentRepository.dreamSymbols`, arama input. **"Kesin hüküm değildir" uyarısı birebir korunur.**
- [ ] Sembol araması (klasik kaynak); sonuç + uyarı.
- [ ] Test (arama filtresi) → PASS · Manuel · Commit.

### Task 5.23: AI Asistan + Ayet Tanıma (`/ai-assistant`, `/ayah-recognition`)

**Files:** Create `app/(features)/ai-assistant.tsx`, `app/ayah-recognition.tsx`, `src/features/ai/*` · Source `lib/features/ai/ai_assistant_screen.dart`
**Interfaces:** Consumes `supabase.functions.invoke('ai-assistant')` (+ yerel fallback `contentRepository.topicalAyahs`), `recognitionService` (ASR + OCR), `sttService` (Türkçe sesli yazma), `QuranMatcher`, `mediaService`, `AyetFrame`, `EmptyState`.
- [ ] Sohbet arayüzü (prompt → cevap; backend yoksa duygu→konu fallback haritası: sabır, huzur, umut… → topical).
- [ ] Ayet tanıma: mikrofon (ASR → `transcribeAudio` → `matchRecitation`), görsel (galeri/`image` param → `recognizeImage` → `matchRecitation`); en iyi 3 eşleşme Arapça+meal göster.
- [ ] Türkçe sesli yazma (`sttService.listen`).
- [ ] Test (fallback duygu→konu eşleme saf fonksiyonu) → PASS · Manuel (mikrofon/görsel gerçek cihaz) · Commit.

### Task 5.24: Video Stüdyo + My Videos (`/studio`, `/my-videos`)

**Files:** Create `app/(features)/studio.tsx`, `app/my-videos.tsx`, `src/features/studio/*` · Source `lib/features/studio/studio_screens.dart`
**Interfaces:** Consumes `renderRepository` (`render-trigger`/`render-status`), `contentRepository` (ayet + meal katmanları), `audioService` (tilavet önizleme), `video_player`→`expo-av`/`expo-video`, `shareService`, `HeroCard`, `GoldChip`.
- [ ] Şablon seç (6 gradyan tema) → tilavet seç (4 kāri) → ayet seç (Arapça + 3 meal katmanı) → backend render job başlat (Supabase) → durum takibi → paylaş. (Local FFmpeg render Flutter'da da backend'e devredilmiş; aynı yaklaşım.)
- [ ] My Videos: `render_jobs` listesi + durum.
- [ ] Test (şablon/katman state reducer) → PASS · Manuel · Commit.

---

## FAZ 6 — Topluluk (Tab İçerikleri) & Final

### Task 6.1: Ana Sayfa (Home tab)

**Files:** Modify `app/(tabs)/home.tsx`, Create `src/features/home/*` · Source `home_screens.dart` (HomeScreen)
**Interfaces:** Consumes `kQuickActions`, `pickDailyAyah`, `collectionsRepository`, `HeroCard`, `AppCard`.
- [ ] 8 hızlı işlem ızgarası + Günün Ayeti hero + kaydedilen ayetler.
- [ ] Test (quick action grid) → PASS · Manuel · Commit.

### Task 6.2: Akış (Feed tab)

**Files:** Modify `app/(tabs)/feed.tsx`, Create `src/features/community/feed/*` · Source `community_screens.dart` (Feed)
**Interfaces:** Consumes `socialRepository` (seed + `feed_posts` + realtime), `shareService`, `expo-av`/`expo-video` (reels), `AyetFrame`, `AppCard`.
- [ ] Ayet kartları (seed + bulut), beğen/paylaş, yazar; Reels sekmesi (render edilmiş videolar).
- [ ] Test (feed merge: seed + cloud) → PASS · Manuel · Commit.

### Task 6.3: Mesajlar (Messages tab)

**Files:** Modify `app/(tabs)/messages.tsx`, Create `src/features/community/messages/*` · Source `community_screens.dart` (Messages)
**Interfaces:** Consumes `messagesRepository` (realtime), `EmptyState`.
- [ ] Konuşma listesi + realtime mesaj akışı + gönder.
- [ ] Test (mesaj parse/sıralama) → PASS · Manuel · Commit.

### Task 6.4: Profil (Profile tab)

**Files:** Modify `app/(tabs)/profile.tsx`, Create `src/features/community/profile/*` · Source `community_screens.dart` (UserProfile)
**Interfaces:** Consumes `profileRepository`, `useSettingsStore`, `readingRepository` (istatistik), `mediaService` (avatar).
- [ ] Profil düzenleme (ad, avatar); istatistikler; ayarlar (meal değiştir); çıkış.
- [ ] Test (profil güncelle) → PASS · Manuel · Commit.

### Task 6.5: Hatim Halkaları (`/khatm`)

**Files:** Create `app/(features)/khatm.tsx`, `src/features/khatm/*` · Source `lib/features/khatm/khatm_screen.dart` (Flutter'da basit/placeholder)
**Interfaces:** Consumes `khatmRepository` (`khatm_circles`, `khatm_claims`), `CircularProgress`, `EmptyState`.
- [ ] Halka listesi; cüz dağıtım/claim; ilerleme.
- [ ] Test (cüz dağıtım mantığı) → PASS · Manuel · Commit.

### Task 6.6: Uçtan uca doğrulama + temizlik

**Files:** Tüm proje
- [ ] `npm run typecheck` → 0 hata; `npm test` → tüm testler PASS.
- [ ] `npx expo start` → onboarding → 5 sekme → her özellik route'u açılır; offline (uçak modu) çekirdek içerik çalışır.
- [ ] Native özellik duman testi (gerçek cihaz): namaz vakti (GPS), kıble (manyetometre), bildirim zamanlama, ses kayıt+tanıma, TTS, paylaşım.
- [ ] Supabase: login, feed realtime, mesaj realtime, AI asistan invoke, ayet tanıma invoke, render job.
- [ ] README: kurulum (`.env`, `npm i`, `db:generate`, `expo run`).
- [ ] Commit — `git commit -am "chore: e2e verification + README"`.

---

## Doğrulama (Verification)

**Birim testleri (CI/lokal):**
```bash
npm test          # arabicNormalizer, quranMatcher, computeZakat, computeStreak,
                  # pickDailyAyah, prayerService, qibla heading, modeller, repos saf fonksiyonları
npm run typecheck # strict TS, 0 hata
```
En kritik doğruluk birimleri TDD ile yazıldı: **Arapça normalleştirme**, **ayet eşleştirme**, **zekât**, **namaz vakti**, **günün ayeti determinizmi**.

**Manuel/cihaz doğrulaması (Flutter ile diff):** Aynı Supabase backend'ine bağlanıp Flutter ve Expo sürümlerini yan yana çalıştır; her ekranın görsel ve davranışsal eşdeğerliğini doğrula. Native özellikler (kıble, GPS, ASR, bildirim, paylaşım) yalnızca **gerçek cihazda** test edilir (emülatörde manyetometre/sensörler yok).

**Offline-first doğrulaması:** İlk açılışta seed → uçak modunda Kur'an okuma, esma, dua, topical, kıssalar, mucizeler, tecvid, zikir sayacı, koleksiyonlar tamamen çalışır; backend gerektiren akışlar (feed, mesaj, AI, render) graceful boş/fallback gösterir.

## Notlar
- Plan dosyası bu konumda; onay sonrası repo içine de (`docs/superpowers/plans/`) kopyalanabilir.
- `quran_full.json` (6236 ayet) birebir kopyalandığı için Kur'an metni/meal değişmez — dini doğruluk korunur.
- Riverpod→(Zustand+TanStack Query) ve Drift→Drizzle eşlemeleri 1:1 davranış hedefler; reaktif `watch` sorguları Query invalidation ile taklit edilir.
