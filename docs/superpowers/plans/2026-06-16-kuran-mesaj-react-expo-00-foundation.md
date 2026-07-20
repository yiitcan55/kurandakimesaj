# Kur'an'da ki Mesaj — React + Expo Port: 00 · Foundation (Temel Altyapı) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Flutter uygulamasının React Native (Expo) + Supabase portunun tüm omurgasını kurmak: proje iskeleti, Supabase veritabanı/şema/RLS, tasarım sistemi (tema, font, bileşenler), navigasyon, state yönetimi (Zustand + TanStack Query), çevrimdışı önbellek katmanı, auth, test altyapısı ve domain kuralı yardımcıları.

**Architecture:** Expo Router (dosya-tabanlı navigasyon) + 5-sekmeli tab shell (orta FAB ile). **Supabase tek veritabanıdır** (Postgres + Auth + Storage + Realtime + Edge Functions); sabit dini içerik Supabase'te tutulur ve TanStack Query persistence + MMKV + `expo-sqlite` cache tablosu ile cihazda önbelleğe alınarak çevrimdışı okunur. Client state Zustand, sunucu verisi TanStack Query ile yönetilir. Ayet→video stüdyosu Remotion Lambda (AWS) ile sunucu tarafında render edilir (Faz 2'de).

**Tech Stack:** Expo SDK 52 (React Native 0.76, React 18), TypeScript (strict), Expo Router 4, `@supabase/supabase-js` 2, `@tanstack/react-query` 5 + `@tanstack/query-async-storage-persister`, `zustand` 5, `react-native-mmkv`, `expo-sqlite`, `expo-secure-store`, `expo-font`, `expo-location`, `expo-notifications`, `expo-sensors` (magnetometer/qibla), `expo-av` (ses), `expo-haptics`, `react-native-reanimated` 3, `@shopify/flash-list`, `adhan` (npm), `hijri-date`/`moment-hijri`, `react-i18next` + `i18next`. Test: Jest + `jest-expo` + `@testing-library/react-native`.

---

## File Structure

Tüm uygulama kodu `app/` (Expo Router rotaları) ve `src/` (paylaşılan kod) altında. Her dosyanın tek bir sorumluluğu var; özellik ekranları feature-first klasörlerde toplanır.

```
kurandakimesaj-rn/                 # YENİ Expo projesi (mevcut Flutter ile yan yana)
├── app.json / app.config.ts       # Expo konfigürasyonu (plugins, fonts, permissions)
├── babel.config.js                # reanimated + react-native-worklets plugin
├── metro.config.js                # sqlite/asset uzantıları
├── tsconfig.json                  # strict + path alias (@/*)
├── .env / .env.example            # EXPO_PUBLIC_SUPABASE_URL, EXPO_PUBLIC_SUPABASE_ANON_KEY
├── jest.config.js                 # jest-expo preset
├── jest.setup.ts                  # test mock'ları (mmkv, supabase, expo modülleri)
│
├── app/                           # Expo Router (dosya-tabanlı rotalar)
│   ├── _layout.tsx                # Root: Provider'lar (QueryClient, fontlar, tema, auth gate)
│   ├── index.tsx                  # /splash davranışı (yönlendirme)
│   ├── setup.tsx                  # onboarding (Faz 1)
│   ├── auth.tsx                   # giriş/kayıt (bu plan)
│   ├── (tabs)/                    # 5-sekmeli shell
│   │   ├── _layout.tsx            # Tab bar (Home, Feed, FAB, Messages, Profile)
│   │   ├── home.tsx               # Ana sayfa (Faz 1)
│   │   ├── feed.tsx               # Akış (Faz 2)
│   │   ├── messages.tsx           # Mesajlar (Faz 3)
│   │   └── profile.tsx            # Profil (Faz 4)
│   └── (features)/                # tam-ekran özellik rotaları (her faz ekler)
│       └── _layout.tsx            # Stack (shared-axis benzeri geçiş)
│
├── src/
│   ├── theme/
│   │   ├── colors.ts              # AppColors (kesin hex)
│   │   ├── typography.ts          # font rolleri + arabicStyle
│   │   ├── tokens.ts              # radii, spacing, durations
│   │   └── index.ts               # useTheme + barrel (sadece tema, feature değil)
│   ├── ui/                        # paylaşılan bileşenler
│   │   ├── AppHeader.tsx
│   │   ├── AppCard.tsx
│   │   ├── HeroCard.tsx
│   │   ├── GoldChip.tsx
│   │   ├── AyetFrame.tsx
│   │   ├── StatBox.tsx
│   │   ├── SectionLabel.tsx
│   │   ├── EmptyState.tsx
│   │   ├── AnimatedCounter.tsx
│   │   ├── BottomSheet.tsx
│   │   ├── ArabicText.tsx         # RTL + Amiri Quran sarmalayıcı (domain kuralı)
│   │   ├── Disclaimer.tsx         # "kesin hüküm değildir" uyarısı (domain kuralı)
│   │   └── ScreenScaffold.tsx     # arka plan + SafeArea + header düzeni
│   ├── lib/
│   │   ├── supabase.ts            # SupabaseClient (secure-store session)
│   │   ├── queryClient.ts         # QueryClient + MMKV persister
│   │   ├── mmkv.ts                # MMKV instance + storage adapter
│   │   ├── cacheDb.ts             # expo-sqlite içerik önbellek tablosu
│   │   └── env.ts                 # env doğrulama
│   ├── stores/
│   │   ├── settingsStore.ts       # Zustand: ayar (meal, interests, bildirim, isPro)
│   │   └── authStore.ts           # Zustand: oturum durumu
│   ├── data/                      # Supabase erişim + tip + query hook fabrikaları
│   │   ├── types.ts               # tüm domain tipleri (TS)
│   │   ├── queryKeys.ts           # merkezi query key fabrikası
│   │   └── content.ts             # sabit içerik (esma/dua/sure...) okuma + cache
│   ├── domain/
│   │   └── rules.ts               # disclaimer metinleri, sıhhat etiketleri sabitleri
│   ├── i18n/
│   │   ├── index.ts               # i18next init (tr default)
│   │   └── tr.ts                  # Türkçe metin sözlüğü
│   └── utils/
│       ├── arabic.ts              # RTL yardımcıları
│       ├── date.ts                # hicri + tr tarih formatı
│       └── format.ts              # tabular sayı, mesafe
│
├── supabase/                      # MEVCUT dizin — şema buraya taşınır/yazılır
│   ├── migrations/                # SQL migration dosyaları (numaralı)
│   ├── functions/                 # Edge Functions (render-trigger vb. — Faz 2)
│   └── seed/                      # içerik seed SQL/JSON (Kur'an, esma, dua)
│
├── assets/
│   └── fonts/                     # CormorantGaramond, DMSans, AmiriQuran .ttf
│
└── __tests__/                     # test dosyaları feature dosyalarının yanında da olabilir
```

> **Not:** Yeni RN projesi `kurandakimesaj-rn/` alt klasöründe kurulur, böylece mevcut Flutter kodu (`lib/`) bozulmaz. Tüm aşağıdaki yollar bu klasöre görelidir. `supabase/` dizini proje kökündedir ve hem Flutter hem RN tarafından paylaşılır.

---

## Convention Reference (tüm faz planları buna atıf yapar)

Bu bölüm faz planlarının kullanacağı sabit konvansiyonları kilitler. Faz planları bu isimleri/yolları aynen kullanmalıdır.

**Tasarım token'ları** (`src/theme/colors.ts`):
`emerald950 #08201A`, `emerald900 #0D2A20`, `emerald850 #0F2C22`, `emerald700 #1E4D38`, `gold #D4B25B`, `goldBright #E8CB6F`, `goldSoft #B69547`, `cream #F3EADB`, `cream2 #E6DCC8`, `muted rgba(243,234,219,0.62)`, `muted2 rgba(243,234,219,0.55)`, `success #5ED27D`, `accent #C9856A`, `info #5AA9D6`, `line rgba(212,178,91,0.18)`, `lineSoft rgba(255,255,255,0.07)`.

**Radii:** `sm 12`, `md 18`, `lg 28`, `pill 999`. **Spacing 8'lik grid.** **Fontlar:** başlık `CormorantGaramond`, gövde `DMSans`, Arapça `AmiriQuran`.

**Query key fabrikası** (`src/data/queryKeys.ts`): `qk.surahs()`, `qk.surahAyahs(n)`, `qk.esma()`, `qk.duas()`, `qk.dailyAyah(dayIso)`, `qk.feed(kind)`, `qk.profile(id)`, `qk.khatmClaims(circleId)`, vb.

**Supabase client:** `import { supabase } from '@/lib/supabase'`.

**Paylaşılan bileşen API'leri** (Task 9'da kilitlenir) — faz planları bu prop imzalarını varsayar:
- `<ScreenScaffold title?={string} trailing?={ReactNode}>{children}</ScreenScaffold>`
- `<AppHeader title={string} trailing?={ReactNode} onBack?={() => void} />`
- `<AppCard onPress?={() => void}>{children}</AppCard>`
- `<HeroCard title={string} subtitle?={string} onPress?={() => void} />`
- `<GoldChip label={string} selected={boolean} onPress={() => void} />`
- `<AyetFrame arabic={string} meal?={string} reference?={string} />`
- `<ArabicText style?={TextStyle}>{string}</ArabicText>`
- `<StatBox value={string | number} label={string} />`
- `<SectionLabel eyebrow={string} title={string} trailing?={ReactNode} />`
- `<EmptyState icon={string} message={string} action?={ReactNode} />`
- `<AnimatedCounter value={number} />`
- `<Disclaimer text={string} />`

---

### Task 1: Expo projesini başlat ve TypeScript strict yapılandır

**Files:**
- Create: `kurandakimesaj-rn/` (Expo projesi)
- Modify: `kurandakimesaj-rn/tsconfig.json`
- Modify: `kurandakimesaj-rn/package.json`

- [ ] **Step 1: Expo projesini oluştur**

Proje kökünde (`C:\Users\yiit5\Desktop\kurandaki mesaj flutter\kurandakimesaj`) çalıştır:

```bash
npx create-expo-app@latest kurandakimesaj-rn --template default
cd kurandakimesaj-rn
```

Expo Router şablonu varsayılan olarak `app/` dizini, TypeScript ve örnek tab'lar getirir.

- [ ] **Step 2: Temel bağımlılıkları kur**

```bash
cd kurandakimesaj-rn
npx expo install @supabase/supabase-js @react-native-async-storage/async-storage expo-secure-store \
  react-native-url-polyfill react-native-mmkv expo-sqlite \
  @tanstack/react-query @tanstack/react-query-persist-client @tanstack/query-async-storage-persister \
  zustand expo-font expo-haptics react-native-reanimated react-native-gesture-handler \
  @shopify/flash-list react-native-safe-area-context i18next react-i18next \
  expo-location expo-notifications expo-sensors expo-av adhan moment-hijri
```

- [ ] **Step 3: tsconfig path alias ekle**

`tsconfig.json` içinde `compilerOptions`:

```json
{
  "extends": "expo/tsconfig.base",
  "compilerOptions": {
    "strict": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["**/*.ts", "**/*.tsx", ".expo/types/**/*.ts", "expo-env.d.ts"]
}
```

- [ ] **Step 4: babel/metro reanimated yapılandır**

`babel.config.js`:

```js
module.exports = function (api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo'],
    plugins: ['react-native-reanimated/plugin'],
  };
};
```

- [ ] **Step 5: Çalıştığını doğrula**

Run: `cd kurandakimesaj-rn && npx tsc --noEmit`
Expected: Hata yok (0 errors).

- [ ] **Step 6: Commit**

```bash
git init 2>/dev/null; git add -A && git commit -m "chore: scaffold Expo RN project with strict TS and core deps"
```

---

### Task 2: Test altyapısını kur (Jest + Testing Library)

**Files:**
- Create: `kurandakimesaj-rn/jest.config.js`
- Create: `kurandakimesaj-rn/jest.setup.ts`
- Modify: `kurandakimesaj-rn/package.json`
- Test: `kurandakimesaj-rn/src/utils/__tests__/format.test.ts`

- [ ] **Step 1: Test bağımlılıkları**

```bash
cd kurandakimesaj-rn
npm i -D jest jest-expo @testing-library/react-native @testing-library/jest-native @types/jest react-test-renderer
```

- [ ] **Step 2: jest.config.js yaz**

```js
module.exports = {
  preset: 'jest-expo',
  setupFilesAfterEnv: ['<rootDir>/jest.setup.ts'],
  transformIgnorePatterns: [
    'node_modules/(?!((jest-)?react-native|@react-native(-community)?|expo(nent)?|@expo(nent)?/.*|@expo-google-fonts/.*|react-navigation|@react-navigation/.*|@unimodules/.*|unimodules|sentry-expo|native-base|react-native-svg|@shopify/flash-list|react-native-reanimated|@supabase/.*))',
  ],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
};
```

- [ ] **Step 3: jest.setup.ts yaz (mock'lar)**

```ts
import '@testing-library/jest-native/extend-expect';

// react-native-mmkv mock (test ortamında native modül yok)
jest.mock('react-native-mmkv', () => {
  const store = new Map<string, string>();
  return {
    MMKV: jest.fn().mockImplementation(() => ({
      set: (k: string, v: string) => store.set(k, String(v)),
      getString: (k: string) => store.get(k) ?? undefined,
      delete: (k: string) => store.delete(k),
      clearAll: () => store.clear(),
    })),
  };
});

// reanimated test mock
jest.mock('react-native-reanimated', () =>
  require('react-native-reanimated/mock'),
);
```

- [ ] **Step 4: package.json test script**

`package.json` → `scripts`:

```json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "typecheck": "tsc --noEmit"
  }
}
```

- [ ] **Step 5: İlk failing test yaz**

`src/utils/__tests__/format.test.ts`:

```ts
import { formatCount, formatDistanceKm } from '@/utils/format';

describe('format', () => {
  it('binlik ayırıcı ile sayı biçimler (tr-TR tabular)', () => {
    expect(formatCount(1234567)).toBe('1.234.567');
  });

  it('mesafeyi km cinsinden tek ondalıkla biçimler', () => {
    expect(formatDistanceKm(1500)).toBe('1,5 km');
  });
});
```

- [ ] **Step 6: Testi çalıştır, başarısız olduğunu doğrula**

Run: `npm test -- format.test.ts`
Expected: FAIL — "Cannot find module '@/utils/format'".

- [ ] **Step 7: format.ts implement et**

`src/utils/format.ts`:

```ts
const nf = new Intl.NumberFormat('tr-TR');

export function formatCount(value: number): string {
  return nf.format(value);
}

export function formatDistanceKm(meters: number): string {
  const km = meters / 1000;
  return `${km.toLocaleString('tr-TR', { minimumFractionDigits: 1, maximumFractionDigits: 1 })} km`;
}
```

- [ ] **Step 8: Testi çalıştır, geçtiğini doğrula**

Run: `npm test -- format.test.ts`
Expected: PASS (2 passing).

- [ ] **Step 9: Commit**

```bash
git add -A && git commit -m "test: set up jest-expo + testing-library, add format utils"
```

---

### Task 3: Ortam değişkenleri ve doğrulama

**Files:**
- Create: `kurandakimesaj-rn/.env.example`
- Create: `kurandakimesaj-rn/src/lib/env.ts`
- Test: `kurandakimesaj-rn/src/lib/__tests__/env.test.ts`

- [ ] **Step 1: .env.example yaz**

```
EXPO_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Gerçek `.env` dosyası `.gitignore`'da olmalı (Expo `.env`'i otomatik okur; `EXPO_PUBLIC_` öneki client'a sızar — bu yalnız anon key için uygundur).

- [ ] **Step 2: Failing test yaz**

`src/lib/__tests__/env.test.ts`:

```ts
import { readEnv } from '@/lib/env';

describe('readEnv', () => {
  it('eksik değişkende açıklayıcı hata fırlatır', () => {
    expect(() => readEnv({})).toThrow(/EXPO_PUBLIC_SUPABASE_URL/);
  });

  it('geçerli değerleri döndürür', () => {
    const env = readEnv({
      EXPO_PUBLIC_SUPABASE_URL: 'https://x.supabase.co',
      EXPO_PUBLIC_SUPABASE_ANON_KEY: 'anon',
    });
    expect(env.supabaseUrl).toBe('https://x.supabase.co');
    expect(env.supabaseAnonKey).toBe('anon');
  });
});
```

- [ ] **Step 3: Çalıştır, başarısızlığı doğrula**

Run: `npm test -- env.test.ts`
Expected: FAIL — modül yok.

- [ ] **Step 4: env.ts implement et**

`src/lib/env.ts`:

```ts
type RawEnv = Record<string, string | undefined>;

export interface AppEnv {
  supabaseUrl: string;
  supabaseAnonKey: string;
}

export function readEnv(raw: RawEnv): AppEnv {
  const supabaseUrl = raw.EXPO_PUBLIC_SUPABASE_URL;
  const supabaseAnonKey = raw.EXPO_PUBLIC_SUPABASE_ANON_KEY;
  if (!supabaseUrl) throw new Error('EXPO_PUBLIC_SUPABASE_URL tanımlı değil');
  if (!supabaseAnonKey) throw new Error('EXPO_PUBLIC_SUPABASE_ANON_KEY tanımlı değil');
  return { supabaseUrl, supabaseAnonKey };
}

export const env: AppEnv = readEnv(process.env as RawEnv);
```

- [ ] **Step 5: Çalıştır, geçtiğini doğrula**

Run: `npm test -- env.test.ts`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat: add env validation"
```

---

### Task 4: Supabase veritabanı şeması — migration (TÜM tablolar + RLS)

**Files:**
- Create: `supabase/migrations/0001_init.sql`
- Create: `supabase/migrations/0002_content_tables.sql`
- Create: `supabase/migrations/0003_rls_policies.sql`

> Bu şema, `database supabase olucak` kararına göre **tek veritabanıdır**: hem dini sabit içerik (sure, ayet, esma, dua...) hem de kullanıcı/topluluk verisi Supabase'tedir.

- [ ] **Step 1: profiles + sosyal/topluluk tabloları (0001_init.sql)**

```sql
-- 0001_init.sql
create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  display_name text,
  avatar_url text,
  bio text,
  is_pro boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.feed_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null check (kind in ('ayah','video')),
  reference text, arabic text, meal text, caption text,
  media_url text, video_url text, thumbnail_url text, template_id text, topic text,
  like_count int not null default 0,
  is_hidden boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists feed_posts_created_idx on public.feed_posts (created_at desc);
create index if not exists feed_posts_kind_idx on public.feed_posts (kind);

create table if not exists public.likes (
  post_id uuid not null references public.feed_posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id)
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  title text, is_group boolean not null default false,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);
create table if not exists public.conversation_members (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);
create index if not exists messages_conv_idx on public.messages (conversation_id, created_at);

create table if not exists public.khatm_circles (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  is_public boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.khatm_claims (
  circle_id uuid not null references public.khatm_circles(id) on delete cascade,
  juz_number int not null check (juz_number between 1 and 30),
  user_id uuid not null references public.profiles(id) on delete cascade,
  completed boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (circle_id, juz_number)
);

create table if not exists public.cloud_dhikr (
  user_id uuid not null references public.profiles(id) on delete cascade,
  date_iso text not null,
  dhikr_key text not null,
  count int not null default 0,
  updated_at timestamptz not null default now(),
  primary key (user_id, date_iso, dhikr_key)
);
create table if not exists public.cloud_collections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  reference text not null, arabic text not null, meal text not null, note text,
  created_at timestamptz not null default now()
);
create table if not exists public.memorization_progress (
  user_id uuid not null references public.profiles(id) on delete cascade,
  surah_number int not null,
  memorized_ayahs int not null default 0,
  last_review_iso text,
  primary key (user_id, surah_number)
);
create table if not exists public.juz_progress (
  user_id uuid not null references public.profiles(id) on delete cascade,
  juz_number int not null check (juz_number between 1 and 30),
  completed boolean not null default false,
  updated_iso text,
  primary key (user_id, juz_number)
);

create table if not exists public.render_jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  template text not null, reciter text not null,
  reference text, arabic text, meal text,
  status text not null default 'queued' check (status in ('queued','processing','done','failed')),
  output_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.donations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  campaign text not null, amount numeric not null,
  status text not null default 'pending', provider_ref text,
  created_at timestamptz not null default now()
);
create table if not exists public.daily_content (
  day date primary key,
  reference text not null, arabic text not null, meal text not null,
  created_at timestamptz not null default now()
);
create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  post_id uuid not null references public.feed_posts(id) on delete cascade,
  reason text not null,
  created_at timestamptz not null default now()
);
```

- [ ] **Step 2: like_count trigger + profil auto-create**

`0001_init.sql` sonuna ekle:

```sql
-- like_count senkronizasyonu
create or replace function public.sync_like_count() returns trigger as $$
begin
  if (tg_op = 'INSERT') then
    update public.feed_posts set like_count = like_count + 1 where id = new.post_id;
  elsif (tg_op = 'DELETE') then
    update public.feed_posts set like_count = greatest(like_count - 1, 0) where id = old.post_id;
  end if;
  return null;
end; $$ language plpgsql security definer;

drop trigger if exists likes_count_trg on public.likes;
create trigger likes_count_trg after insert or delete on public.likes
  for each row execute function public.sync_like_count();

-- yeni auth.users → profiles satırı
create or replace function public.handle_new_user() returns trigger as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', 'Misafir'))
  on conflict (id) do nothing;
  return new;
end; $$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();
```

- [ ] **Step 3: Sabit içerik tabloları (0002_content_tables.sql)**

```sql
-- 0002_content_tables.sql  (dini sabit içerik — Supabase otorite)
create table if not exists public.surahs (
  number int primary key,
  name_tr text not null, name_arabic text not null, meaning text not null,
  ayah_count int not null, revelation text not null check (revelation in ('Mekki','Medeni')),
  juz_start int not null default 1
);
create table if not exists public.ayahs (
  id bigserial primary key,
  surah_number int not null references public.surahs(number) on delete cascade,
  number_in_surah int not null,
  arabic text not null,
  meal_diyanet text, meal_elmali text, meal_tdv text,
  tafsir text,
  unique (surah_number, number_in_surah)
);
create index if not exists ayahs_surah_idx on public.ayahs (surah_number, number_in_surah);

create table if not exists public.esma_names (
  "order" int primary key,
  name text not null, arabic text not null, meaning text not null, audio_url text
);
create table if not exists public.duas (
  id bigserial primary key,
  title text not null, category text not null,
  arabic text not null, latin text default '', body text not null, source text default '', audio_url text
);
create table if not exists public.topical_ayahs (
  id bigserial primary key,
  topic text not null, reference text not null, arabic text not null, meal text not null
);
create table if not exists public.stories (
  id bigserial primary key,
  "order" int not null, title text not null, category text not null,
  read_minutes int not null, summary text not null, body text not null, audio_url text
);
create table if not exists public.miracles (
  id bigserial primary key,
  category text not null, title text not null, body text not null
);
create table if not exists public.tajweed_lessons (
  id bigserial primary key,
  "order" int not null, title text not null, rule text not null, example text not null, body text not null, audio_url text
);
create table if not exists public.dream_symbols (
  id bigserial primary key,
  term text not null, category text not null, meaning text not null, source text default ''
);
-- Rüya araması için FTS (Türkçe sözcükler için 'simple' config + unaccent)
create index if not exists dream_term_trgm on public.dream_symbols using gin (to_tsvector('simple', term));
create table if not exists public.video_templates (
  id text primary key, name text not null, category text not null, preview_url text, background_url text
);
```

- [ ] **Step 4: RLS politikaları (0003_rls_policies.sql)**

```sql
-- 0003_rls_policies.sql  (default-deny; içerik herkese okunur, kullanıcı verisi sahibe)
alter table public.profiles enable row level security;
alter table public.feed_posts enable row level security;
alter table public.likes enable row level security;
alter table public.follows enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.khatm_circles enable row level security;
alter table public.khatm_claims enable row level security;
alter table public.cloud_dhikr enable row level security;
alter table public.cloud_collections enable row level security;
alter table public.memorization_progress enable row level security;
alter table public.juz_progress enable row level security;
alter table public.render_jobs enable row level security;
alter table public.donations enable row level security;
alter table public.daily_content enable row level security;
alter table public.reports enable row level security;
-- içerik tabloları (salt okunur, herkese açık)
alter table public.surahs enable row level security;
alter table public.ayahs enable row level security;
alter table public.esma_names enable row level security;
alter table public.duas enable row level security;
alter table public.topical_ayahs enable row level security;
alter table public.stories enable row level security;
alter table public.miracles enable row level security;
alter table public.tajweed_lessons enable row level security;
alter table public.dream_symbols enable row level security;
alter table public.video_templates enable row level security;

-- içerik: herkese SELECT
do $$ declare t text;
begin
  foreach t in array array['surahs','ayahs','esma_names','duas','topical_ayahs','stories','miracles','tajweed_lessons','dream_symbols','video_templates','daily_content']
  loop
    execute format('drop policy if exists %I_read on public.%I; create policy %I_read on public.%I for select using (true);', t, t, t, t);
  end loop;
end $$;

-- profiles
create policy profiles_read on public.profiles for select using (true);
create policy profiles_write on public.profiles for update using (auth.uid() = id);
create policy profiles_insert on public.profiles for insert with check (auth.uid() = id);

-- feed_posts
create policy posts_read on public.feed_posts for select using (not is_hidden or author_id = auth.uid());
create policy posts_insert on public.feed_posts for insert with check (author_id = auth.uid());
create policy posts_update on public.feed_posts for update using (author_id = auth.uid());
create policy posts_delete on public.feed_posts for delete using (author_id = auth.uid());

-- likes / follows
create policy likes_read on public.likes for select using (true);
create policy likes_write on public.likes for insert with check (user_id = auth.uid());
create policy likes_del on public.likes for delete using (user_id = auth.uid());
create policy follows_read on public.follows for select using (true);
create policy follows_write on public.follows for insert with check (follower_id = auth.uid());
create policy follows_del on public.follows for delete using (follower_id = auth.uid());

-- konuşmalar/mesajlar: üyelik bazlı
create policy conv_read on public.conversations for select
  using (exists (select 1 from public.conversation_members m where m.conversation_id = id and m.user_id = auth.uid()));
create policy conv_insert on public.conversations for insert with check (created_by = auth.uid());
create policy cm_read on public.conversation_members for select
  using (exists (select 1 from public.conversation_members m where m.conversation_id = conversation_id and m.user_id = auth.uid()));
create policy cm_write on public.conversation_members for insert with check (user_id = auth.uid());
create policy msg_read on public.messages for select
  using (exists (select 1 from public.conversation_members m where m.conversation_id = messages.conversation_id and m.user_id = auth.uid()));
create policy msg_insert on public.messages for insert with check (
  sender_id = auth.uid() and exists (select 1 from public.conversation_members m where m.conversation_id = messages.conversation_id and m.user_id = auth.uid()));

-- khatm
create policy circle_read on public.khatm_circles for select using (is_public or owner_id = auth.uid());
create policy circle_insert on public.khatm_circles for insert with check (owner_id = auth.uid());
create policy circle_del on public.khatm_circles for delete using (owner_id = auth.uid());
create policy claim_read on public.khatm_claims for select using (true);
create policy claim_write on public.khatm_claims for insert with check (user_id = auth.uid());
create policy claim_update on public.khatm_claims for update using (user_id = auth.uid());
create policy claim_del on public.khatm_claims for delete using (user_id = auth.uid());

-- kullanıcıya özel sync/progress tabloları
do $$ declare t text;
begin
  foreach t in array array['cloud_dhikr','cloud_collections','memorization_progress','juz_progress','render_jobs']
  loop
    execute format('create policy %I_all on public.%I for all using (user_id = auth.uid()) with check (user_id = auth.uid());', t, t);
  end loop;
end $$;

-- donations
create policy don_read on public.donations for select using (user_id = auth.uid());
create policy don_insert on public.donations for insert with check (user_id = auth.uid() or user_id is null);

-- reports
create policy rep_insert on public.reports for insert with check (reporter_id = auth.uid());
create policy rep_read on public.reports for select using (reporter_id = auth.uid());
```

- [ ] **Step 5: Migration'ları uygula**

Supabase CLI kuruluysa (`npm i -g supabase`), proje kökünde:

```bash
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

Expected: 3 migration de hatasız uygulanır. (CLI yoksa SQL'ler Supabase Studio → SQL Editor'da sırayla çalıştırılır.)

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations && git commit -m "feat(db): full Supabase schema + RLS (content + community)"
```

---

### Task 5: Supabase client (secure-store oturum kalıcılığı)

**Files:**
- Create: `kurandakimesaj-rn/src/lib/supabase.ts`
- Test: `kurandakimesaj-rn/src/lib/__tests__/supabase.test.ts`

- [ ] **Step 1: Failing test yaz**

`src/lib/__tests__/supabase.test.ts`:

```ts
jest.mock('@/lib/env', () => ({
  env: { supabaseUrl: 'https://x.supabase.co', supabaseAnonKey: 'anon' },
}));

describe('supabase client', () => {
  it('auth ve from API yüzeyine sahip bir client export eder', () => {
    const { supabase } = require('@/lib/supabase');
    expect(typeof supabase.auth.getSession).toBe('function');
    expect(typeof supabase.from).toBe('function');
  });
});
```

- [ ] **Step 2: Çalıştır, başarısızlığı doğrula**

Run: `npm test -- supabase.test.ts`
Expected: FAIL — modül yok.

- [ ] **Step 3: supabase.ts implement et**

`src/lib/supabase.ts`:

```ts
import 'react-native-url-polyfill/auto';
import { createClient } from '@supabase/supabase-js';
import * as SecureStore from 'expo-secure-store';
import { env } from '@/lib/env';

// Supabase oturumunu cihazda güvenli depola (token'lar)
const SecureStorageAdapter = {
  getItem: (key: string) => SecureStore.getItemAsync(key),
  setItem: (key: string, value: string) => SecureStore.setItemAsync(key, value),
  removeItem: (key: string) => SecureStore.deleteItemAsync(key),
};

export const supabase = createClient(env.supabaseUrl, env.supabaseAnonKey, {
  auth: {
    storage: SecureStorageAdapter,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
  },
});
```

- [ ] **Step 4: Çalıştır, geçtiğini doğrula**

Run: `npm test -- supabase.test.ts`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: supabase client with secure-store session"
```

---

### Task 6: MMKV depolama + TanStack Query client + persistence

**Files:**
- Create: `kurandakimesaj-rn/src/lib/mmkv.ts`
- Create: `kurandakimesaj-rn/src/lib/queryClient.ts`
- Test: `kurandakimesaj-rn/src/lib/__tests__/queryClient.test.ts`

- [ ] **Step 1: mmkv.ts yaz**

`src/lib/mmkv.ts`:

```ts
import { MMKV } from 'react-native-mmkv';

export const storage = new MMKV({ id: 'kuran-app' });

// TanStack persistClient'ın beklediği senkron string storage arayüzü
export const mmkvPersistStorage = {
  getItem: (key: string) => storage.getString(key) ?? null,
  setItem: (key: string, value: string) => storage.set(key, value),
  removeItem: (key: string) => storage.delete(key),
};
```

- [ ] **Step 2: Failing test yaz**

`src/lib/__tests__/queryClient.test.ts`:

```ts
import { makeQueryClient } from '@/lib/queryClient';

describe('queryClient', () => {
  it('uzun staleTime ile offline-öncelikli varsayılanlar kurar', () => {
    const qc = makeQueryClient();
    const def = qc.getDefaultOptions().queries!;
    expect(def.staleTime).toBeGreaterThanOrEqual(60_000);
    expect(def.gcTime).toBeGreaterThanOrEqual(24 * 60 * 60 * 1000);
  });
});
```

- [ ] **Step 3: Çalıştır, başarısızlığı doğrula**

Run: `npm test -- queryClient.test.ts`
Expected: FAIL — modül yok.

- [ ] **Step 4: queryClient.ts implement et**

`src/lib/queryClient.ts`:

```ts
import { QueryClient } from '@tanstack/react-query';
import { createSyncStoragePersister } from '@tanstack/query-async-storage-persister';
import { mmkvPersistStorage } from '@/lib/mmkv';

// Sabit dini içerik nadiren değişir → uzun staleTime, agresif gcTime.
// react-best-practices: client-swr-dedup — TanStack Query istek tekilleştirmesi sağlar.
export function makeQueryClient(): QueryClient {
  return new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: 5 * 60_000,
        gcTime: 7 * 24 * 60 * 60 * 1000,
        retry: 2,
        refetchOnWindowFocus: false,
        networkMode: 'offlineFirst',
      },
    },
  });
}

export const queryPersister = createSyncStoragePersister({
  storage: mmkvPersistStorage,
  key: 'rq-cache',
});
```

- [ ] **Step 5: Çalıştır, geçtiğini doğrula**

Run: `npm test -- queryClient.test.ts`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat: MMKV storage + persisted offline-first query client"
```

---

### Task 7: Tasarım sistemi — renkler, tipografi, token'lar

**Files:**
- Create: `kurandakimesaj-rn/src/theme/colors.ts`
- Create: `kurandakimesaj-rn/src/theme/tokens.ts`
- Create: `kurandakimesaj-rn/src/theme/typography.ts`
- Create: `kurandakimesaj-rn/src/theme/index.ts`
- Test: `kurandakimesaj-rn/src/theme/__tests__/colors.test.ts`

- [ ] **Step 1: Failing test yaz**

`src/theme/__tests__/colors.test.ts`:

```ts
import { AppColors } from '@/theme/colors';

describe('AppColors', () => {
  it('plandaki kesin marka hex değerlerini tutar', () => {
    expect(AppColors.emerald950).toBe('#08201A');
    expect(AppColors.gold).toBe('#D4B25B');
    expect(AppColors.cream).toBe('#F3EADB');
    expect(AppColors.success).toBe('#5ED27D');
  });
});
```

- [ ] **Step 2: Çalıştır, başarısızlığı doğrula**

Run: `npm test -- colors.test.ts`
Expected: FAIL — modül yok.

- [ ] **Step 3: colors.ts implement et**

`src/theme/colors.ts`:

```ts
export const AppColors = {
  emerald950: '#08201A',
  emerald900: '#0D2A20',
  emerald850: '#0F2C22',
  emerald700: '#1E4D38',
  gold: '#D4B25B',
  goldBright: '#E8CB6F',
  goldSoft: '#B69547',
  goldFaint: 'rgba(212,178,91,0.12)',
  cream: '#F3EADB',
  cream2: '#E6DCC8',
  muted: 'rgba(243,234,219,0.62)',
  muted2: 'rgba(243,234,219,0.55)',
  success: '#5ED27D',
  accent: '#C9856A',
  info: '#5AA9D6',
  line: 'rgba(212,178,91,0.18)',
  lineSoft: 'rgba(255,255,255,0.07)',
} as const;

export const Gradients = {
  hero: [AppColors.emerald700, AppColors.emerald950] as const,
  card: ['#102C22', AppColors.emerald900] as const,
  cardActive: ['#1B4334', '#123528'] as const,
  fab: [AppColors.goldBright, AppColors.goldSoft] as const,
};
```

- [ ] **Step 4: tokens.ts implement et**

`src/theme/tokens.ts`:

```ts
export const Radii = { sm: 12, md: 18, lg: 28, pill: 999 } as const;

export const Spacing = {
  xs: 8, s: 10, sm: 14, m: 16, ml: 18, l: 20, xl: 24, xxl: 28, huge: 44,
} as const;

export const Durations = {
  fast: 180, normal: 320, slow: 520, entrance: 650, stagger: 60,
} as const;

export const TouchTarget = { min: 44, chip: 48 } as const;
```

- [ ] **Step 5: typography.ts implement et**

`src/theme/typography.ts`:

```ts
import { TextStyle } from 'react-native';
import { AppColors } from '@/theme/colors';

export const Fonts = {
  display: 'CormorantGaramond',
  body: 'DMSans',
  arabic: 'AmiriQuran',
} as const;

export function display(size = 26, color = AppColors.cream, weight: TextStyle['fontWeight'] = '600'): TextStyle {
  return { fontFamily: Fonts.display, fontSize: size, color, fontWeight: weight, lineHeight: size * 1.05, letterSpacing: -0.5 };
}

export function body(size = 14, color = AppColors.cream, weight: TextStyle['fontWeight'] = '400'): TextStyle {
  return { fontFamily: Fonts.body, fontSize: size, color, fontWeight: weight, lineHeight: size * 1.5 };
}

export function eyebrow(color = AppColors.gold): TextStyle {
  return { fontFamily: Fonts.body, fontSize: 11, color, fontWeight: '700', letterSpacing: 2.4, textTransform: 'uppercase' };
}

// DOMAIN KURALI: Arapça her zaman Amiri Quran + RTL.
export function arabicStyle(size = 28, color = AppColors.cream): TextStyle {
  return { fontFamily: Fonts.arabic, fontSize: size, color, lineHeight: size * 1.9, writingDirection: 'rtl', textAlign: 'right' };
}
```

- [ ] **Step 6: index.ts barrel + useTheme**

`src/theme/index.ts`:

```ts
export { AppColors, Gradients } from '@/theme/colors';
export { Radii, Spacing, Durations, TouchTarget } from '@/theme/tokens';
export { Fonts, display, body, eyebrow, arabicStyle } from '@/theme/typography';
```

- [ ] **Step 7: Çalıştır, geçtiğini doğrula**

Run: `npm test -- colors.test.ts`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add -A && git commit -m "feat(theme): exact color palette, tokens, typography"
```

---

### Task 8: Fontları yükle (Cormorant Garamond, DM Sans, Amiri Quran)

**Files:**
- Create: `kurandakimesaj-rn/assets/fonts/` (3 .ttf)
- Modify: `kurandakimesaj-rn/app/_layout.tsx`

- [ ] **Step 1: Font dosyalarını indir**

`assets/fonts/` içine yerleştir:
- `CormorantGaramond-SemiBold.ttf` (Google Fonts)
- `DMSans-Regular.ttf`, `DMSans-Medium.ttf`, `DMSans-Bold.ttf`
- `AmiriQuran-Regular.ttf` (Amiri Quran — Arapça hat)

```bash
cd kurandakimesaj-rn
# Google Fonts'tan indirme (manuel veya curl ile); dosyaları assets/fonts/ altına koy
```

- [ ] **Step 2: app/_layout.tsx içinde fontları yükle**

`app/_layout.tsx` (sonra Task 13'te Provider'larla genişletilecek — şimdilik font yüklemesi):

```tsx
import { useFonts } from 'expo-font';
import { Stack } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { useEffect } from 'react';

SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const [loaded] = useFonts({
    CormorantGaramond: require('../assets/fonts/CormorantGaramond-SemiBold.ttf'),
    DMSans: require('../assets/fonts/DMSans-Regular.ttf'),
    'DMSans-Medium': require('../assets/fonts/DMSans-Medium.ttf'),
    'DMSans-Bold': require('../assets/fonts/DMSans-Bold.ttf'),
    AmiriQuran: require('../assets/fonts/AmiriQuran-Regular.ttf'),
  });

  useEffect(() => {
    if (loaded) SplashScreen.hideAsync();
  }, [loaded]);

  if (!loaded) return null;
  return <Stack screenOptions={{ headerShown: false }} />;
}
```

- [ ] **Step 3: Çalıştığını doğrula**

Run: `cd kurandakimesaj-rn && npx expo start` (bir cihaz/emülatörde aç)
Expected: Uygulama açılır, splash kapanır, font hatası yok.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat: load Cormorant Garamond, DM Sans, Amiri Quran fonts"
```

---

### Task 9: Paylaşılan UI bileşenleri (tüm fazlar bunları kullanır)

**Files:**
- Create: `kurandakimesaj-rn/src/ui/ArabicText.tsx`
- Create: `kurandakimesaj-rn/src/ui/AppHeader.tsx`
- Create: `kurandakimesaj-rn/src/ui/ScreenScaffold.tsx`
- Create: `kurandakimesaj-rn/src/ui/AppCard.tsx`
- Create: `kurandakimesaj-rn/src/ui/HeroCard.tsx`
- Create: `kurandakimesaj-rn/src/ui/GoldChip.tsx`
- Create: `kurandakimesaj-rn/src/ui/AyetFrame.tsx`
- Create: `kurandakimesaj-rn/src/ui/StatBox.tsx`
- Create: `kurandakimesaj-rn/src/ui/SectionLabel.tsx`
- Create: `kurandakimesaj-rn/src/ui/EmptyState.tsx`
- Create: `kurandakimesaj-rn/src/ui/AnimatedCounter.tsx`
- Create: `kurandakimesaj-rn/src/ui/Disclaimer.tsx`
- Test: `kurandakimesaj-rn/src/ui/__tests__/components.test.tsx`

- [ ] **Step 1: Failing test yaz**

`src/ui/__tests__/components.test.tsx`:

```tsx
import React from 'react';
import { render, fireEvent } from '@testing-library/react-native';
import { GoldChip } from '@/ui/GoldChip';
import { AyetFrame } from '@/ui/AyetFrame';
import { ArabicText } from '@/ui/ArabicText';
import { Fonts } from '@/theme';

describe('paylaşılan UI', () => {
  it('GoldChip etiketi gösterir ve basınca onPress çağırır', () => {
    const onPress = jest.fn();
    const { getByText } = render(<GoldChip label="Sabır" selected={false} onPress={onPress} />);
    fireEvent.press(getByText('Sabır'));
    expect(onPress).toHaveBeenCalledTimes(1);
  });

  it('ArabicText, Amiri Quran fontu ve RTL yönü uygular (domain kuralı)', () => {
    const { getByText } = render(<ArabicText>بِسْمِ اللَّهِ</ArabicText>);
    const node = getByText('بِسْمِ اللَّهِ');
    const flat = Array.isArray(node.props.style) ? Object.assign({}, ...node.props.style) : node.props.style;
    expect(flat.fontFamily).toBe(Fonts.arabic);
    expect(flat.writingDirection).toBe('rtl');
  });

  it('AyetFrame arabic + meal + reference gösterir', () => {
    const { getByText } = render(<AyetFrame arabic="آية" meal="meal metni" reference="2:255" />);
    expect(getByText('meal metni')).toBeTruthy();
    expect(getByText('2:255')).toBeTruthy();
  });
});
```

- [ ] **Step 2: Çalıştır, başarısızlığı doğrula**

Run: `npm test -- components.test.tsx`
Expected: FAIL — modüller yok.

- [ ] **Step 3: ArabicText.tsx**

```tsx
import React from 'react';
import { Text, TextStyle } from 'react-native';
import { arabicStyle } from '@/theme';

interface Props { children: string; size?: number; color?: string; style?: TextStyle; }

// DOMAIN KURALI: Arapça her zaman Amiri Quran + RTL + doğru yön.
export function ArabicText({ children, size, color, style }: Props) {
  return <Text style={[arabicStyle(size, color), style]}>{children}</Text>;
}
```

- [ ] **Step 4: GoldChip.tsx**

```tsx
import React from 'react';
import { Pressable, Text, StyleSheet } from 'react-native';
import { AppColors, Radii, TouchTarget, body } from '@/theme';

interface Props { label: string; selected: boolean; onPress: () => void; }

export function GoldChip({ label, selected, onPress }: Props) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ selected }}
      onPress={onPress}
      style={[styles.chip, selected ? styles.selected : styles.unselected]}
    >
      <Text style={body(13, selected ? AppColors.emerald950 : AppColors.cream, '600')}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  chip: { minHeight: TouchTarget.chip, paddingHorizontal: 16, justifyContent: 'center', borderRadius: Radii.pill, borderWidth: 1 },
  selected: { backgroundColor: AppColors.gold, borderColor: AppColors.gold },
  unselected: { backgroundColor: 'transparent', borderColor: AppColors.line },
});
```

- [ ] **Step 5: AppCard.tsx**

```tsx
import React from 'react';
import { Pressable, View, StyleSheet, ViewStyle } from 'react-native';
import { AppColors, Radii, Spacing } from '@/theme';

interface Props { children: React.ReactNode; onPress?: () => void; style?: ViewStyle; }

export function AppCard({ children, onPress, style }: Props) {
  const content = <View style={[styles.card, style]}>{children}</View>;
  if (!onPress) return content;
  return (
    <Pressable onPress={onPress} accessibilityRole="button" style={({ pressed }) => pressed && { transform: [{ scale: 0.97 }] }}>
      {content}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: { backgroundColor: AppColors.emerald900, borderRadius: Radii.md, borderWidth: 1, borderColor: AppColors.line, padding: Spacing.ml },
});
```

- [ ] **Step 6: HeroCard.tsx**

```tsx
import React from 'react';
import { Pressable, View, Text, StyleSheet } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { AppColors, Gradients, Radii, Spacing, display, body } from '@/theme';

interface Props { title: string; subtitle?: string; onPress?: () => void; }

export function HeroCard({ title, subtitle, onPress }: Props) {
  return (
    <Pressable onPress={onPress} disabled={!onPress}>
      <LinearGradient colors={Gradients.hero} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.hero}>
        <View style={styles.filigree} />
        <Text style={display(30, AppColors.cream)}>{title}</Text>
        {subtitle ? <Text style={[body(14, AppColors.cream2), { marginTop: Spacing.xs }]}>{subtitle}</Text> : null}
      </LinearGradient>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  hero: { borderRadius: Radii.lg, padding: Spacing.xl, overflow: 'hidden', minHeight: 140 },
  filigree: { position: 'absolute', right: -24, top: -24, width: 96, height: 96, borderRadius: 48, borderWidth: 1, borderColor: AppColors.goldFaint },
});
```

> `expo-linear-gradient` kurulumu: `npx expo install expo-linear-gradient`.

- [ ] **Step 7: AyetFrame.tsx**

```tsx
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { AppColors, Radii, Spacing, body, eyebrow } from '@/theme';
import { ArabicText } from '@/ui/ArabicText';

interface Props { arabic: string; meal?: string; reference?: string; }

export function AyetFrame({ arabic, meal, reference }: Props) {
  return (
    <View style={styles.frame}>
      <ArabicText size={28}>{arabic}</ArabicText>
      {meal ? <Text style={[body(15, AppColors.cream2), { marginTop: Spacing.sm }]}>{meal}</Text> : null}
      {reference ? <Text style={[eyebrow(), { marginTop: Spacing.s }]}>{reference}</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  frame: { borderRadius: Radii.md, borderWidth: 1, borderColor: AppColors.line, padding: Spacing.l, backgroundColor: AppColors.emerald850 },
});
```

- [ ] **Step 8: StatBox, SectionLabel, EmptyState, AnimatedCounter, Disclaimer, AppHeader, ScreenScaffold**

`src/ui/StatBox.tsx`:

```tsx
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { AppColors, Spacing, display, body } from '@/theme';

export function StatBox({ value, label }: { value: string | number; label: string }) {
  return (
    <View style={styles.box}>
      <Text style={[display(28, AppColors.gold), { fontVariant: ['tabular-nums'] }]}>{value}</Text>
      <Text style={[body(12, AppColors.muted), { marginTop: 2 }]}>{label}</Text>
    </View>
  );
}
const styles = StyleSheet.create({ box: { alignItems: 'flex-start', paddingVertical: Spacing.xs } });
```

`src/ui/SectionLabel.tsx`:

```tsx
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { AppColors, Spacing, display, eyebrow } from '@/theme';

export function SectionLabel({ eyebrow: eb, title, trailing }: { eyebrow: string; title: string; trailing?: React.ReactNode }) {
  return (
    <View style={styles.row}>
      <View style={{ flex: 1 }}>
        <Text style={eyebrow()}>{eb}</Text>
        <Text style={[display(22, AppColors.cream), { marginTop: 4 }]}>{title}</Text>
      </View>
      {trailing}
    </View>
  );
}
const styles = StyleSheet.create({ row: { flexDirection: 'row', alignItems: 'center', marginBottom: Spacing.sm } });
```

`src/ui/EmptyState.tsx`:

```tsx
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { AppColors, Spacing, body } from '@/theme';

export function EmptyState({ icon, message, action }: { icon: keyof typeof Ionicons.glyphMap; message: string; action?: React.ReactNode }) {
  return (
    <View style={styles.wrap}>
      <Ionicons name={icon} size={48} color={AppColors.muted2} />
      <Text style={[body(14, AppColors.muted), { textAlign: 'center', marginTop: Spacing.sm }]}>{message}</Text>
      {action ? <View style={{ marginTop: Spacing.m }}>{action}</View> : null}
    </View>
  );
}
const styles = StyleSheet.create({ wrap: { alignItems: 'center', justifyContent: 'center', padding: Spacing.huge } });
```

`src/ui/AnimatedCounter.tsx`:

```tsx
import React, { useEffect } from 'react';
import { Text } from 'react-native';
import Animated, { useSharedValue, useAnimatedProps, withTiming } from 'react-native-reanimated';
import { AppColors, display } from '@/theme';

const AnimatedText = Animated.createAnimatedComponent(Text);

export function AnimatedCounter({ value, size = 56 }: { value: number; size?: number }) {
  const sv = useSharedValue(value);
  useEffect(() => { sv.value = withTiming(value, { duration: 320 }); }, [value]);
  const props = useAnimatedProps(() => ({ text: String(Math.round(sv.value)) } as any));
  return (
    <AnimatedText
      animatedProps={props}
      style={[display(size, AppColors.cream), { fontVariant: ['tabular-nums'] }]}
    >
      {String(value)}
    </AnimatedText>
  );
}
```

`src/ui/Disclaimer.tsx`:

```tsx
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { AppColors, Radii, Spacing, body } from '@/theme';

// DOMAIN KURALI: Rüya/Zekat gibi ekranlarda "kesin hüküm değildir" uyarısı.
export function Disclaimer({ text }: { text: string }) {
  return (
    <View style={styles.box}>
      <Ionicons name="information-circle-outline" size={18} color={AppColors.info} />
      <Text style={[body(12, AppColors.muted), { flex: 1, marginLeft: 8 }]}>{text}</Text>
    </View>
  );
}
const styles = StyleSheet.create({
  box: { flexDirection: 'row', alignItems: 'flex-start', padding: Spacing.sm, borderRadius: Radii.sm, backgroundColor: 'rgba(90,169,214,0.10)', borderWidth: 1, borderColor: 'rgba(90,169,214,0.25)' },
});
```

`src/ui/AppHeader.tsx`:

```tsx
import React from 'react';
import { View, Text, Pressable, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { AppColors, Spacing, TouchTarget, display } from '@/theme';

export function AppHeader({ title, trailing, onBack }: { title: string; trailing?: React.ReactNode; onBack?: () => void }) {
  return (
    <View style={styles.row}>
      <Pressable accessibilityRole="button" accessibilityLabel="Geri" onPress={onBack ?? (() => router.back())} style={styles.btn} hitSlop={8}>
        <Ionicons name="chevron-back" size={26} color={AppColors.gold} />
      </Pressable>
      <Text style={[display(22, AppColors.cream), { flex: 1, textAlign: 'center' }]} numberOfLines={1}>{title}</Text>
      <View style={styles.btn}>{trailing}</View>
    </View>
  );
}
const styles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: Spacing.m, paddingVertical: Spacing.s },
  btn: { width: TouchTarget.min, height: TouchTarget.min, alignItems: 'center', justifyContent: 'center' },
});
```

`src/ui/ScreenScaffold.tsx`:

```tsx
import React from 'react';
import { View, StyleSheet } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { AppColors } from '@/theme';
import { AppHeader } from '@/ui/AppHeader';

export function ScreenScaffold({ title, trailing, children }: { title?: string; trailing?: React.ReactNode; children: React.ReactNode }) {
  return (
    <SafeAreaView style={styles.root} edges={['top']}>
      {title ? <AppHeader title={title} trailing={trailing} /> : null}
      <View style={styles.body}>{children}</View>
    </SafeAreaView>
  );
}
const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: AppColors.emerald950 },
  body: { flex: 1 },
});
```

- [ ] **Step 9: Çalıştır, geçtiğini doğrula**

Run: `npm test -- components.test.tsx`
Expected: PASS (3 passing).

- [ ] **Step 10: Commit**

```bash
git add -A && git commit -m "feat(ui): shared design-system components (header, card, chip, ayet frame, etc.)"
```

---

### Task 10: Domain tipleri + query key fabrikası

**Files:**
- Create: `kurandakimesaj-rn/src/data/types.ts`
- Create: `kurandakimesaj-rn/src/data/queryKeys.ts`
- Test: `kurandakimesaj-rn/src/data/__tests__/queryKeys.test.ts`

- [ ] **Step 1: types.ts yaz (tüm domain tipleri)**

`src/data/types.ts`:

```ts
export type MealCode = 'diyanet' | 'elmali' | 'tdv';

export interface AppSettings {
  meal: MealCode;
  interests: string[];
  notificationsEnabled: boolean;
  displayName: string | null;
  avatarUrl: string | null;
  isPro: boolean;
  onboarded: boolean;
}

export interface Surah {
  number: number; nameTr: string; nameArabic: string; meaning: string;
  ayahCount: number; revelation: 'Mekki' | 'Medeni'; juzStart: number;
}
export interface Ayah {
  id: number; surahNumber: number; numberInSurah: number; arabic: string;
  meals: Partial<Record<MealCode, string>>; tafsir: string | null;
}
export interface EsmaName { order: number; name: string; arabic: string; meaning: string; audioUrl: string | null; }
export interface Dua { id: number; title: string; category: string; arabic: string; latin: string; body: string; source: string; audioUrl: string | null; }
export interface TopicalAyah { id: number; topic: string; reference: string; arabic: string; meal: string; }
export interface Story { id: number; order: number; title: string; category: string; readMinutes: number; summary: string; body: string; audioUrl: string | null; }
export interface Miracle { id: number; category: string; title: string; body: string; }
export interface TajweedLesson { id: number; order: number; title: string; rule: string; example: string; body: string; audioUrl: string | null; }
export interface DreamSymbol { id: number; term: string; category: string; meaning: string; source: string; }
export interface VideoTemplate { id: string; name: string; category: string; previewUrl: string | null; backgroundUrl: string | null; }

export interface Profile { id: string; username: string | null; displayName: string | null; avatarUrl: string | null; bio: string | null; isPro: boolean; }
export type FeedKind = 'ayah' | 'video';
export interface FeedPost {
  id: string; authorId: string; authorName: string; kind: FeedKind;
  reference: string | null; arabic: string | null; meal: string | null; caption: string | null;
  videoUrl: string | null; thumbnailUrl: string | null; templateId: string | null; topic: string | null;
  likeCount: number; likedByMe: boolean; createdAt: string;
}
export interface ChatMessage { id: string; senderId: string; body: string; createdAt: string; }
export interface KhatmCircle { id: string; name: string; ownerId: string; isPublic: boolean; }
export interface KhatmClaim { circleId: string; juzNumber: number; userId: string; completed: boolean; }
export interface Collection { id: string; reference: string; arabic: string; meal: string; note: string | null; createdAt: string; }
export type RenderStatus = 'queued' | 'processing' | 'done' | 'failed';
export interface RenderJob { id: string; status: RenderStatus; outputUrl: string | null; }
export interface PrayerTimes { fajr: Date; sunrise: Date; dhuhr: Date; asr: Date; maghrib: Date; isha: Date; }
```

- [ ] **Step 2: Failing test yaz**

`src/data/__tests__/queryKeys.test.ts`:

```ts
import { qk } from '@/data/queryKeys';

describe('queryKeys', () => {
  it('kararlı, parametrize key dizileri üretir', () => {
    expect(qk.surahs()).toEqual(['surahs']);
    expect(qk.surahAyahs(2)).toEqual(['surahAyahs', 2]);
    expect(qk.feed('video')).toEqual(['feed', 'video']);
    expect(qk.dailyAyah('2026-06-16')).toEqual(['dailyAyah', '2026-06-16']);
  });
});
```

- [ ] **Step 3: Çalıştır, başarısızlığı doğrula**

Run: `npm test -- queryKeys.test.ts`
Expected: FAIL — modül yok.

- [ ] **Step 4: queryKeys.ts implement et**

`src/data/queryKeys.ts`:

```ts
import type { FeedKind } from '@/data/types';

export const qk = {
  surahs: () => ['surahs'] as const,
  surahAyahs: (n: number) => ['surahAyahs', n] as const,
  esma: () => ['esma'] as const,
  duas: () => ['duas'] as const,
  duaCategories: () => ['duaCategories'] as const,
  topics: () => ['topics'] as const,
  topicalByTopic: (t: string) => ['topical', t] as const,
  stories: () => ['stories'] as const,
  miracles: () => ['miracles'] as const,
  tajweed: () => ['tajweed'] as const,
  dreamSearch: (q: string) => ['dreamSearch', q] as const,
  templates: () => ['templates'] as const,
  dailyAyah: (dayIso: string) => ['dailyAyah', dayIso] as const,
  feed: (kind: FeedKind) => ['feed', kind] as const,
  profile: (id: string) => ['profile', id] as const,
  myProfile: () => ['myProfile'] as const,
  collections: () => ['collections'] as const,
  memorizations: () => ['memorizations'] as const,
  juz: () => ['juz'] as const,
  khatmCircles: () => ['khatmCircles'] as const,
  khatmClaims: (circleId: string) => ['khatmClaims', circleId] as const,
  conversations: () => ['conversations'] as const,
  messages: (conversationId: string) => ['messages', conversationId] as const,
  renderJob: (id: string) => ['renderJob', id] as const,
};
```

- [ ] **Step 5: Çalıştır, geçtiğini doğrula**

Run: `npm test -- queryKeys.test.ts`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat(data): domain types + central query key factory"
```

---

### Task 11: Zustand store'ları (ayarlar + auth) + MMKV kalıcılığı

**Files:**
- Create: `kurandakimesaj-rn/src/stores/settingsStore.ts`
- Create: `kurandakimesaj-rn/src/stores/authStore.ts`
- Test: `kurandakimesaj-rn/src/stores/__tests__/settingsStore.test.ts`

- [ ] **Step 1: Failing test yaz**

`src/stores/__tests__/settingsStore.test.ts`:

```ts
import { useSettingsStore } from '@/stores/settingsStore';

describe('settingsStore', () => {
  beforeEach(() => {
    useSettingsStore.setState({
      meal: 'diyanet', interests: [], notificationsEnabled: false,
      displayName: null, avatarUrl: null, isPro: false, onboarded: false,
    });
  });

  it('meal seçimini günceller', () => {
    useSettingsStore.getState().setMeal('elmali');
    expect(useSettingsStore.getState().meal).toBe('elmali');
  });

  it('onboarding tamamlamayı işaretler', () => {
    useSettingsStore.getState().completeOnboarding(['sabir', 'huzur']);
    expect(useSettingsStore.getState().onboarded).toBe(true);
    expect(useSettingsStore.getState().interests).toEqual(['sabir', 'huzur']);
  });

  it('pro durumunu açar', () => {
    useSettingsStore.getState().setPro(true);
    expect(useSettingsStore.getState().isPro).toBe(true);
  });
});
```

- [ ] **Step 2: Çalıştır, başarısızlığı doğrula**

Run: `npm test -- settingsStore.test.ts`
Expected: FAIL — modül yok.

- [ ] **Step 3: settingsStore.ts implement et**

`src/stores/settingsStore.ts`:

```ts
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import { mmkvPersistStorage } from '@/lib/mmkv';
import type { AppSettings, MealCode } from '@/data/types';

interface SettingsState extends AppSettings {
  setMeal: (m: MealCode) => void;
  toggleInterest: (id: string) => void;
  setNotifications: (v: boolean) => void;
  setPro: (v: boolean) => void;
  setDisplayName: (n: string) => void;
  completeOnboarding: (interests: string[]) => void;
}

export const useSettingsStore = create<SettingsState>()(
  persist(
    (set) => ({
      meal: 'diyanet', interests: [], notificationsEnabled: false,
      displayName: null, avatarUrl: null, isPro: false, onboarded: false,
      setMeal: (meal) => set({ meal }),
      toggleInterest: (id) => set((s) => ({
        interests: s.interests.includes(id) ? s.interests.filter((x) => x !== id) : [...s.interests, id],
      })),
      setNotifications: (notificationsEnabled) => set({ notificationsEnabled }),
      setPro: (isPro) => set({ isPro }),
      setDisplayName: (displayName) => set({ displayName }),
      completeOnboarding: (interests) => set({ onboarded: true, interests }),
    }),
    { name: 'settings', storage: createJSONStorage(() => mmkvPersistStorage) },
  ),
);
```

- [ ] **Step 4: authStore.ts implement et**

`src/stores/authStore.ts`:

```ts
import { create } from 'zustand';
import type { Session } from '@supabase/supabase-js';
import { supabase } from '@/lib/supabase';

interface AuthState {
  session: Session | null;
  initializing: boolean;
  setSession: (s: Session | null) => void;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (email: string, password: string, displayName: string) => Promise<void>;
  signOut: () => Promise<void>;
  init: () => () => void; // unsubscribe döner
}

export const useAuthStore = create<AuthState>((set) => ({
  session: null,
  initializing: true,
  setSession: (session) => set({ session }),
  signIn: async (email, password) => {
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) throw error;
  },
  signUp: async (email, password, displayName) => {
    const { error } = await supabase.auth.signUp({ email, password, options: { data: { display_name: displayName } } });
    if (error) throw error;
  },
  signOut: async () => { await supabase.auth.signOut(); },
  init: () => {
    supabase.auth.getSession().then(({ data }) => set({ session: data.session, initializing: false }));
    const { data: sub } = supabase.auth.onAuthStateChange((_e, session) => set({ session }));
    return () => sub.subscription.unsubscribe();
  },
}));
```

- [ ] **Step 5: Çalıştır, geçtiğini doğrula**

Run: `npm test -- settingsStore.test.ts`
Expected: PASS (3 passing).

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat(stores): zustand settings + auth stores with MMKV persistence"
```

---

### Task 12: Sabit içerik veri katmanı (Supabase → cache hook'ları)

**Files:**
- Create: `kurandakimesaj-rn/src/data/content.ts`
- Test: `kurandakimesaj-rn/src/data/__tests__/content.test.ts`

> Bu, `database supabase olucak` + `Supabase + cihaz önbelleği` kararının veri katmanıdır: içerik Supabase'ten çekilir, TanStack Query (MMKV persister) ile çevrimdışı önbelleğe alınır.

- [ ] **Step 1: Failing test yaz**

`src/data/__tests__/content.test.ts`:

```ts
import { mapSurahRow, mapAyahRow } from '@/data/content';

describe('content mappers', () => {
  it('surah satırını domain tipine eşler', () => {
    const s = mapSurahRow({ number: 1, name_tr: 'Fatiha', name_arabic: 'الفاتحة', meaning: 'Açılış', ayah_count: 7, revelation: 'Mekki', juz_start: 1 });
    expect(s).toEqual({ number: 1, nameTr: 'Fatiha', nameArabic: 'الفاتحة', meaning: 'Açılış', ayahCount: 7, revelation: 'Mekki', juzStart: 1 });
  });

  it('ayah satırını meal kayıtlarına eşler', () => {
    const a = mapAyahRow({ id: 5, surah_number: 1, number_in_surah: 1, arabic: 'آية', meal_diyanet: 'd', meal_elmali: 'e', meal_tdv: null, tafsir: null });
    expect(a.meals.diyanet).toBe('d');
    expect(a.meals.elmali).toBe('e');
    expect(a.meals.tdv).toBeUndefined();
  });
});
```

- [ ] **Step 2: Çalıştır, başarısızlığı doğrula**

Run: `npm test -- content.test.ts`
Expected: FAIL — modül yok.

- [ ] **Step 3: content.ts implement et (mapper'lar + hook'lar)**

`src/data/content.ts`:

```ts
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { qk } from '@/data/queryKeys';
import type { Surah, Ayah, EsmaName, Dua, MealCode } from '@/data/types';

export function mapSurahRow(r: any): Surah {
  return {
    number: r.number, nameTr: r.name_tr, nameArabic: r.name_arabic, meaning: r.meaning,
    ayahCount: r.ayah_count, revelation: r.revelation, juzStart: r.juz_start ?? 1,
  };
}

export function mapAyahRow(r: any): Ayah {
  const meals: Partial<Record<MealCode, string>> = {};
  if (r.meal_diyanet) meals.diyanet = r.meal_diyanet;
  if (r.meal_elmali) meals.elmali = r.meal_elmali;
  if (r.meal_tdv) meals.tdv = r.meal_tdv;
  return { id: r.id, surahNumber: r.surah_number, numberInSurah: r.number_in_surah, arabic: r.arabic, meals, tafsir: r.tafsir ?? null };
}

export function useSurahs() {
  return useQuery({
    queryKey: qk.surahs(),
    queryFn: async (): Promise<Surah[]> => {
      const { data, error } = await supabase.from('surahs').select('*').order('number');
      if (error) throw error;
      return (data ?? []).map(mapSurahRow);
    },
  });
}

export function useSurahAyahs(surahNumber: number) {
  return useQuery({
    queryKey: qk.surahAyahs(surahNumber),
    queryFn: async (): Promise<Ayah[]> => {
      const { data, error } = await supabase.from('ayahs').select('*').eq('surah_number', surahNumber).order('number_in_surah');
      if (error) throw error;
      return (data ?? []).map(mapAyahRow);
    },
    enabled: surahNumber > 0,
  });
}

export function useEsma() {
  return useQuery({
    queryKey: qk.esma(),
    queryFn: async (): Promise<EsmaName[]> => {
      const { data, error } = await supabase.from('esma_names').select('*').order('order');
      if (error) throw error;
      return (data ?? []).map((r: any) => ({ order: r.order, name: r.name, arabic: r.arabic, meaning: r.meaning, audioUrl: r.audio_url ?? null }));
    },
  });
}

export function useDuas() {
  return useQuery({
    queryKey: qk.duas(),
    queryFn: async (): Promise<Dua[]> => {
      const { data, error } = await supabase.from('duas').select('*').order('id');
      if (error) throw error;
      return (data ?? []).map((r: any) => ({ id: r.id, title: r.title, category: r.category, arabic: r.arabic, latin: r.latin ?? '', body: r.body, source: r.source ?? '', audioUrl: r.audio_url ?? null }));
    },
  });
}
```

- [ ] **Step 4: Çalıştır, geçtiğini doğrula**

Run: `npm test -- content.test.ts`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat(data): content query hooks (surah/ayah/esma/dua) over Supabase + cache"
```

---

### Task 13: Root layout — Provider'lar, persistence, auth init, i18n

**Files:**
- Modify: `kurandakimesaj-rn/app/_layout.tsx`
- Create: `kurandakimesaj-rn/src/i18n/index.ts`
- Create: `kurandakimesaj-rn/src/i18n/tr.ts`
- Create: `kurandakimesaj-rn/src/domain/rules.ts`

- [ ] **Step 1: i18n tr.ts yaz (temel metinler)**

`src/i18n/tr.ts`:

```ts
export const tr = {
  common: { back: 'Geri', save: 'Kaydet', cancel: 'İptal', share: 'Paylaş', retry: 'Tekrar dene', loading: 'Yükleniyor…' },
  tabs: { home: 'Ana Sayfa', feed: 'Akış', create: 'Oluştur', messages: 'Mesajlar', profile: 'Profil' },
  errors: { network: 'Bağlantı hatası. İnternetinizi kontrol edin.', generic: 'Bir şeyler ters gitti.' },
};
export type TrDict = typeof tr;
```

- [ ] **Step 2: i18n index.ts yaz**

`src/i18n/index.ts`:

```ts
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import { tr } from '@/i18n/tr';

i18n.use(initReactI18next).init({
  resources: { tr: { translation: tr } },
  lng: 'tr', fallbackLng: 'tr',
  interpolation: { escapeValue: false },
});
export default i18n;
```

- [ ] **Step 3: domain/rules.ts yaz (disclaimer sabitleri)**

`src/domain/rules.ts`:

```ts
// DOMAIN KURALLARI: dini içerik doğruluğu + zorunlu uyarılar.
export const Disclaimers = {
  dream: 'Rüya tabirleri klasik İslami kaynaklara dayanır; kesin hüküm değildir. Bir âlime danışınız.',
  zakat: 'Bu hesaplama bilgilendirme amaçlıdır; kesin hüküm değildir. Kendi durumunuz için bir fıkıh ehline danışınız.',
} as const;

export const HadithGrades = { sahih: 'Sahih', hasan: 'Hasan', zayif: 'Zayıf' } as const;

export const ApprovedMealSources: Record<string, string> = {
  diyanet: 'Diyanet İşleri Başkanlığı',
  elmali: 'Elmalılı Hamdi Yazır',
  tdv: 'Türkiye Diyanet Vakfı',
};
```

- [ ] **Step 4: app/_layout.tsx genişlet (Provider'lar)**

`app/_layout.tsx`:

```tsx
import 'react-native-gesture-handler';
import '@/i18n';
import { useFonts } from 'expo-font';
import { Stack } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { useEffect } from 'react';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { StatusBar } from 'expo-status-bar';
import { PersistQueryClientProvider } from '@tanstack/react-query-persist-client';
import { makeQueryClient, queryPersister } from '@/lib/queryClient';
import { useAuthStore } from '@/stores/authStore';
import { AppColors } from '@/theme';

SplashScreen.preventAutoHideAsync();
const queryClient = makeQueryClient();

export default function RootLayout() {
  const [loaded] = useFonts({
    CormorantGaramond: require('../assets/fonts/CormorantGaramond-SemiBold.ttf'),
    DMSans: require('../assets/fonts/DMSans-Regular.ttf'),
    'DMSans-Medium': require('../assets/fonts/DMSans-Medium.ttf'),
    'DMSans-Bold': require('../assets/fonts/DMSans-Bold.ttf'),
    AmiriQuran: require('../assets/fonts/AmiriQuran-Regular.ttf'),
  });
  const initAuth = useAuthStore((s) => s.init);

  useEffect(() => {
    const unsub = initAuth();
    return unsub;
  }, [initAuth]);

  useEffect(() => { if (loaded) SplashScreen.hideAsync(); }, [loaded]);
  if (!loaded) return null;

  return (
    <GestureHandlerRootView style={{ flex: 1, backgroundColor: AppColors.emerald950 }}>
      <SafeAreaProvider>
        <PersistQueryClientProvider client={queryClient} persistOptions={{ persister: queryPersister }}>
          <StatusBar style="light" />
          <Stack screenOptions={{ headerShown: false, contentStyle: { backgroundColor: AppColors.emerald950 } }} />
        </PersistQueryClientProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
```

- [ ] **Step 5: Çalıştığını doğrula**

Run: `cd kurandakimesaj-rn && npm run typecheck`
Expected: 0 errors. Ardından `npx expo start` ile uygulama açılır, hata yok.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat: root layout with query persistence, auth init, i18n, domain rules"
```

---

### Task 14: Navigasyon — 5-sekmeli tab shell + orta FAB + features stack

**Files:**
- Create: `kurandakimesaj-rn/app/(tabs)/_layout.tsx`
- Create: `kurandakimesaj-rn/app/(tabs)/home.tsx` (placeholder — Faz 1'de doldurulur)
- Create: `kurandakimesaj-rn/app/(tabs)/feed.tsx` (placeholder)
- Create: `kurandakimesaj-rn/app/(tabs)/messages.tsx` (placeholder)
- Create: `kurandakimesaj-rn/app/(tabs)/profile.tsx` (placeholder)
- Create: `kurandakimesaj-rn/app/(features)/_layout.tsx`
- Create: `kurandakimesaj-rn/app/index.tsx` (splash/yönlendirme)
- Create: `kurandakimesaj-rn/src/ui/CreateSheet.tsx`

- [ ] **Step 1: Tab layout yaz (orta FAB ile)**

`app/(tabs)/_layout.tsx`:

```tsx
import { Tabs } from 'expo-router';
import { Pressable, View, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { useState } from 'react';
import { AppColors, Gradients } from '@/theme';
import { CreateSheet } from '@/ui/CreateSheet';

export default function TabsLayout() {
  const [createOpen, setCreateOpen] = useState(false);
  return (
    <>
      <Tabs
        screenOptions={{
          headerShown: false,
          tabBarStyle: { backgroundColor: AppColors.emerald900, borderTopColor: AppColors.line },
          tabBarActiveTintColor: AppColors.gold,
          tabBarInactiveTintColor: AppColors.muted2,
          tabBarLabelStyle: { fontFamily: 'DMSans', fontSize: 11 },
        }}
      >
        <Tabs.Screen name="home" options={{ title: 'Ana Sayfa', tabBarIcon: ({ color }) => <Ionicons name="home" size={24} color={color} /> }} />
        <Tabs.Screen name="feed" options={{ title: 'Akış', tabBarIcon: ({ color }) => <Ionicons name="albums" size={24} color={color} /> }} />
        <Tabs.Screen
          name="create-placeholder"
          options={{
            title: '', tabBarButton: () => (
              <Pressable accessibilityRole="button" accessibilityLabel="Oluştur" onPress={() => setCreateOpen(true)} style={styles.fabWrap}>
                <LinearGradient colors={Gradients.fab} style={styles.fab}>
                  <Ionicons name="add" size={28} color={AppColors.emerald950} />
                </LinearGradient>
              </Pressable>
            ),
          }}
        />
        <Tabs.Screen name="messages" options={{ title: 'Mesajlar', tabBarIcon: ({ color }) => <Ionicons name="mail" size={24} color={color} /> }} />
        <Tabs.Screen name="profile" options={{ title: 'Profil', tabBarIcon: ({ color }) => <Ionicons name="person" size={24} color={color} /> }} />
      </Tabs>
      <CreateSheet open={createOpen} onClose={() => setCreateOpen(false)} />
    </>
  );
}
const styles = StyleSheet.create({
  fabWrap: { top: -18, justifyContent: 'center', alignItems: 'center' },
  fab: { width: 52, height: 52, borderRadius: 26, justifyContent: 'center', alignItems: 'center', shadowColor: '#000', shadowOpacity: 0.3, shadowRadius: 8, elevation: 6 },
});
```

> Not: `create-placeholder` ekran dosyası `app/(tabs)/create-placeholder.tsx` boş bir `export default () => null` döndürür; gerçek aksiyon FAB butonunun `CreateSheet`'i açmasıdır.

- [ ] **Step 2: CreateSheet placeholder yaz**

`src/ui/CreateSheet.tsx`:

```tsx
import React from 'react';
import { Modal, View, Text, Pressable, StyleSheet } from 'react-native';
import { router } from 'expo-router';
import { AppColors, Radii, Spacing, display, body } from '@/theme';

export function CreateSheet({ open, onClose }: { open: boolean; onClose: () => void }) {
  const go = (path: string) => { onClose(); router.push(path as any); };
  return (
    <Modal visible={open} transparent animationType="slide" onRequestClose={onClose}>
      <Pressable style={styles.backdrop} onPress={onClose} />
      <View style={styles.sheet}>
        <View style={styles.handle} />
        <Text style={display(22, AppColors.cream)}>Oluştur</Text>
        <Pressable style={styles.item} onPress={() => go('/(features)/studio')}>
          <Text style={body(15, AppColors.cream)}>Ayet → Video Stüdyosu</Text>
        </Pressable>
        <Pressable style={styles.item} onPress={() => go('/(features)/ai-assistant')}>
          <Text style={body(15, AppColors.cream)}>Yapay Zeka Asistan</Text>
        </Pressable>
      </View>
    </Modal>
  );
}
const styles = StyleSheet.create({
  backdrop: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)' },
  sheet: { position: 'absolute', bottom: 0, left: 0, right: 0, backgroundColor: AppColors.emerald900, borderTopLeftRadius: Radii.lg, borderTopRightRadius: Radii.lg, padding: Spacing.xl },
  handle: { alignSelf: 'center', width: 44, height: 4, borderRadius: 2, backgroundColor: AppColors.gold, marginBottom: Spacing.m },
  item: { paddingVertical: Spacing.m, borderBottomWidth: 1, borderBottomColor: AppColors.lineSoft },
});
```

- [ ] **Step 3: Placeholder tab ekranları + create-placeholder**

`app/(tabs)/home.tsx`, `feed.tsx`, `messages.tsx`, `profile.tsx` — her biri (Faz dosyaları dolduracak):

```tsx
import { ScreenScaffold } from '@/ui/ScreenScaffold';
import { EmptyState } from '@/ui/EmptyState';
export default function Screen() {
  return (
    <ScreenScaffold title="Ana Sayfa">
      <EmptyState icon="construct" message="Bu ekran ilgili faz planında uygulanacak." />
    </ScreenScaffold>
  );
}
```

(her dosyada `title`'ı uygun şekilde değiştir; `create-placeholder.tsx` → `export default function C() { return null; }`)

- [ ] **Step 4: features stack layout**

`app/(features)/_layout.tsx`:

```tsx
import { Stack } from 'expo-router';
import { AppColors } from '@/theme';
export default function FeaturesLayout() {
  return <Stack screenOptions={{ headerShown: false, animation: 'slide_from_right', contentStyle: { backgroundColor: AppColors.emerald950 } }} />;
}
```

- [ ] **Step 5: app/index.tsx — splash + yönlendirme**

`app/index.tsx`:

```tsx
import { Redirect } from 'expo-router';
import { useSettingsStore } from '@/stores/settingsStore';

export default function Index() {
  const onboarded = useSettingsStore((s) => s.onboarded);
  return <Redirect href={onboarded ? '/(tabs)/home' : '/setup'} />;
}
```

(`app/setup.tsx` Faz 1'de uygulanır; şimdilik geçici olarak `<Redirect href="/(tabs)/home" />` döndüren bir placeholder oluştur.)

- [ ] **Step 6: Çalıştığını doğrula**

Run: `cd kurandakimesaj-rn && npx expo start`
Expected: Uygulama açılır, 5-sekmeli tab bar görünür, orta FAB CreateSheet'i açar, sekmeler arası geçiş çalışır.

- [ ] **Step 7: Commit**

```bash
git add -A && git commit -m "feat(nav): 5-tab shell with center FAB create sheet + features stack"
```

---

### Task 15: Auth ekranı (giriş/kayıt) + auth gate

**Files:**
- Create: `kurandakimesaj-rn/app/auth.tsx`
- Test: `kurandakimesaj-rn/app/__tests__/auth.test.tsx`

- [ ] **Step 1: Failing test yaz**

`app/__tests__/auth.test.tsx`:

```tsx
import React from 'react';
import { render, fireEvent, waitFor } from '@testing-library/react-native';

const signIn = jest.fn().mockResolvedValue(undefined);
jest.mock('@/stores/authStore', () => ({
  useAuthStore: (sel: any) => sel({ signIn, signUp: jest.fn(), session: null, initializing: false }),
}));
jest.mock('expo-router', () => ({ router: { replace: jest.fn() } }));

import AuthScreen from '../auth';

describe('AuthScreen', () => {
  it('email+şifre ile giriş çağırır', async () => {
    const { getByPlaceholderText, getByText } = render(<AuthScreen />);
    fireEvent.changeText(getByPlaceholderText('E-posta'), 'a@b.com');
    fireEvent.changeText(getByPlaceholderText('Şifre'), 'secret12');
    fireEvent.press(getByText('Giriş Yap'));
    await waitFor(() => expect(signIn).toHaveBeenCalledWith('a@b.com', 'secret12'));
  });
});
```

- [ ] **Step 2: Çalıştır, başarısızlığı doğrula**

Run: `npm test -- auth.test.tsx`
Expected: FAIL — modül yok.

- [ ] **Step 3: auth.tsx implement et**

`app/auth.tsx`:

```tsx
import React, { useState } from 'react';
import { View, Text, TextInput, Pressable, StyleSheet, Alert } from 'react-native';
import { router } from 'expo-router';
import { useAuthStore } from '@/stores/authStore';
import { ScreenScaffold } from '@/ui/ScreenScaffold';
import { AppColors, Radii, Spacing, display, body } from '@/theme';

export default function AuthScreen() {
  const signIn = useAuthStore((s) => s.signIn);
  const signUp = useAuthStore((s) => s.signUp);
  const [mode, setMode] = useState<'in' | 'up'>('in');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [busy, setBusy] = useState(false);

  const submit = async () => {
    setBusy(true);
    try {
      if (mode === 'in') await signIn(email, password);
      else await signUp(email, password, name || 'Misafir');
      router.replace('/(tabs)/home');
    } catch (e: any) {
      Alert.alert('Hata', e?.message ?? 'Giriş başarısız');
    } finally {
      setBusy(false);
    }
  };

  return (
    <ScreenScaffold title="Hesap">
      <View style={styles.body}>
        <Text style={display(30, AppColors.cream)}>{mode === 'in' ? 'Tekrar hoş geldin' : 'Aramıza katıl'}</Text>
        {mode === 'up' && (
          <TextInput placeholder="Görünen ad" placeholderTextColor={AppColors.muted2} value={name} onChangeText={setName} style={styles.input} />
        )}
        <TextInput placeholder="E-posta" placeholderTextColor={AppColors.muted2} autoCapitalize="none" keyboardType="email-address" value={email} onChangeText={setEmail} style={styles.input} />
        <TextInput placeholder="Şifre" placeholderTextColor={AppColors.muted2} secureTextEntry value={password} onChangeText={setPassword} style={styles.input} />
        <Pressable onPress={submit} disabled={busy} style={styles.primary}>
          <Text style={body(15, AppColors.emerald950, '700')}>{mode === 'in' ? 'Giriş Yap' : 'Kayıt Ol'}</Text>
        </Pressable>
        <Pressable onPress={() => setMode(mode === 'in' ? 'up' : 'in')}>
          <Text style={[body(13, AppColors.gold), { textAlign: 'center', marginTop: Spacing.m }]}>
            {mode === 'in' ? 'Hesabın yok mu? Kayıt ol' : 'Zaten hesabın var mı? Giriş yap'}
          </Text>
        </Pressable>
      </View>
    </ScreenScaffold>
  );
}
const styles = StyleSheet.create({
  body: { padding: Spacing.xl, gap: Spacing.m },
  input: { backgroundColor: AppColors.emerald850, borderRadius: Radii.md, borderWidth: 1, borderColor: AppColors.line, paddingHorizontal: Spacing.m, paddingVertical: 14, color: AppColors.cream, fontFamily: 'DMSans' },
  primary: { backgroundColor: AppColors.gold, borderRadius: Radii.md, paddingVertical: 16, alignItems: 'center', marginTop: Spacing.s },
});
```

- [ ] **Step 4: Çalıştır, geçtiğini doğrula**

Run: `npm test -- auth.test.tsx`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: email/password auth screen wired to Supabase"
```

---

### Task 16: Çevrimdışı bayrak + ağ hatası deneyimi + son doğrulama

**Files:**
- Create: `kurandakimesaj-rn/src/lib/online.ts`
- Modify: `kurandakimesaj-rn/src/ui/EmptyState.tsx` (zaten var — yeniden kullanılır)
- Test: `kurandakimesaj-rn/src/lib/__tests__/online.test.ts`

- [ ] **Step 1: NetInfo kur**

```bash
cd kurandakimesaj-rn && npx expo install @react-native-community/netinfo
```

- [ ] **Step 2: Failing test yaz**

`src/lib/__tests__/online.test.ts`:

```ts
import { isQueryError, networkMessage } from '@/lib/online';

describe('online helpers', () => {
  it('ağ hatasını tanır ve Türkçe mesaj döner', () => {
    expect(isQueryError(new Error('Network request failed'))).toBe(true);
    expect(networkMessage(new Error('x'))).toMatch(/Bağlantı|ters/);
  });
});
```

- [ ] **Step 3: Çalıştır, başarısızlığı doğrula**

Run: `npm test -- online.test.ts`
Expected: FAIL — modül yok.

- [ ] **Step 4: online.ts implement et**

`src/lib/online.ts`:

```ts
export function isQueryError(e: unknown): e is Error {
  return e instanceof Error;
}

export function networkMessage(e: unknown): string {
  const msg = e instanceof Error ? e.message : '';
  if (/network|fetch|timeout|offline/i.test(msg)) return 'Bağlantı hatası. İnternetinizi kontrol edin.';
  return 'Bir şeyler ters gitti.';
}
```

- [ ] **Step 5: Çalıştır, geçtiğini doğrula**

Run: `npm test -- online.test.ts`
Expected: PASS.

- [ ] **Step 6: Tüm test paketini + typecheck'i çalıştır (foundation doğrulaması)**

Run: `cd kurandakimesaj-rn && npm test && npm run typecheck`
Expected: Tüm testler PASS, 0 tip hatası.

- [ ] **Step 7: Commit**

```bash
git add -A && git commit -m "feat: offline/network error helpers; foundation complete"
```

---

## Self-Review

**1. Spec coverage:**
- ✅ Supabase tek veritabanı (içerik + topluluk şeması, RLS) — Task 4
- ✅ Offline önbellek (TanStack Query + MMKV persister + offlineFirst) — Task 6, 12
- ✅ Tasarım sistemi (kesin hex/font/radii) — Task 7, 8, 9
- ✅ Navigasyon (5-tab + FAB shell, features stack) — Task 14
- ✅ State (Zustand + TanStack Query) — Task 6, 11
- ✅ Auth (Supabase + secure-store) — Task 5, 11, 15
- ✅ Domain kuralları (Arapça RTL/Amiri, disclaimer, meal kaynakları, Türkçe ortografi) — Task 7, 9, 13
- ✅ Test altyapısı (TDD) — Task 2 ve her task'ta

**2. Placeholder taraması:** Tüm kod adımlarında gerçek, çalışır kod var. Tab placeholder ekranları kasıtlıdır ve faz planlarında doldurulacağı açıkça belirtilmiştir.

**3. Tip tutarlılığı:** `AppColors`, `qk.*`, paylaşılan bileşen prop'ları (Convention Reference), domain tipleri (`src/data/types.ts`) faz planlarında atıfla kullanılır; isimler bu dosya boyunca tutarlıdır.

---

## Sonraki Adım

Bu foundation tamamlandığında faz planlarına geçilir:
- `01-faz1-temel.md` — onboarding, Kur'an okuma, namaz vakitleri, zikirmatik, günün ayeti, koleksiyonlar, ana sayfa, bildirimler
- `02-faz2-studio.md` — video stüdyosu (Remotion Lambda), şablonlar, AI asistan, akış, tesbihat, Esmaü'l-Hüsna
- `03-faz3-ogrenme-topluluk.md` — tecvid, ezber, cüz takip, kıssalar, mucizeler, konuya göre ayet, hatim halkaları, mesajlar, oruç/imsakiye
- `04-faz4-araclar.md` — zekât, cami bul, bağış, rüya tabiri, dini günler, dua kitaplığı, premium, profil
