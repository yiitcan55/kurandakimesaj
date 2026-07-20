-- ayah-audio: Ayet Bulucu'nun ses hattı için GEÇİCİ video deposu.
--
-- avatars/post-media'dan farklı olarak PRIVATE (public = false): burada duran şey
-- kullanıcının kendi videosudur, herkese açık okuma politikası YOKTUR. Dosya
-- yalnızca sahibi tarafından yazılır/silinir; `ayah-finder-audio` Edge Function'ı
-- service_role ile kısa ömürlü imzalı URL üretip Groq'a verir ve iş biter bitmez
-- objeyi siler.
--
-- 20 MB sınırı istemcide de ön kontrol edilir (sunucuya boşuna yükleme yapılmasın),
-- burada da zorlanır (savunma derinliği).

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'ayah-audio',
  'ayah-audio',
  false,
  20971520,  -- 20 MB
  array[
    'video/mp4', 'video/quicktime', 'video/x-matroska', 'video/webm', 'video/3gpp',
    'audio/mpeg', 'audio/mp4', 'audio/aac', 'audio/wav', 'audio/ogg', 'audio/webm'
  ]
)
on conflict (id) do nothing;

-- Yazma/okuma/silme: yalnız kendi klasörü ('<auth.uid()>/...'). Public read YOK.
create policy "ayah_audio_write_own" on storage.objects
  for insert with check (
    bucket_id = 'ayah-audio'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy "ayah_audio_read_own" on storage.objects
  for select using (
    bucket_id = 'ayah-audio'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy "ayah_audio_delete_own" on storage.objects
  for delete using (
    bucket_id = 'ayah-audio'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
