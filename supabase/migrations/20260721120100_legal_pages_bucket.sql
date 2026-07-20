insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('legal', 'legal', true, 1048576, array['text/html'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "legal_pages_public_read" on storage.objects
  for select using (bucket_id = 'legal');
