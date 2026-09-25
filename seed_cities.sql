-- Re-seed Cities for Malaysia
do $$
declare
  selangor_id uuid;
  kl_id uuid;
  johor_id uuid;
  penang_id uuid;
  perak_id uuid;
  kedah_id uuid;
  sabah_id uuid;
  sarawak_id uuid;
begin
  -- Get Region IDs (Case insensitive search just in case)
  select id into selangor_id from public.regions where lower(name) = 'selangor' limit 1;
  select id into kl_id from public.regions where lower(name) = 'kuala lumpur' limit 1;
  select id into johor_id from public.regions where lower(name) = 'johor' limit 1;
  select id into penang_id from public.regions where lower(name) = 'penang' limit 1;
  select id into perak_id from public.regions where lower(name) = 'perak' limit 1;
  select id into kedah_id from public.regions where lower(name) = 'kedah' limit 1;
  select id into sabah_id from public.regions where lower(name) = 'sabah' limit 1;
  select id into sarawak_id from public.regions where lower(name) = 'sarawak' limit 1;

  -- Insert Cities (Safe inserts)
  
  -- Selangor
  if selangor_id is not null then
    insert into public.cities (region_id, name) values
      (selangor_id, 'Shah Alam'),
      (selangor_id, 'Petaling Jaya'),
      (selangor_id, 'Subang Jaya'),
      (selangor_id, 'Klang'),
      (selangor_id, 'Puchong'),
      (selangor_id, 'Cyberjaya'),
      (selangor_id, 'Sepang'),
      (selangor_id, 'Kajang'),
      (selangor_id, 'Rawang'),
      (selangor_id, 'Selayang'),
      (selangor_id, 'Ampang')
    on conflict (name, region_id) do nothing;
  end if;

  -- Kuala Lumpur
  if kl_id is not null then
     insert into public.cities (region_id, name) values
      (kl_id, 'Kuala Lumpur'),
      (kl_id, 'Cheras'),
      (kl_id, 'Kepong'),
      (kl_id, 'Setapak'),
      (kl_id, 'Bangsar'),
      (kl_id, 'Mont Kiara'),
      (kl_id, 'Bukit Bintang')
    on conflict (name, region_id) do nothing;
  end if;

  -- Johor
  if johor_id is not null then
     insert into public.cities (region_id, name) values
      (johor_id, 'Johor Bahru'),
      (johor_id, 'Iskandar Puteri'),
      (johor_id, 'Batu Pahat'),
      (johor_id, 'Muar'),
      (johor_id, 'Kluang'),
      (johor_id, 'Kulai')
    on conflict (name, region_id) do nothing;
  end if;
  
   -- Penang
  if penang_id is not null then
     insert into public.cities (region_id, name) values
      (penang_id, 'George Town'),
      (penang_id, 'Bayan Lepas'),
      (penang_id, 'Butterworth'),
      (penang_id, 'Bukit Mertajam')
    on conflict (name, region_id) do nothing;
  end if;

  -- Perak
  if perak_id is not null then
     insert into public.cities (region_id, name) values
      (perak_id, 'Ipoh'),
      (perak_id, 'Taiping'),
      (perak_id, 'Manjung'),
      (perak_id, 'Teluk Intan')
    on conflict (name, region_id) do nothing;
  end if;

  -- Sabah
  if sabah_id is not null then
     insert into public.cities (region_id, name) values
      (sabah_id, 'Kota Kinabalu'),
      (sabah_id, 'Sandakan'),
      (sabah_id, 'Tawau')
    on conflict (name, region_id) do nothing;
  end if;

   -- Sarawak
  if sarawak_id is not null then
     insert into public.cities (region_id, name) values
      (sarawak_id, 'Kuching'),
      (sarawak_id, 'Miri'),
      (sarawak_id, 'Sibu'),
      (sarawak_id, 'Bintulu')
    on conflict (name, region_id) do nothing;
  end if;

end $$;

-- Verify results
select r.name as state, count(c.id) as city_count 
from public.regions r 
left join public.cities c on r.id = c.region_id 
group by r.name 
order by city_count desc;
