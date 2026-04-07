-- Create gems table matching StorageService column expectations
create table public.gems (
  id text primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  transcript text not null,
  title text,
  duration_seconds integer,
  tags text[] default '{}',
  audio_url text,
  saved_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

-- Index for user-scoped queries (fetchGemsFromSupabase filters by user_id)
create index gems_user_id_idx on public.gems(user_id);
create index gems_saved_at_idx on public.gems(saved_at desc);

-- RLS: each user can only access their own gems
alter table public.gems enable row level security;

create policy "Users read own gems"
  on public.gems for select
  using (auth.uid() = user_id);

create policy "Users insert own gems"
  on public.gems for insert
  with check (auth.uid() = user_id);

create policy "Users update own gems"
  on public.gems for update
  using (auth.uid() = user_id);

create policy "Users delete own gems"
  on public.gems for delete
  using (auth.uid() = user_id);
