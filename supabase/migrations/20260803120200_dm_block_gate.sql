-- DM ENGELLEME KAPISI — engelleme mesajlaşmada da VERİTABANINDA zorlanır.
--
-- Bağlam: profilden 1:1 sohbet açma açıldı (`openDirectConversation`,
-- backend_repositories.dart). Apple Guideline 1.2 gereği kullanıcı,
-- engellediği kişiden mesaj ALMAMALI. Kapıyı yalnız UI'da tutmak yetmez:
-- istemci doğrudan PostgREST üzerinden `messages` tablosuna insert atabilir.
--
-- DOKUNULMAYANLAR: `feed_posts`, `feed_posts_moderation_guard`,
-- `feed_select_visible` / `feed_select_admin`, `is_own_post_media`,
-- `revoke update on profiles`. App Store onayı bunlara bağlı.

-- ════════════════════════════════════════════════════════════════════════════
-- 1. ENGEL SORGUSU — SECURITY DEFINER OLMAK ZORUNDA
-- ════════════════════════════════════════════════════════════════════════════
-- TUZAK: `messages` politikasının içinden `user_blocks`a DÜZ bir alt-sorgu
-- atılırsa, o alt-sorgu ÇAĞIRANIN rolüyle çalışır ve `user_blocks`ın kendi
-- politikası (`user_blocks_select_own`: `auth.uid() = blocker_id`,
-- 20260721121000_ugc_safety.sql) devreye girer.
--
-- "Karşı taraf BENİ engelledi" satırının `blocker_id`si karşı taraftır → o
-- satır bana GÖRÜNMEZ → `not exists` her zaman true döner → kapı, engelleme
-- gerçekten varken bile SESSİZCE AÇIK kalır. Yanlış güvenlik hissi veren tam
-- da bu sınıf hatadır.
--
-- Çözüm `is_conversation_member` ile aynı kalıp (init.sql:169-175):
-- security definer + pinlenmiş search_path.
create or replace function public.blocks_between(a uuid, b uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.user_blocks ub
    where (ub.blocker_id = a and ub.blocked_id = b)
       or (ub.blocker_id = b and ub.blocked_id = a)
  );
$$;

-- Fonksiyon yalnız iki uuid'nin arasında engel OLUP OLMADIĞINI söyler; kimin
-- kimi engellediğini sızdırmaz. Yine de yüzeyi daraltıyoruz.
revoke all on function public.blocks_between(uuid, uuid) from public;
grant execute on function public.blocks_between(uuid, uuid) to authenticated;

-- ════════════════════════════════════════════════════════════════════════════
-- 2. POLİTİKA DEĞİŞTİRİLİR — YENİSİ EKLENMEZ
-- ════════════════════════════════════════════════════════════════════════════
-- TUZAK: aynı tablo+komut için permissive politikalar **OR'lanır** (bu dersin
-- kaynağı: 20260725120000_moderation_queue.sql — `feed_update_own` yürürlükte
-- kaldığı sürece sıkı `feed_update_admin` eklemek kapıyı kapatmıyordu).
-- Engel kontrolünü İKİNCİ bir `create policy` olarak eklersek eski
-- `messages_insert_member` tek başına yetmeye devam eder ve engel hiç
-- uygulanmaz. Bu yüzden mevcut politika DROP edilip AND'li hâli yazılıyor.
drop policy if exists "messages_insert_member" on public.messages;

create policy "messages_insert_member" on public.messages
  for insert with check (
    -- Eski iki koşul AYNEN korunuyor (init.sql:192-196).
    (select auth.uid()) = sender_id
    and public.is_conversation_member(conversation_id, (select auth.uid()))
    -- YENİ: 1:1 sohbette karşı tarafla aramızda ÇİFT YÖNLÜ engel olmamalı.
    --
    -- `user_blocks` birincil anahtarı `(blocker_id, blocked_id)` — tek satır
    -- TEK yön demektir. "Ben onu engelledim" ve "o beni engelledi" ayrı
    -- satırlardır; ikisi de mesajlaşmayı kesmeli. `blocks_between` her iki
    -- yönü birden sorgular.
    --
    -- GRUP SOHBETLERİ BİLİNÇLİ OLARAK KAPSAM DIŞI (`is_group = false`):
    -- grupta "karşı taraf" tanımsızdır ve tek bir engelli çift N kişilik
    -- grubun tamamını kilitlerdi.
    and not exists (
      select 1
      from public.conversation_members m
      join public.conversations conv on conv.id = m.conversation_id
      where m.conversation_id = messages.conversation_id
        and conv.is_group = false
        and m.user_id <> (select auth.uid())
        and public.blocks_between((select auth.uid()), m.user_id)
    )
  );

-- ════════════════════════════════════════════════════════════════════════════
-- KALAN BİLİNÇLİ RİSK
-- ════════════════════════════════════════════════════════════════════════════
-- Bu göç MESAJ GÖNDERMEYİ kapatır; SOHBET AÇMAYI (`conversations` +
-- `conversation_members` insert) kapatmaz. Engellenen biri hâlâ boş bir sohbet
-- oluşturup engelleyenin listesinde görünebilir — mesaj gönderemez ama liste
-- kirliliği yaratabilir. `cmembers_insert` politikasını sıkılaştırmak bu
-- göçün kurduğu iki-insert akışını da etkileyeceği için ayrı bir turda,
-- iki oturumlu SQL doğrulamasıyla yapılmalıdır.
--
-- DOĞRULAMA (SQL editöründe, iki ayrı oturum):
--   1. A → B sohbet açar, mesaj atar               → BAŞARILI
--   2. B, A'yı engeller (user_blocks insert)       → BAŞARILI
--   3. A yeniden mesaj atmayı dener                → RLS ile REDDEDİLİR (42501)
--   4. B mesaj atmayı dener (ters yön)             → RLS ile REDDEDİLİR (42501)
--   4. adım kritiktir: security definer olmasaydı bu adım YANLIŞLIKLA geçerdi.
