# Supabase Backend — Kur'an'da ki Mesaj

Bu klasör uygulamanın **deploy edilebilir backend kodudur**: şema + RLS (default-deny),
Storage, Realtime, pg_cron ve Edge Functions. Hiçbir gizli anahtar koda gömülmez;
`service_role` asla istemcide bulunmaz.

## İçerik
```
supabase/
├── config.toml                         # proje + auth + functions yapılandırması
├── migrations/
│   ├── 20260615120000_init.sql         # tüm tablolar + RLS + trigger + Realtime
│   └── 20260615120100_storage.sql      # avatars / post-media bucket + politikalar
└── functions/
    ├── _shared/cors.ts
    ├── render-trigger/      # ayet→video render işini kuyruğa ekler (JWT)
    ├── render-status/       # render iş durumu (JWT)
    ├── revenuecat-webhook/  # abonelik → profiles.is_pro (secret doğrulamalı)
    ├── donation-verify/     # bağış doğrulama iskeleti (JWT)
    └── daily-content/       # günlük öne çıkan ayet (pg_cron/service_role)
```

## Tablolar (hepsinde RLS açık, default-deny)
`profiles` · `feed_posts` · `likes` · `follows` · `conversations` · `conversation_members` ·
`messages` · `khatm_circles` · `khatm_claims` · `cloud_dhikr` · `cloud_collections` ·
`render_jobs` · `donations` · `reports` · `daily_content`

Realtime publication: `feed_posts`, `likes`, `messages`, `khatm_claims`, `render_jobs`.

## Dağıtım adımları

1. **Supabase CLI kur** (Windows): `scoop install supabase` veya `npm i -g supabase`.
2. **Proje oluştur** (supabase.com) → Project Ref, `anon` key ve URL'i al.
3. **Bağla:** `supabase link --project-ref <PROJECT_REF>`
4. **Şemayı uygula:** `supabase db push`  (migrations + storage + RLS)
5. **Fonksiyonları dağıt:**
   ```
   supabase functions deploy render-trigger render-status donation-verify daily-content revenuecat-webhook
   ```
6. **Secret'lar** (yalnızca sunucuda; `SUPABASE_URL`/`SUPABASE_ANON_KEY`/`SUPABASE_SERVICE_ROLE_KEY` otomatik enjekte edilir):
   ```
   supabase secrets set REVENUECAT_WEBHOOK_SECRET=<rastgele-güçlü-secret>
   ```
7. **pg_cron** (günlük içerik): `init.sql` sonundaki `cron.schedule(...)` bloğunu
   `<PROJECT_REF>` ve service_role anahtarıyla doldurup SQL editöründe çalıştır.
8. **Uygulamayı bağla:**
   ```
   flutter run --dart-define=SUPABASE_URL=https://<REF>.supabase.co --dart-define=SUPABASE_ANON_KEY=<ANON_KEY>
   ```
   Boş bırakılırsa uygulama backend'siz (yerel) çalışır.

## Auth
- E-posta/parola hazır (uygulamadaki Giriş ekranı). Üretimde `config.toml`'da
  `enable_confirmations = true` yapıp e-posta sağlayıcısını ayarla.
- OAuth/derin bağlantı için redirect: `io.kurandakimesaj://login-callback`
  (Android `AndroidManifest` intent-filter + iOS `Info.plist` URL scheme gerekir).

## RevenueCat (PRO)
- RevenueCat'te **app_user_id = Supabase `user.id`** olarak ayarla.
- Webhook URL: `https://<REF>.functions.supabase.co/revenuecat-webhook`
- Webhook Authorization header: `Bearer <REVENUECAT_WEBHOOK_SECRET>`
- Aktif abonelikte `profiles.is_pro = true` yazılır; uygulama bunu okuyup PRO kapılarını açar.

## Video render worker (sonraki adım)
`render-trigger` işi `render_jobs` tablosuna `queued` olarak yazar. Gerçek render
(ffmpeg/headless) ayrı bir worker'da (Supabase dışı bir servis veya kuyruk) yapılır;
worker `service_role` ile job'u `processing`→`done` günceller ve `output_url`'i
`post-media` bucket'ına yükler. İstemci `render-status` ile durumu sorar.

## İstemci entegrasyon durumu (`lib/data/backend_repositories.dart`)
- **Bağlandı:** Akış okuma+beğeni (oturum açıkken bulut), Stüdyo render-trigger,
  Zikir bulut senkronu (offline→online upsert).
- **Repository hazır (ekran bağlama bir sonraki tur):** Mesajlar Realtime
  (`MessagesRepository.watchMessages`), Hatim claims (`KhatmRepository`), profil/PRO
  eşitleme (`ProfileRepository.isPro`), koleksiyon bulut senkronu (`SyncRepository`).
- Supabase yoksa tüm bunlar zarifçe yerel içeriğe/duruma düşer (uygulama açılır).
