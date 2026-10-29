-- Personal Music Library: skema database, RLS, dan Storage Policies
-- Jalankan seluruh file ini di Supabase Dashboard > SQL Editor > Run.

create table public.songs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 200),
  artist text not null default 'Unknown Artist',
  album text not null default 'Unknown Album',
  genre text not null default 'Other',
  year int check (year between 1900 and 2100),
  duration real not null default 0,
  size bigint not null default 0,
  file_path text not null,
  cover_path text,
  favorite boolean not null default false,
  plays int not null default 0,
  last_played timestamptz,
  created_at timestamptz not null default now()
);
create table public.playlists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 40),
  created_at timestamptz not null default now()
);
create table public.playlist_songs (
  playlist_id uuid not null references public.playlists(id) on delete cascade,
  song_id uuid not null references public.songs(id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (playlist_id, song_id)
);
create index on public.songs (user_id, created_at desc);
create index on public.playlists (user_id);
create index on public.playlist_songs (song_id);

-- Row Level Security: setiap pengguna hanya bisa mengakses datanya sendiri
alter table public.songs enable row level security;
alter table public.playlists enable row level security;
alter table public.playlist_songs enable row level security;

create policy songs_owner on public.songs for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy playlists_owner on public.playlists for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create policy ps_select on public.playlist_songs for select to authenticated
  using (user_id = (select auth.uid()));
create policy ps_insert on public.playlist_songs for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (select 1 from public.playlists p where p.id = playlist_id and p.user_id = (select auth.uid()))
    and exists (select 1 from public.songs s where s.id = song_id and s.user_id = (select auth.uid()))
  );
create policy ps_delete on public.playlist_songs for delete to authenticated
  using (user_id = (select auth.uid()));

-- Storage: bucket privat (file diputar lewat signed URL), batas 50 MB per file
insert into storage.buckets (id, name, public, file_size_limit)
values ('music', 'music', false, 52428800)
on conflict (id) do update set public = false, file_size_limit = 52428800;

-- Struktur path: <user_id>/audio/<file> dan <user_id>/covers/<file>
create policy music_select_own on storage.objects for select to authenticated
  using (bucket_id = 'music' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy music_insert_own on storage.objects for insert to authenticated
  with check (bucket_id = 'music' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy music_update_own on storage.objects for update to authenticated
  using (bucket_id = 'music' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy music_delete_own on storage.objects for delete to authenticated
  using (bucket_id = 'music' and (storage.foldername(name))[1] = (select auth.uid())::text);

-- Realtime: sinkronisasi antarperangkat
alter publication supabase_realtime add table public.songs, public.playlists, public.playlist_songs;
