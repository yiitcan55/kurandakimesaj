-- MEAL DÜZENLE — videoya zaman çizelgeli altyazı (meal cue) kolonları.
--
-- `meal_cues`: [{"s":0.0,"e":4.2,"su":2,"a":255}, ...] — yalnız SAYI içerir
-- (başlangıç sn, bitiş sn, sure no, ayet no). Serbest metin YOK: ekranda
-- görünen ayet/meal metni istemcide paketli Kur'an verisinden çizilir, bu
-- yüzden kolon moderatörün görmediği bir metin taşıyamaz.
-- `meal_cue_style`: 'default' | 'large' | 'arabic' (yalnız görünüm tercihi).
--
-- DOKUNULMAYANLAR: `feed_posts_moderation_guard` (yeniden tanımlanmadı,
-- trigger'ına dokunulmadı), `feed_select_visible` / `feed_select_admin`,
-- `is_own_post_media`, `revoke update on profiles`.

-- ════════════════════════════════════════════════════════════════════════════
-- 1. KOLONLAR
-- ════════════════════════════════════════════════════════════════════════════
alter table public.feed_posts
  add column if not exists meal_cues jsonb,
  add column if not exists meal_cue_style text;

-- ════════════════════════════════════════════════════════════════════════════
-- 2. DOĞRULAMA FONKSİYONU
-- ════════════════════════════════════════════════════════════════════════════
-- Bozuk girdi İSTİSNA ATMAZ, false döner. SQL operand sırasını garanti
-- etmediği için her tip kontrolü CASE içinde, cast'ten ÖNCE yapılır
-- (jsonb_array_length / jsonb_array_elements dizi olmayan değerde, ::numeric
-- sayı olmayan değerde patlardı).
create or replace function public.is_valid_meal_cues(c jsonb)
returns boolean
language sql
immutable
set search_path = public
as $$
  select case
    when c is null or jsonb_typeof(c) <> 'array' then false
    when jsonb_array_length(c) not between 1 and 60 then false
    else not exists (
      select 1
        from jsonb_array_elements(c) as e
       where not (
         case
           when jsonb_typeof(e) <> 'object' then false
           -- TAM dört anahtar: sayı 4 ve dördü de var → başka anahtar yok.
           when (select count(*) from jsonb_object_keys(e)) <> 4 then false
           when not (e ?& array['s', 'e', 'su', 'a']) then false
           when jsonb_typeof(e -> 's')  <> 'number'
             or jsonb_typeof(e -> 'e')  <> 'number'
             or jsonb_typeof(e -> 'su') <> 'number'
             or jsonb_typeof(e -> 'a')  <> 'number' then false
           else
             (e ->> 's')::numeric >= 0
             and (e ->> 'e')::numeric > (e ->> 's')::numeric
             and (e ->> 'e')::numeric <= 7200
             and (e ->> 'su')::numeric = trunc((e ->> 'su')::numeric)
             and (e ->> 'su')::numeric between 1 and 114
             and (e ->> 'a')::numeric = trunc((e ->> 'a')::numeric)
             and (e ->> 'a')::numeric between 1 and 286
         end
       )
    )
  end;
$$;

-- ════════════════════════════════════════════════════════════════════════════
-- 3. KISITLAR (idempotent — reels_kind.sql kalıbı)
-- ════════════════════════════════════════════════════════════════════════════
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.feed_posts'::regclass
      and conname = 'feed_posts_meal_cues_check'
  ) then
    alter table public.feed_posts
      add constraint feed_posts_meal_cues_check
      check (meal_cues is null
             or (kind = 'video' and public.is_valid_meal_cues(meal_cues)));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.feed_posts'::regclass
      and conname = 'feed_posts_meal_cue_style_check'
  ) then
    alter table public.feed_posts
      add constraint feed_posts_meal_cue_style_check
      check (meal_cue_style is null
             or meal_cue_style in ('default', 'large', 'arabic'));
  end if;
end $$;

-- ════════════════════════════════════════════════════════════════════════════
-- 4. "BİR KEZ YAZILIR" TETİKLEYİCİSİ
-- ════════════════════════════════════════════════════════════════════════════
-- Yayınlandıktan sonra istemci cue'ları değiştiremez. auth.uid() null →
-- service_role / sunucu (Edge Function, panel) serbest; admin istemcisi dahil
-- her kullanıcı oturumu kilitli.
create or replace function public.feed_posts_meal_cues_lock()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if (select auth.uid()) is not null
     and (new.meal_cues is distinct from old.meal_cues
          or new.meal_cue_style is distinct from old.meal_cue_style) then
    raise exception 'Altyazı zaman çizelgesi yayınlandıktan sonra değiştirilemez.'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists feed_posts_meal_cues_lock_trg on public.feed_posts;
create trigger feed_posts_meal_cues_lock_trg
  before update on public.feed_posts
  for each row execute function public.feed_posts_meal_cues_lock();

-- ════════════════════════════════════════════════════════════════════════════
-- MODERASYON TETİKLEYİCİSİYLE İLİŞKİ — BİLİNÇLİ KARAR
-- ════════════════════════════════════════════════════════════════════════════
-- `feed_posts_moderation_guard` (20260725120000_moderation_queue.sql) onay
-- SONRASI değişiklikte satırı yeniden kuyruğa atan demete `meal_cues` /
-- `meal_cue_style` EKLENMEDİ.
--
-- `audio_track_id` emsali (reel_audio.sql: FK ile küratörlü tabloya kilitli,
-- bu yüzden demete girmedi) burada GEÇERLİ DEĞİL: cue = "hangi video, hangi
-- ayet, hangi saniye" eşleşmesidir ve bu eşleşme içeriğin kendisidir; önceden
-- onaylanmış bir değer kümesi yoktur. Doğru çare demete eklemek değil,
-- DEĞİŞMEZLİK: cue yayınlandıktan sonra hiç değişemez (yukarıdaki ayrı
-- trigger), dolayısıyla moderatörün onayladığı eşleşme onay sonrası
-- kaydırılamaz. Guard'ı yeniden tanımlamak onun güvenlik gövdesine dokunmak
-- olurdu; ayrı trigger bunu önler.
--
-- INSERT tarafında ek bir şey gerekmez: guard zaten `status := 'pending'`
-- yazıyor (moderation_queue.sql:192-197). Kapı ZAYIFLAMIYOR.
--
-- DOĞRULAMA SONDALARI — kullanıcı oturumunda koşulacak SQL (yorum):
--   -- 1) fazladan anahtar → 23514
--   insert into feed_posts (author_id, kind, meal_cues)
--   values (auth.uid(), 'video',
--           '[{"s":0,"e":3,"su":1,"a":1,"x":1}]'::jsonb);
--   -- 2) su = 115 → 23514
--   insert into feed_posts (author_id, kind, meal_cues)
--   values (auth.uid(), 'video', '[{"s":0,"e":3,"su":115,"a":1}]'::jsonb);
--   -- 3) kind = 'still' iken meal_cues → 23514
--   insert into feed_posts (author_id, kind, meal_cues)
--   values (auth.uid(), 'still', '[{"s":0,"e":3,"su":1,"a":1}]'::jsonb);
--   -- 4) geçerli ekleme → status = 'pending'
--   insert into feed_posts (author_id, kind, meal_cues, meal_cue_style)
--   values (auth.uid(), 'video', '[{"s":0,"e":3,"su":1,"a":1}]'::jsonb, 'large')
--   returning id, status;                      -- status = 'pending'
--   -- 5) yazarın meal_cues güncellemesi → 42501
--   update feed_posts set meal_cues = '[{"s":0,"e":4,"su":1,"a":2}]'::jsonb
--    where id = '<4. adımdaki id>';
--   -- 6) onaylı satırda caption değişince status 'pending'e döner
--   --    (guard hâlâ çalışıyor; admin ile önce status='approved' yap):
--   update feed_posts set caption = caption || ' ' where id = '<onaylı id>'
--   returning status;                          -- 'pending'
--   -- 7) fonksiyon asla istisna atmaz, hep false: boş dizi, [null],
--   --    string sayı, ondalık su, negatif s
--   select public.is_valid_meal_cues('[]'),
--          public.is_valid_meal_cues('[null]'),
--          public.is_valid_meal_cues('[{"s":"0","e":3,"su":1,"a":1}]'),
--          public.is_valid_meal_cues('[{"s":0,"e":3,"su":1.5,"a":1}]'),
--          public.is_valid_meal_cues('[{"s":-1,"e":3,"su":1,"a":1}]'),
--          public.is_valid_meal_cues('{}'),
--          public.is_valid_meal_cues(null);      -- hepsi false
