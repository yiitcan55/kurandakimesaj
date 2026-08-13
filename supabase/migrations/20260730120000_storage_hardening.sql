-- Storage sertleştirme — moderasyon kapısının veritabanı DIŞINDA kalan bacağı.
--
-- Bağlam: 1.0.1, Apple Guideline 1.2 reddine yanıttır. Onay mekanizması
-- `feed_posts` üzerindeki RLS + `feed_posts_moderation_guard` trigger'ıyla
-- veritabanında zorlanır. Ancak kapı yalnız SATIRI koruyordu — satırın
-- gösterdiği BAYTLARI korumuyordu. Bu migration o boşluğu kapatır.
--
-- Gönderim öncesi güvenlik denetiminin K1 / Y1 / O1 bulguları.

-- ─────────────────────────────────────────────────────────────────────────
-- K1 (KRİTİK) — Onaylanan medya, hiçbir veritabanı yazımı olmadan değiştirilebiliyordu.
--
-- İstismar: saldırgan masum bir PNG yükler (`<uid>/1700000000000.png`) →
-- moderatör kuyrukta görüp ONAYLAR (`status='approved'`) → saldırgan
-- `post_media_delete_own` ile dosyayı SİLER → `post_media_write_own` ile AYNI
-- yola uygunsuz içeriği yükler. `feed_posts` satırına hiç dokunulmadığı için
-- guard tetiklenmez, `status` 'approved' kalır. Uygunsuz içerik canlıdır;
-- tek gecikme CDN cache TTL'i.
--
-- Düzeltme: nesne baytları yüklendikten sonra DEĞİŞTİRİLEMEZ olmalı.
-- `post-media` üzerinde UPDATE politikası zaten yok; DELETE de kalkınca
-- sil-yeniden-yükle yolu kapanır.
--
-- Kırılma riski YOK: `lib/` içinde `post-media` üzerinde hiçbir `.remove()`
-- çağrısı yok (tek storage çağrıları `uploadPostMedia` ve `getPublicUrl`).
-- Temizlik yolu açık kalıyor: `post_media_delete_admin`
-- (20260725140000_post_media_limits.sql) yöneticiye siliş yetkisi verir.
drop policy if exists "post_media_delete_own" on storage.objects;

-- ─────────────────────────────────────────────────────────────────────────
-- Y1 (YÜKSEK) — `post_media_read` politikasının hiçbir koşulu yoktu:
--   create policy "post_media_read" ... using (bucket_id = 'post-media');
-- Yol, sahip, is_admin — hiçbiri kontrol edilmiyordu. Anon key ile
-- `/storage/v1/object/list/post-media` çağrısı bucket'taki TÜM klasörleri
-- (= kullanıcı UUID'leri) ve dosya adlarını döküyordu. Yani hiç incelenmemiş
-- ('pending') ve moderatörün açıkça REDDETTİĞİ ('rejected') tüm medya
-- keşfedilebilir durumdaydı. RLS satırı gizliyordu, baytları gizlemiyordu.
--
-- DÜRÜST SINIR: `post-media` bucket'ı `public = true`. Public bucket'ta
-- `/object/public/...` yolu RLS'i DEĞERLENDİRMEZ. Bu politika bu yüzden
-- KEŞFİ (list API + kimlik doğrulamalı okuma) kapatır, yolu zaten bilen
-- birini durdurmaz. Tam kapatmak bucket'ı private yapıp imzalı URL'lere
-- geçmeyi gerektirir — akışın tamamını etkileyen ayrı bir iş kalemi.
-- Yollar `<uid>/<epoch_ms>.<ext>` biçiminde olduğu için tahmin pratik değil;
-- asıl keşif vektörü list API'ydi ve kapanıyor.
--
-- Akış render'ı ETKİLENMEZ: uygulama medyayı yalnız `getPublicUrl` ile
-- (yani `/object/public/...` ile) gösterir.
drop policy if exists "post_media_read" on storage.objects;
create policy "post_media_read" on storage.objects
  for select using (
    bucket_id = 'post-media'
    and (
      (storage.foldername(name))[1] = (select auth.uid())::text
      or exists (
        select 1 from public.profiles p
        where p.id = (select auth.uid()) and p.is_admin
      )
    )
  );

-- ─────────────────────────────────────────────────────────────────────────
-- O1 (ORTA) — `is_own_post_media` host kalıbı `[a-z0-9-]+\.supabase\.co` idi,
-- yani HERHANGİ bir Supabase projesini kabul ediyordu.
--
-- İstismar: saldırgan kendi ücretsiz Supabase projesinde `post-media` adlı
-- public bucket açar, `<kendi-kdm-uid>/x.png` yoluna masum görsel koyar ve
-- `media_url` olarak kendi host'unu gönderir. Guard geçer, moderatör onaylar,
-- sonra dosyayı KENDİ sunucusunda serbestçe değiştirir — K1'in dış varyantı.
-- Ayrıca akışı kaydıran her kullanıcının IP ve User-Agent'ı saldırganın
-- sunucusuna düşer (moderatörünki dahil).
--
-- İkinci kusur: kalıp sağdan sabitlenmemişti ve nokta-segment reddedilmiyordu,
-- yani `.../post-media/<uid>/../../avatars/x.png` de geçiyordu (HTTP istemcisi
-- RFC 3986 normalizasyonu yapıp aynı host içinde BAŞKA yola çözer).
--
-- Düzeltme: host bu projenin ref'ine sabitlenir + kalıp sağdan sabitlenir.
-- `[^/.][^/]*$` tek path segmenti zorlar: ilk karakter `/` veya `.` olamaz
-- (`..` reddedilir), gerisinde `/` olamaz (iç içe yol reddedilir).
-- `uploadPostMedia` yolu `<uid>/<epoch_ms>.png|mp4` ürettiği için uyumlu.
--
-- DİKKAT — projeler arası taşıma: staging'e veya yeni bir Supabase projesine
-- geçilirse aşağıdaki ref GÜNCELLENMELİ, yoksa tüm yüklemeler guard'da
-- reddedilir. Bu bilinçli bir tercihtir: gürültülü kırılma, sessiz güvenlik
-- açığına yeğlenir. Ref'in tek diğer kopyası `--dart-define=SUPABASE_URL`.
create or replace function public.is_own_post_media(url text, owner uuid)
returns boolean
language sql
immutable
as $$
  select url is null
      or url = ''
      or url ~ ('^https://uytqxgcbohdlwwxemgyy\.supabase\.co'
                || '/storage/v1/object/public/post-media/'
                || owner::text || '/[^/.][^/]*$');
$$;
