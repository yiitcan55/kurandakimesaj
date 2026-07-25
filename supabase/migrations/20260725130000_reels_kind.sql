-- REELS TEKLEŞTİRME — iki paralel içerik sistemi (Gönderiler + Reels) tek
-- sisteme iniyor. `kind` artık yalnız medya türünü anlatır:
--   'video' → kullanıcının mp4'ü        'still' → stüdyo üretimi PNG
-- Karar K1: gerçek video render hattı bu sürümde kapsam dışı; stüdyo çıktısı
-- `still` reel olarak yayınlanır (Ken Burns + gradyan kompozisyonuyla tam ekran).

-- ── 1) Önce veriyi dönüştür (kısıt değişmeden!) ──────────────────────────────
-- 'ayah' (metin/görsel gönderi) artık üretilmiyor. VERİ SİLİNMİYOR, dönüşüyor.
-- Savunmacı: ('video','still') dışındaki HER değeri 'still'e çekiyoruz —
-- init.sql'deki kısıt yalnız ('ayah','video')e izin veriyordu ama bozuk
-- `_uploadToSupabase` bir dönem 'image' yazmayı deniyordu; kalmış bir satır
-- varsa 3. adımdaki kısıt eklemesi patlardı.
update public.feed_posts
   set kind = 'still'
 where kind is distinct from 'video'
   and kind is distinct from 'still';

-- ── 2) Eski kısıtı ve artık geçersiz olan varsayılanı kaldır ─────────────────
-- SIRA ÖNEMLİ: varsayılan hâlâ 'ayah' iken yeni kısıt eklenirse, `kind`
-- göndermeyen her insert anında kısıt ihlaline düşer. (init.sql:62 —
-- `kind text not null default 'ayah'`.)
alter table public.feed_posts drop constraint if exists feed_posts_kind_check;
alter table public.feed_posts alter column kind set default 'still';

-- ── 3) Yeni kısıt ────────────────────────────────────────────────────────────
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.feed_posts'::regclass
      and conname = 'feed_posts_kind_check'
  ) then
    alter table public.feed_posts
      add constraint feed_posts_kind_check check (kind in ('video','still'));
  end if;
end $$;

-- ── 4) İndeks ────────────────────────────────────────────────────────────────
-- init.sql'deki feed_posts_kind_idx (kind, created_at desc) duruyor. Reels tek
-- akış olduğu için artık `kind` filtresiyle sorgulamıyoruz; sıralama+kapı
-- indeksi feed_posts_status_idx (moderation_queue göçü). kind indeksi
-- bırakılıyor: hâlâ 'video'/'still' ayrımıyla sorgu yazılabilir ve düşürmek
-- geri alınamaz bir kayıp yaratır.
