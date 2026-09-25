-- Enable UUID extension if not enabled
create extension if not exists "uuid-ossp";

-- Create regions table (States)
create table if not exists public.regions (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  code text, -- e.g. SGR for Selangor
  country_code text default 'MY',
  is_active boolean default true,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create cities table
create table if not exists public.cities (
  id uuid default uuid_generate_v4() primary key,
  region_id uuid references public.regions(id) on delete cascade,
  name text not null,
  postcode_prefix text, -- Optional, helpful for validation
  is_active boolean default true,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.regions enable row level security;
alter table public.cities enable row level security;

-- RLS Policies
-- Everyone can read active regions/cities
create policy "Public can read active regions"
  on public.regions for select
  using (is_active = true);

create policy "Public can read active cities"
  on public.cities for select
  using (is_active = true);

-- Only service_role or admin (if you have an admin role system) can insert/update/delete
-- For simplicity in development, we'll allow authenticated users to READ only.
-- Service role has full access by default.

-- SEED DATA (Malaysia)
insert into public.regions (name, code) values
  ('Selangor', 'SGR'),
  ('Kuala Lumpur', 'KUL'),
  ('Johor', 'JHR'),
  ('Penang', 'PNG'),
  ('Perak', 'PRK'),
  ('Kedah', 'KDH'),
  ('Pahang', 'PHG'),
  ('Negeri Sembilan', 'NSN'),
  ('Melaka', 'MLK'),
  ('Terengganu', 'TRG'),
  ('Kelantan', 'KTN'),
  ('Perlis', 'PLS'),
  ('Sabah', 'SBH'),
  ('Sarawak', 'SWK'),
  ('Putrajaya', 'PJY'),
  ('Labuan', 'LBN')
on conflict do nothing; -- Ideally name should be unique, but we didn't set unique constraint in create table for brevity.

-- Seed Cities (Sample for major states)
-- We need to get IDs to insert cities. Using DO block.
do $$
declare
  selangor_id uuid;
  kl_id uuid;
  johor_id uuid;
  penang_id uuid;
begin
  select id into selangor_id from public.regions where name = 'Selangor';
  select id into kl_id from public.regions where name = 'Kuala Lumpur';
  select id into johor_id from public.regions where name = 'Johor';
  select id into penang_id from public.regions where name = 'Penang';

  -- Selangor Cities
  if selangor_id is not null then
    insert into public.cities (region_id, name) values
      (selangor_id, 'Shah Alam'),
      (selangor_id, 'Petaling Jaya'),
      (selangor_id, 'Subang Jaya'),
      (selangor_id, 'Klang'),
      (selangor_id, 'Puchong'),
      (selangor_id, 'Cyberjaya'),
      (selangor_id, 'Sepang'),
      (selangor_id, 'Kajang');
  end if;

  -- KL Cities
  if kl_id is not null then
     insert into public.cities (region_id, name) values
      (kl_id, 'Kuala Lumpur'),
      (kl_id, 'Cheras'),
      (kl_id, 'Kepong'),
      (kl_id, 'Setapak'),
      (kl_id, 'Bangsar');
  end if;

  -- Johor Cities
  if johor_id is not null then
     insert into public.cities (region_id, name) values
      (johor_id, 'Johor Bahru'),
      (johor_id, 'Iskandar Puteri'),
      (johor_id, 'Batu Pahat'),
      (johor_id, 'Muar'),
      (johor_id, 'Kluang');
  end if;
  
   -- Penang Cities
  if penang_id is not null then
     insert into public.cities (region_id, name) values
      (penang_id, 'George Town'),
      (penang_id, 'Bayan Lepas'),
      (penang_id, 'Butterworth'),
      (penang_id, 'Bukit Mertajam');
  end if;

end $$;
