-- Kur'an'da ki Mesaj — Supabase şeması (tablolar + RLS default-deny + trigger + Realtime + Storage).
-- Kural: RLS HER tabloda açık; dini metin (esma/ayet/dua) burada DURMAZ (istemci drift seed'inde, değiştirilemez).
-- service_role asla istemcide; tüm istemci erişimi anon/authenticated + RLS ile.

-- ── Uzantılar ───────────────────────────────────────────────────────────────
create extension if not exists pgcrypto;      -- gen_random_uuid()
create extension if not exists pg_cron;        -- günlük içerik rotasyonu
create extension if not exists pg_net;         -- cron → Edge Function (opsiyonel)

-- ── updated_at yardımcı trigger ──────────────────────────────────────────────
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end; $$;

-- ════════════════════════════════════════════════════════════════════════════
-- PROFILES — auth.users'a 1-1, herkese okunur, sahibi günceller.
-- ════════════════════════════════════════════════════════════════════════════
create table public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  username     text unique,
  display_name text,
  avatar_url   text,
  bio          text,
  is_pro       boolean not null default false,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
alter table public.profiles enable row level security;

create policy "profiles_select_all" on public.profiles
  for select using (true);
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);
create policy "profiles_insert_own" on public.profiles
  for insert with check (auth.uid() = id);

create trigger profiles_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();

-- Yeni kullanıcı → profil oluştur.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)))
  on conflict (id) do nothing;
  return new;
end; $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ════════════════════════════════════════════════════════════════════════════
-- FEED_POSTS — topluluk akışı (ayet kartı / video). Herkese okunur, sahibi yazar.
-- ════════════════════════════════════════════════════════════════════════════
create table public.feed_posts (
  id          uuid primary key default gen_random_uuid(),
  author_id   uuid not null references public.profiles(id) on delete cascade,
  kind        text not null default 'ayah' check (kind in ('ayah','video')),
  reference   text,
  arabic      text,
  meal        text,
  caption     text,
  media_url   text,          -- storage: post-media bucket
  topic       text,
  like_count  integer not null default 0,
  is_hidden   boolean not null default false,  -- moderasyon
  created_at  timestamptz not null default now()
);
alter table public.feed_posts enable row level security;

create index feed_posts_created_idx on public.feed_posts (created_at desc);
create index feed_posts_author_idx on public.feed_posts (author_id);

create policy "feed_select_visible" on public.feed_posts
  for select using (is_hidden = false or auth.uid() = author_id);
create policy "feed_insert_own" on public.feed_posts
  for insert with check (auth.uid() = author_id);
create policy "feed_update_own" on public.feed_posts
  for update using (auth.uid() = author_id) with check (auth.uid() = author_id);
create policy "feed_delete_own" on public.feed_posts
  for delete using (auth.uid() = author_id);

-- ════════════════════════════════════════════════════════════════════════════
-- LIKES — (post, kullanıcı) tekil; like_count tetikleyici ile tutulur.
-- ════════════════════════════════════════════════════════════════════════════
create table public.likes (
  post_id    uuid not null references public.feed_posts(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);
alter table public.likes enable row level security;

create policy "likes_select_all" on public.likes for select using (true);
create policy "likes_insert_own" on public.likes
  for insert with check (auth.uid() = user_id);
create policy "likes_delete_own" on public.likes
  for delete using (auth.uid() = user_id);

create or replace function public.sync_like_count()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if (tg_op = 'INSERT') then
    update public.feed_posts set like_count = like_count + 1 where id = new.post_id;
  elsif (tg_op = 'DELETE') then
    update public.feed_posts set like_count = greatest(0, like_count - 1) where id = old.post_id;
  end if;
  return null;
end; $$;

create trigger likes_count_trigger
  after insert or delete on public.likes
  for each row execute function public.sync_like_count();

-- ════════════════════════════════════════════════════════════════════════════
-- FOLLOWS — takip grafiği.
-- ════════════════════════════════════════════════════════════════════════════
create table public.follows (
  follower_id  uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at   timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);
alter table public.follows enable row level security;

create policy "follows_select_all" on public.follows for select using (true);
create policy "follows_insert_own" on public.follows
  for insert with check (auth.uid() = follower_id);
create policy "follows_delete_own" on public.follows
  for delete using (auth.uid() = follower_id);

-- ════════════════════════════════════════════════════════════════════════════
-- MESAJLAŞMA — conversations + members + messages (Realtime).
-- ════════════════════════════════════════════════════════════════════════════
create table public.conversations (
  id         uuid primary key default gen_random_uuid(),
  title      text,
  is_group   boolean not null default false,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);
alter table public.conversations enable row level security;

create table public.conversation_members (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id         uuid not null references public.profiles(id) on delete cascade,
  joined_at       timestamptz not null default now(),
  primary key (conversation_id, user_id)
);
alter table public.conversation_members enable row level security;

create table public.messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id       uuid not null references public.profiles(id) on delete cascade,
  body            text not null,
  created_at      timestamptz not null default now()
);
alter table public.messages enable row level security;
create index messages_conversation_idx on public.messages (conversation_id, created_at);

-- Üyelik kontrolü (recursion'suz) için yardımcı.
create or replace function public.is_conversation_member(conv uuid, uid uuid)
returns boolean language sql security definer stable set search_path = public as $$
  select exists (
    select 1 from public.conversation_members m
    where m.conversation_id = conv and m.user_id = uid
  );
$$;

create policy "conv_select_member" on public.conversations
  for select using (public.is_conversation_member(id, auth.uid()));
create policy "conv_insert_own" on public.conversations
  for insert with check (auth.uid() = created_by);

create policy "cmembers_select_self_conv" on public.conversation_members
  for select using (public.is_conversation_member(conversation_id, auth.uid()));
create policy "cmembers_insert" on public.conversation_members
  for insert with check (
    auth.uid() = user_id
    or public.is_conversation_member(conversation_id, auth.uid())
  );

create policy "messages_select_member" on public.messages
  for select using (public.is_conversation_member(conversation_id, auth.uid()));
create policy "messages_insert_member" on public.messages
  for insert with check (
    auth.uid() = sender_id
    and public.is_conversation_member(conversation_id, auth.uid())
  );

-- ════════════════════════════════════════════════════════════════════════════
-- HATİM HALKALARI — circle + cüz üstlenme.
-- ════════════════════════════════════════════════════════════════════════════
create table public.khatm_circles (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  owner_id   uuid not null references public.profiles(id) on delete cascade,
  is_public  boolean not null default true,
  created_at timestamptz not null default now()
);
alter table public.khatm_circles enable row level security;

create table public.khatm_claims (
  circle_id   uuid not null references public.khatm_circles(id) on delete cascade,
  juz_number  integer not null check (juz_number between 1 and 30),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  completed   boolean not null default false,
  updated_at  timestamptz not null default now(),
  primary key (circle_id, juz_number)
);
alter table public.khatm_claims enable row level security;

create policy "khatm_select_public" on public.khatm_circles
  for select using (is_public = true or auth.uid() = owner_id);
create policy "khatm_insert_own" on public.khatm_circles
  for insert with check (auth.uid() = owner_id);
create policy "khatm_delete_own" on public.khatm_circles
  for delete using (auth.uid() = owner_id);

create policy "claims_select_all" on public.khatm_claims for select using (true);
create policy "claims_insert_own" on public.khatm_claims
  for insert with check (auth.uid() = user_id);
create policy "claims_update_own" on public.khatm_claims
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "claims_delete_own" on public.khatm_claims
  for delete using (auth.uid() = user_id);

-- ════════════════════════════════════════════════════════════════════════════
-- BULUT SENKRONU — dhikr sayaçları + koleksiyonlar (offline→online).
-- ════════════════════════════════════════════════════════════════════════════
create table public.cloud_dhikr (
  user_id    uuid not null references public.profiles(id) on delete cascade,
  date_iso   text not null,
  dhikr_key  text not null,
  count      integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (user_id, date_iso, dhikr_key)
);
alter table public.cloud_dhikr enable row level security;
create policy "cloud_dhikr_own" on public.cloud_dhikr
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table public.cloud_collections (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  reference  text not null,
  arabic     text not null,
  meal       text not null,
  note       text,
  created_at timestamptz not null default now()
);
alter table public.cloud_collections enable row level security;
create policy "cloud_collections_own" on public.cloud_collections
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ════════════════════════════════════════════════════════════════════════════
-- RENDER JOBS — ayet→video render kuyruğu (worker sunucu tarafında işler).
-- ════════════════════════════════════════════════════════════════════════════
create table public.render_jobs (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  template   text not null,
  reciter    text not null,
  reference  text,
  arabic     text,
  meal       text,
  status     text not null default 'queued' check (status in ('queued','processing','done','failed')),
  output_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.render_jobs enable row level security;
create policy "render_select_own" on public.render_jobs
  for select using (auth.uid() = user_id);
create policy "render_insert_own" on public.render_jobs
  for insert with check (auth.uid() = user_id);
-- status güncellemesi yalnızca worker (service_role) tarafından; istemciye update izni YOK.

create trigger render_updated_at before update on public.render_jobs
  for each row execute function public.set_updated_at();

-- ════════════════════════════════════════════════════════════════════════════
-- DONATIONS — bağış kaydı (donation-verify Edge Function ile doğrulanır).
-- ════════════════════════════════════════════════════════════════════════════
create table public.donations (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid references public.profiles(id) on delete set null,
  campaign     text not null,
  amount       numeric(12,2),
  status       text not null default 'pending' check (status in ('pending','verified','failed')),
  provider_ref text,
  created_at   timestamptz not null default now()
);
alter table public.donations enable row level security;
create policy "donations_select_own" on public.donations
  for select using (auth.uid() = user_id);
create policy "donations_insert_own" on public.donations
  for insert with check (auth.uid() = user_id);

-- ════════════════════════════════════════════════════════════════════════════
-- REPORTS — moderasyon şikâyetleri.
-- ════════════════════════════════════════════════════════════════════════════
create table public.reports (
  id          uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  post_id     uuid references public.feed_posts(id) on delete cascade,
  reason      text,
  created_at  timestamptz not null default now()
);
alter table public.reports enable row level security;
create policy "reports_insert_own" on public.reports
  for insert with check (auth.uid() = reporter_id);
create policy "reports_select_own" on public.reports
  for select using (auth.uid() = reporter_id);

-- ════════════════════════════════════════════════════════════════════════════
-- GÜNLÜK İÇERİK — pg_cron ile her gün dönen ayet referansı.
-- ════════════════════════════════════════════════════════════════════════════
create table public.daily_content (
  day        date primary key default current_date,
  reference  text,
  arabic     text,
  meal       text,
  created_at timestamptz not null default now()
);
alter table public.daily_content enable row level security;
create policy "daily_content_select_all" on public.daily_content for select using (true);

-- Cron: her gün 00:05'te daily-content Edge Function'ı tetikle (pg_net ile).
-- NOT: <PROJECT_REF> ve service_role anahtarını deploy sonrası ayarla.
-- select cron.schedule('daily-content', '5 0 * * *', $$
--   select net.http_post(
--     url := 'https://<PROJECT_REF>.functions.supabase.co/daily-content',
--     headers := jsonb_build_object('Authorization', 'Bearer <SERVICE_ROLE_KEY>')
--   );
-- $$);

-- ════════════════════════════════════════════════════════════════════════════
-- REALTIME — istemcinin dinleyebilmesi için publication'a ekle.
-- ════════════════════════════════════════════════════════════════════════════
alter publication supabase_realtime add table public.feed_posts;
alter publication supabase_realtime add table public.likes;
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.khatm_claims;
alter publication supabase_realtime add table public.render_jobs;
