-- COMMENTS — gönderi/reel yorumları. `likes` + `sync_like_count` kalıbının ikizi.
-- Herkese okunur, sahibi yazar/siler; feed_posts.comment_count trigger ile tutulur.

alter table public.feed_posts
  add column if not exists comment_count integer not null default 0;

create table if not exists public.comments (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references public.feed_posts(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  body       text not null check (char_length(body) between 1 and 2000),
  created_at timestamptz not null default now()
);
alter table public.comments enable row level security;

create index if not exists comments_post_idx on public.comments (post_id, created_at);

create policy "comments_select_all" on public.comments for select using (true);
create policy "comments_insert_own" on public.comments
  for insert with check (auth.uid() = user_id);
create policy "comments_delete_own" on public.comments
  for delete using (auth.uid() = user_id);

-- comment_count senkronu (sync_like_count 105-118 birebir kalıbı).
create or replace function public.sync_comment_count()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if (tg_op = 'INSERT') then
    update public.feed_posts set comment_count = comment_count + 1 where id = new.post_id;
  elsif (tg_op = 'DELETE') then
    update public.feed_posts set comment_count = greatest(0, comment_count - 1) where id = old.post_id;
  end if;
  return null;
end; $$;

create trigger comments_count_trigger
  after insert or delete on public.comments
  for each row execute function public.sync_comment_count();

-- Realtime (feed_posts/likes zaten publication'da).
alter publication supabase_realtime add table public.comments;
