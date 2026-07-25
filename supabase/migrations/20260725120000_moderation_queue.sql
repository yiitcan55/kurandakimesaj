-- MODERASYON KUYRUĞU — App Store Guideline 1.2: uygunsuz içeriği filtreleme yöntemi.
-- Her gönderi yayına girmeden önce admin onayından geçer (docs/legal/terms.html
-- zaten bunu vaat ediyor; bu migration o cümleyi doğru kılar).

-- ── feed_posts.status — onay durumu ──────────────────────────────────────────
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'feed_posts' and column_name = 'status'
  ) then
    alter table public.feed_posts
      add column status text not null default 'pending'
        check (status in ('pending','approved','rejected'));

    -- MEVCUT İÇERİK BİLEREK 'pending' BIRAKILIYOR.
    --
    -- İlk taslakta buraya `set status='approved'` yazmıştık ("akış boşalmasın"
    -- gerekçesiyle). Bu yanlıştı: uygulama tam da Guideline 1.2 (UGC) ile
    -- reddedildi, yani canlı veritabanındaki içerik HİÇ moderasyondan geçmedi.
    -- Hepsini görmeden onaylamak, Apple'a verilen "her gönderi yayına çıkmadan
    -- önce yönetici onayından geçer" beyanıyla doğrudan çelişirdi — inceleyici
    -- akışı kaydırıp ilk reddi tetikleyen içerikle karşılaşabilirdi.
    --
    -- Akış boş kalmaz: küratörlü "Günün Seçkileri" veritabanında değil,
    -- istemcide (`feedProvider`) — onaydan etkilenmez.
    --
    -- GÖNDERİM ÖNCESİ ADIM: /moderation → Bekleyenler kuyruğunu gözden geçirip
    -- uygun olanları onaylayın (bkz. docs/APP_REVIEW_RESPONSE.md, manuel adım 4a).
  end if;
end $$;

create index if not exists feed_posts_status_idx
  on public.feed_posts (status, created_at desc);

-- ── Yayın kapısı: onaylanmamış içerik yalnız sahibine görünür ────────────────
-- Kullanıcı kendi bekleyen/reddedilen gönderisini görebilsin ki "incelemede"
-- durumunu takip edebilsin; başkaları yalnız onaylanmış + gizlenmemiş görür.
drop policy if exists "feed_select_visible" on public.feed_posts;
create policy "feed_select_visible" on public.feed_posts
  for select using (
    (status = 'approved' and is_hidden = false) or auth.uid() = author_id
  );

-- ── profiles.is_admin — moderatör bayrağı ────────────────────────────────────
alter table public.profiles
  add column if not exists is_admin boolean not null default false;

-- KRİTİK — YETKİ YÜKSELTMEYİ ENGELLE: profiles_update_own (init.sql:35-36)
-- kullanıcının kendi satırını güncellemesine izin veriyor ve RLS with check
-- kolon bazlı ayrım yapamıyor; bu yüzden sütun ayrıcalığıyla kapatıyoruz —
-- RLS'ten önce çalışır, daha ucuz ve kesindir. Önce tabloya tanınmış geniş
-- UPDATE'i geri alıyoruz, sonra yalnız kullanıcının değiştirmesi gereken
-- kolonları yeniden veriyoruz. is_admin ve is_pro (ikincisini yalnız
-- revenuecat-webhook service_role ile yazar) SET listesine hiç giremez;
-- aksi halde her kullanıcı `update profiles set is_admin = true where id =
-- auth.uid()` ile kendini admin/pro yapıp tüm moderasyonu devre dışı
-- bırakabilirdi.
revoke update on public.profiles from authenticated, anon;
grant update (username, display_name, avatar_url, bio) on public.profiles to authenticated;

-- Aynı korumanın INSERT ayağı (savunma derinliği). Bugün ulaşılamıyor: profil
-- satırını handle_new_user tetikleyicisi oluşturuyor, ikinci bir insert PK
-- çakışmasına düşer. Ama bu kırılgan bir varsayım — ileride profiles_delete_own
-- gibi tek bir politika eklenirse kullanıcı satırını silip kendini is_admin
-- olarak yeniden yaratabilirdi. Yetki bayrakları insert'te de kilitli.
drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles
  for insert with check (
    (select auth.uid()) = id and is_admin = false and is_pro = false
  );

-- ── Admin politikaları ────────────────────────────────────────────────────────
-- reports: bugüne kadar yalnız reports_select_own vardı → admin dahil kimse
-- başkasının şikâyetini göremiyordu. Moderatör tüm raporları okuyabilsin.
drop policy if exists "reports_select_admin" on public.reports;
create policy "reports_select_admin" on public.reports
  for select using (
    exists (
      select 1 from public.profiles p
      where p.id = (select auth.uid()) and p.is_admin
    )
  );

-- feed_posts: admin bekleyen içeriği GÖREBİLSİN. Bu olmadan tek select
-- politikası feed_select_visible kalır ve o da `status='approved' ... or
-- auth.uid()=author_id` dediği için moderatör BAŞKASININ bekleyen gönderisini
-- hiç göremez → kuyruk her zaman boş görünür, onay akışı ölü doğar.
-- Permissive politikalar OR'lanır: bu ek politika yalnız is_admin olan çağıran
-- için açılır, normal kullanıcının görünürlüğünü genişletmez.
drop policy if exists "feed_select_admin" on public.feed_posts;
create policy "feed_select_admin" on public.feed_posts
  for select using (
    exists (
      select 1 from public.profiles p
      where p.id = (select auth.uid()) and p.is_admin
    )
  );

-- feed_posts: admin durum değiştirebilsin (onayla/reddet).
drop policy if exists "feed_update_admin" on public.feed_posts;
create policy "feed_update_admin" on public.feed_posts
  for update using (
    exists (
      select 1 from public.profiles p
      where p.id = (select auth.uid()) and p.is_admin
    )
  )
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = (select auth.uid()) and p.is_admin
    )
  );

-- ── Moderasyon kapısının GERÇEK zorlayıcısı ──────────────────────────────────
-- RLS tek başına YETMİYOR; adversaryal denetim iki bağımsız kaçak buldu:
--   1) INSERT — feed_insert_own'un with check'i yalnız author_id'ye bakıyor.
--      `default 'pending'` sadece istemci alanı HİÇ göndermediğinde işler;
--      payload'a açıkça status:'approved' konursa kuyruğa hiç girmeden yayına
--      çıkıyordu.
--   2) UPDATE — init.sql'deki feed_update_own hâlâ yürürlükte ve aynı komut
--      için permissive politikalar OR'lanır. Yazar kendi bekleyen gönderisini
--      `update feed_posts set status='approved'` ile kendisi onaylayabiliyordu;
--      feed_update_admin'in sıkı olması hiçbir şeyi değiştirmiyordu.
--
-- Sütun ayrıcalığı (yukarıda profiles'ta kullandığımız desen) burada ÇÖZÜM
-- DEĞİL: yönetici de `authenticated` rolünde, status'u rolden geri alsaydık
-- onay ekranı da kırılırdı. Ayrım satır bazlı (is_admin), Postgres kolon
-- grant'i ise rol bazlıdır.
--
-- Bu yüzden politika başına yama yerine TEK trigger: her yazma yolu buradan
-- geçer, yarın biri yeni bir permissive politika eklerse guard yürürlükte kalır.
-- Medya bağlantısı KENDİ depolamamızdaki KENDİ klasörünü mü gösteriyor?
--
-- Bu kolonlar istemci kontrolünde serbest metin. Doğrulanmazsa saldırgan kendi
-- sunucusunu gösterir: moderatör kuyrukta masum görseli görüp onaylar, sonra
-- saldırgan dosyayı değiştirir — hiçbir veritabanı yazımı gerekmeden uygunsuz
-- içerik yayına girer. Ayrıca akışı kaydıran HER kullanıcının IP'si ve
-- User-Agent'ı saldırganın sunucusuna düşer (moderatörünki dahil).
--
-- ponytail: host kalıbı `*.supabase.co` — kalan dar boşluk, saldırganın KENDİ
-- Supabase projesinde `post-media/<kendi-uid'si>/` yolunu kurmasıdır. Tam
-- kapatmak için aşağıdaki kalıbı bu projenin ref'iyle sabitleyin
-- (`^https://uytqxgcbohdlwwxemgyy\.supabase\.co/...`); bunu yapmadım çünkü
-- staging/yeni bir projeye geçildiğinde yüklemeler sessizce değil GÜRÜLTÜLÜ
-- kırılır ve nedeni geç anlaşılır. Tek satırlık değişiklik, karar sizin.
create or replace function public.is_own_post_media(url text, owner uuid)
returns boolean
language sql
immutable
as $$
  select url is null
      or url = ''
      or url ~ ('^https://[a-z0-9-]+\.supabase\.co/storage/v1/object/public/post-media/'
                || owner::text || '/');
$$;

create or replace function public.feed_posts_moderation_guard()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  caller uuid := (select auth.uid());
  caller_is_admin boolean;
begin
  -- auth.uid() null → service_role / sunucu tarafı (Edge Function). İstemci bu
  -- duruma düşemez: feed_insert_own zaten auth.uid() = author_id şartını arar.
  if caller is null then
    return new;
  end if;

  select coalesce(p.is_admin, false) into caller_is_admin
    from public.profiles p where p.id = caller;
  -- SİLME: `into`, eşleşen profiles satırı YOKSA hata atmaz — değişkeni NULL
  -- bırakır ve içerideki coalesce bunu yakalayamaz. O hâlde `if not
  -- caller_is_admin` NULL ile karşılaşıp dal HİÇ çalışmaz, yani guard sessizce
  -- devre dışı kalır. Aşağıdaki satır tam olarak bunu kapatıyor.
  caller_is_admin := coalesce(caller_is_admin, false);

  if not caller_is_admin then
    if not public.is_own_post_media(new.media_url, new.author_id)
       or not public.is_own_post_media(new.video_url, new.author_id)
       or not public.is_own_post_media(new.thumbnail_url, new.author_id) then
      raise exception 'Medya bağlantısı yalnızca kendi yüklediğin dosyayı gösterebilir.'
        using errcode = '42501';
    end if;
  end if;

  if tg_op = 'INSERT' then
    -- İstemci ne gönderirse göndersin, yeni içerik kuyruğa girer.
    if not caller_is_admin then
      new.status := 'pending';
      new.is_hidden := false;
    end if;
  else
    if not caller_is_admin then
      if new.status is distinct from old.status then
        raise exception 'İçerik durumunu yalnızca yönetici değiştirebilir.'
          using errcode = '42501';
      end if;
      -- is_hidden bir moderasyon alanı (uygulama onu yalnız okur, hiç yazmaz);
      -- yazar yöneticinin gizlemesini geri alamamalı.
      if new.is_hidden is distinct from old.is_hidden then
        raise exception 'İçeriği yalnızca yönetici gizleyebilir.'
          using errcode = '42501';
      end if;

      -- ONAY SONRASI DEĞİŞİKLİK → KUYRUĞA GERİ.
      -- Bu olmadan guard yalnız INSERT anını korur: yazar masum bir görselle
      -- onay alır, sonra `media_url`/`caption` alanlarını değiştirir ve satır
      -- 'approved' kalmaya devam eder. `feed_update_own` politikası bu yazıma
      -- izin verdiği için moderasyon kuyruğu tamamen atlatılmış olurdu.
      if (new.media_url, new.video_url, new.thumbnail_url, new.caption,
          new.meal, new.arabic, new.reference, new.kind, new.topic)
         is distinct from
         (old.media_url, old.video_url, old.thumbnail_url, old.caption,
          old.meal, old.arabic, old.reference, old.kind, old.topic)
      then
        new.status := 'pending';
      end if;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists feed_posts_moderation_guard_trg on public.feed_posts;
create trigger feed_posts_moderation_guard_trg
  before insert or update on public.feed_posts
  for each row execute function public.feed_posts_moderation_guard();

-- ── Yorum moderasyonu ────────────────────────────────────────────────────────
-- Yorumlar moderasyon sisteminin TAMAMEN dışındaydı: tek silme politikası
-- `comments_delete_own` olduğu için yöneticinin başkasının yorumunu kaldırma
-- yetkisi YOKTU. Moderasyon ekranı bunu itiraf ediyordu ("yorumu kaldırmak için
-- yazarını engelleyin"). Apple'ın 3. (şikâyet) ve 5. (24 saat içinde aksiyon)
-- şartları yorumlar için karşılanmıyordu — inceleyici bir yorumu bildirip
-- kaldırılmasını isterse elimizde hiçbir yol olmayacaktı.
drop policy if exists "comments_delete_admin" on public.comments;
create policy "comments_delete_admin" on public.comments
  for delete using (
    exists (
      select 1 from public.profiles p
      where p.id = (select auth.uid()) and p.is_admin
    )
  );

-- Onaylanmamış/gizlenmiş gönderinin yorumları da sızmasın: `comments_select_all`
-- koşulsuz `using (true)` idi — post_id'yi bilen herkes, ana gönderi kendisine
-- görünmese bile o gönderinin yorum metinlerini okuyabiliyordu.
drop policy if exists "comments_select_all" on public.comments;
drop policy if exists "comments_select_visible" on public.comments;
create policy "comments_select_visible" on public.comments
  for select using (
    -- Kendi yorumun her zaman görünür. Bu dal yalnız nezaket değil GEREKLİ:
    -- `deleteComment` silinen satırı `.select('id')` ile geri istiyor (RLS
    -- reddi DELETE'te 403 değil sessizce 0 satırdır, o yüzden dönen satır
    -- sayısı kontrol ediliyor) ve Postgres RETURNING'i SELECT politikasından
    -- geçirir. Bu dal olmasaydı, reddedilmiş bir gönderideki kendi yorumunu
    -- silen kullanıcı silme başarılı olduğu hâlde hata mesajı görürdü.
    comments.user_id = (select auth.uid())
    or exists (
      select 1 from public.feed_posts f
      where f.id = comments.post_id
        and ((f.status = 'approved' and f.is_hidden = false)
             or f.author_id = (select auth.uid()))
    )
    or exists (
      select 1 from public.profiles p
      where p.id = (select auth.uid()) and p.is_admin
    )
  );

-- ── Çift politika temizliği: follows ─────────────────────────────────────────
-- 20260630120000_follows.sql, init'teki kapsamı BÜYÜK HARF + tırnaklı Türkçe
-- adlarla tekrar tanımlamıştı; "Kendi takibini yönetir" FOR ALL olduğundan
-- (with check yazılmadığı için using ifadesi check olarak da kullanılır)
-- init'te hiç olmayan bir UPDATE yetkisi açıyordu — kullanıcı kendi follows
-- satırının following_id'sini istediği gibi değiştirebiliyordu. init'in
-- follows_select_all / follows_insert_own / follows_delete_own'ı zaten
-- yeterli; çakışan ikiliyi kaldırıyoruz.
drop policy if exists "Herkes okuyabilir" on public.follows;
drop policy if exists "Kendi takibini yönetir" on public.follows;
