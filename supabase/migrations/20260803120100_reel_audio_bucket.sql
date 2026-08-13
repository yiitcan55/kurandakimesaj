-- REELS SES DOSYALARI İÇİN DEPOLAMA KOVASI.
--
-- Kalıp: 20260721120100_legal_pages_bucket.sql (public + yalnız select).
-- Kova gün BİRİNCİ göçte sınırlı açılıyor; sonradan yamalanmıyor
-- (20260725140000_post_media_limits.sql'in gerekçesi: sınırsız public kova,
-- kimlik doğrulamalı herhangi bir kullanıcı için sınırsız barındırma demek).

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'reel-audio', 'reel-audio', true, 8388608,
  array['audio/mpeg', 'audio/mp4', 'audio/aac']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- YALNIZ OKUMA. `authenticated` için insert/update/delete politikası
-- BİLEREK yazılmadı — yükleme dashboard'dan (service_role) yapılır.
--
-- `post-media`daki K1 açığı (20260730120000_storage_hardening.sql): kullanıcıya
-- delete verilirse onaylanmış dosyayı silip AYNI yola yenisini yükleyebiliyor,
-- veritabanına hiç dokunulmadığı için moderasyon tetikleyicisi uyanmıyordu.
-- Küratörlü kütüphanede bu deseni baştan açmıyoruz.
--
-- Koşulsuz select burada GÜVENLİ (post-media'dan farklı olarak): bu kovada
-- kullanıcı klasörü yok, `list` yalnız küratörlü parça adlarını açığa çıkarır —
-- kullanıcı UUID'si sızmaz.
drop policy if exists "reel_audio_public_read" on storage.objects;
create policy "reel_audio_public_read" on storage.objects
  for select using (bucket_id = 'reel-audio');
