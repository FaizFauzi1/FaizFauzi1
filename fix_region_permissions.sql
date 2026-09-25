-- 1. Grant usage on schema (usually enabled, but good to ensure)
grant usage on schema public to anon, authenticated;

-- 2. Grant permissions on tables
grant select on table public.regions to anon, authenticated;
grant select on table public.cities to anon, authenticated;

-- 3. Verify Policies (Drop and Recreate to be sure)
drop policy if exists "Public can read active regions" on public.regions;
create policy "Public can read active regions"
  on public.regions for select
  to anon, authenticated
  using (is_active = true);

drop policy if exists "Public can read active cities" on public.cities;
create policy "Public can read active cities"
  on public.cities for select
  to anon, authenticated
  using (is_active = true);

-- 4. Re-Seed Regions (in case previous insert failed or was missed)
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
on conflict do nothing;

-- 5. Re-Seed Cities (Sample)
do $$
declare
  selangor_id uuid;
  kl_id uuid;
  johor_id uuid;
begin
  select id into selangor_id from public.regions where name = 'Selangor';
  select id into kl_id from public.regions where name = 'Kuala Lumpur';
  select id into johor_id from public.regions where name = 'Johor';

  if selangor_id is not null then
    -- Check if cities exist before inserting to avoid duplicates if unique constraint missing
    if not exists (select 1 from public.cities where region_id = selangor_id and name = 'Shah Alam') then
       insert into public.cities (region_id, name) values (selangor_id, 'Shah Alam');
    end if;
    if not exists (select 1 from public.cities where region_id = selangor_id and name = 'Petaling Jaya') then
       insert into public.cities (region_id, name) values (selangor_id, 'Petaling Jaya');
    end if;
     if not exists (select 1 from public.cities where region_id = selangor_id and name = 'Subang Jaya') then
       insert into public.cities (region_id, name) values (selangor_id, 'Subang Jaya');
    end if;
     if not exists (select 1 from public.cities where region_id = selangor_id and name = 'Klang') then
       insert into public.cities (region_id, name) values (selangor_id, 'Klang');
    end if;
  end if;

  if kl_id is not null then
    if not exists (select 1 from public.cities where region_id = kl_id and name = 'Kuala Lumpur') then
       insert into public.cities (region_id, name) values (kl_id, 'Kuala Lumpur');
    end if;
  end if;
  
   if johor_id is not null then
    if not exists (select 1 from public.cities where region_id = johor_id and name = 'Johor Bahru') then
       insert into public.cities (region_id, name) values (johor_id, 'Johor Bahru');
    end if;
  end if;

end $$;
