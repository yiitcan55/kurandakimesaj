-- Storage bucket'ları + RLS politikaları.
-- avatars: herkese okunur, sahibi (klasör = user_id) yazar.
-- post-media: herkese okunur, oturum açmış kullanıcı kendi klasörüne yazar.

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('post-media', 'post-media', true)
on conflict (id) do nothing;

-- Okuma (her iki bucket herkese açık).
create policy "avatars_read" on storage.objects
  for select using (bucket_id = 'avatars');
create policy "post_media_read" on storage.objects
  for select using (bucket_id = 'post-media');

-- Yazma: dosya yolu '<auth.uid()>/...' biçiminde olmalı (ilk klasör = kullanıcı).
create policy "avatars_write_own" on storage.objects
  for insert with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy "avatars_update_own" on storage.objects
  for update using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy "avatars_delete_own" on storage.objects
  for delete using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "post_media_write_own" on storage.objects
  for insert with check (
    bucket_id = 'post-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy "post_media_delete_own" on storage.objects
  for delete using (
    bucket_id = 'post-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
