-- Release guard: migration geçmişi işlenmiş olsa bile manuel silinen bucket'ı
-- geri getir ve güvenlik/sınır ayarlarını tek doğru değere hizala.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'ayah-audio',
  'ayah-audio',
  false,
  20971520,
  array[
    'video/mp4', 'video/quicktime', 'video/x-matroska', 'video/webm', 'video/3gpp',
    'audio/mpeg', 'audio/mp4', 'audio/aac', 'audio/wav', 'audio/ogg', 'audio/webm'
  ]
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
