-- 1. Remove duplicate Cities first (keep latest)
delete from public.cities
where id in (
  select id from (
    select id,
           row_number() over (partition by name, region_id order by created_at desc) as r_num
    from public.cities
  ) t
  where t.r_num > 1
);

-- 2. Remove duplicate Regions (Prioritize those with cities)
delete from public.regions
where id in (
  select id from (
    select r.id,
           r.name,
           (select count(*) from public.cities c where c.region_id = r.id) as city_count,
           row_number() over (
             partition by r.name 
             order by (select count(*) from public.cities c where c.region_id = r.id) desc, r.created_at desc
           ) as rank
    from public.regions r
  ) t
  where t.rank > 1
);

-- 3. Add Unique Constraint to prevent future duplicates
alter table public.regions drop constraint if exists regions_name_key;
alter table public.cities drop constraint if exists cities_name_region_key;

alter table public.regions add constraint regions_name_key unique (name);
alter table public.cities add constraint cities_name_region_key unique (name, region_id);

-- 4. Verify count
select count(*) as region_count from public.regions;
