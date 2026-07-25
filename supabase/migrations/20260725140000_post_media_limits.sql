-- post-media BUCKET SINIRLARI — istemci kapısının sunucu tarafı karşılığı.
--
-- İstemci artık video seçiminde 20 MB sınırı uyguluyor
-- (community_screens.dart `_pickVideo` + `_publish`, kAyahVideoMaxBytes ile
-- aynı değer). Ama istemci kapısı bir kolaylıktır, güvenlik sınırı değil:
-- Supabase istemcisiyle doğrudan `storage.from('post-media').upload(...)`
-- çağrılabilir ve depolama RLS'i yalnızca "kendi klasörüne yazıyor mu" diye
-- bakıyor — boyuta ve türe hiç bakmıyordu.
--
-- Bu iki sınır olmadan herkese açık bir bucket, kimliği doğrulanmış herhangi
-- bir kullanıcı için sınırsız boyutta, keyfi türde dosya barındırma servisine
-- dönüşür (depolama maliyeti + kötüye kullanım yüzeyi).

update storage.buckets
   set file_size_limit = 20971520,          -- 20 MB — kAyahVideoMaxBytes ile aynı
       allowed_mime_types = array[
         'image/png',                        -- stüdyo çıktısı (kind='still')
         'image/jpeg',
         'image/webp',
         'video/mp4'                         -- galeri videosu (kind='video')
       ]
 where id = 'post-media';

-- ── Yönetici silme yetkisi ───────────────────────────────────────────────────
-- Tek silme politikası `post_media_delete_own` idi. Sonuç: moderatör bir
-- gönderiyi reddettiğinde satır akıştan kalkıyor ama DOSYA public URL'den
-- erişilebilir kalmaya devam ediyordu ve yöneticinin onu silme yetkisi yoktu —
-- uygulamanın kendi alan adı uygunsuz içeriği barındırmayı sürdürürdü.
drop policy if exists "post_media_delete_admin" on storage.objects;
create policy "post_media_delete_admin" on storage.objects
  for delete using (
    bucket_id = 'post-media'
    and exists (
      select 1 from public.profiles p
      where p.id = (select auth.uid()) and p.is_admin
    )
  );
