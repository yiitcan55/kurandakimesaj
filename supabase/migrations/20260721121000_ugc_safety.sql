-- App Store Guideline 1.2: kullanıcı engelleme ve yorum raporlama.

create table public.user_blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint user_blocks_not_self check (blocker_id <> blocked_id)
);

alter table public.user_blocks enable row level security;

create policy "user_blocks_select_own" on public.user_blocks
  for select using (auth.uid() = blocker_id);
create policy "user_blocks_insert_own" on public.user_blocks
  for insert with check (auth.uid() = blocker_id);
create policy "user_blocks_delete_own" on public.user_blocks
  for delete using (auth.uid() = blocker_id);

create index user_blocks_blocked_idx
  on public.user_blocks (blocked_id);

alter table public.reports
  add column comment_id uuid references public.comments(id) on delete cascade;

-- Eski, hedefsiz kayıtlar migration'ı engellemesin; yeni kayıtlar tek hedefli olsun.
alter table public.reports
  add constraint reports_single_target
  check (num_nonnulls(post_id, comment_id) = 1) not valid;

create index reports_comment_idx on public.reports (comment_id)
  where comment_id is not null;
