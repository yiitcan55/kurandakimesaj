-- REELS ARKA PLAN SESİ — küratörlü müzik kütüphanesi.
--
-- Telif güvencesi UYGULAMADA değil, YABANCI ANAHTARDA durur:
-- `feed_posts.audio_track_id` yalnız `feed_audio_tracks(id)` değerlerini kabul
-- eder ve o tabloya SADECE service_role yazabilir (aşağıda yazma politikası
-- YOK). Yani kullanıcı keyfi bir ses URL'i gösteremez; her olası değer
-- önceden onaylanmış bir parçadır.
--
-- DOKUNULMAYANLAR: `feed_posts_moderation_guard`, `feed_select_visible` /
-- `feed_select_admin`, `is_own_post_media`, `revoke update on profiles`.

-- ════════════════════════════════════════════════════════════════════════════
-- 1. KÜRATÖRLÜ PARÇA KÜTÜPHANESİ
-- ════════════════════════════════════════════════════════════════════════════
create table if not exists public.feed_audio_tracks (
  id               uuid primary key default gen_random_uuid(),
  title            text not null,
  artist           text not null default '',
  url              text not null,
  -- Lisans NOT NULL: kaynağı belgelenmemiş bir parça kütüphaneye giremez.
  -- Boş geçilebilseydi "küratörlü" iddiası ilk acele eklemede çökerdi.
  license          text not null,
  source_url       text,
  duration_seconds integer,
  sort_order       integer not null default 0,
  is_active        boolean not null default true,
  created_at       timestamptz not null default now()
);

alter table public.feed_audio_tracks enable row level security;

-- Yalnız OKUMA politikası var. INSERT/UPDATE/DELETE politikası BİLEREK
-- yazılmadı → RLS açık + politika yok = default-deny; `authenticated` rolü
-- hiçbir parça ekleyemez. Kütüphaneyi yalnız service_role (dashboard/panel)
-- doldurur. Kürasyon kapısı budur.
drop policy if exists "feed_audio_select_active" on public.feed_audio_tracks;
create policy "feed_audio_select_active" on public.feed_audio_tracks
  for select using (is_active);

create index if not exists feed_audio_tracks_order_idx
  on public.feed_audio_tracks (sort_order, created_at);

-- ════════════════════════════════════════════════════════════════════════════
-- 2. GÖNDERİYE BAĞLA
-- ════════════════════════════════════════════════════════════════════════════
alter table public.feed_posts
  add column if not exists audio_track_id uuid
  references public.feed_audio_tracks(id) on delete set null;

create index if not exists feed_posts_audio_idx
  on public.feed_posts (audio_track_id);

-- ════════════════════════════════════════════════════════════════════════════
-- MODERASYON TETİKLEYİCİSİYLE İLİŞKİ — BİLİNÇLİ KARAR
-- ════════════════════════════════════════════════════════════════════════════
-- `feed_posts_moderation_guard` (20260725120000_moderation_queue.sql:216-223)
-- onay SONRASI değişiklikte satırı yeniden kuyruğa atıyor. Karşılaştırdığı
-- demet: media_url, video_url, thumbnail_url, caption, meal, arabic,
-- reference, kind, topic.
--
-- `audio_track_id` bu demete BİLEREK EKLENMEDİ. Demetteki kolonların hepsi
-- SERBEST metin veya SERBEST URL: değişmeleri "moderatörün görmediği içerik"
-- demektir. `audio_track_id` ise FK ile küratörlü tabloya kilitli — alabileceği
-- HER değer zaten önceden onaylanmış bir parçadır. Demete eklersek kullanıcı
-- yalnızca müziğini değiştirdiği için onaylı reel'i tekrar kuyruğa düşürürüz:
-- moderasyon açısından kazanç yok, kullanıcı açısından ceza var.
--
-- INSERT tarafında ek bir şey gerekmez: tetikleyici zaten `status := 'pending'`
-- yazıyor (moderation_queue.sql:192-197). Kapı ZAYIFLAMIYOR.
--
-- DOĞRULAMA (kürasyon kapısının kanıtı) — kullanıcı oturumunda:
--   insert into feed_posts (author_id, kind, audio_track_id)
--   values (auth.uid(), 'still', gen_random_uuid());
--   → FK ihlali **23503** ile REDDEDİLMELİ.
