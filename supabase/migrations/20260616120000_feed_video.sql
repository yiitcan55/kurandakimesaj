-- Reels (dikey video) desteği: feed_posts tablosuna oynatılabilir video URL'i,
-- önizleme (thumbnail) ve şablon kimliği eklenir. `kind` zaten init göçünde var
-- ('ayah' | 'video'). Bu kolonlar render hattı backend'de hazır olunca dolacak;
-- istemci null'a karşı defansif okuduğu için kolonlar boşken de çalışır.

alter table public.feed_posts add column if not exists video_url     text;
alter table public.feed_posts add column if not exists thumbnail_url  text;
alter table public.feed_posts add column if not exists template_id    text;

-- Reels sekmesi yalnız kind='video' kayıtları çeker → kind üzerinde dizin.
create index if not exists feed_posts_kind_idx on public.feed_posts (kind, created_at desc);
