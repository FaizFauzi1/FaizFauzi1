select 
  (select count(*) from public.regions) as total_regions,
  (select count(*) from public.cities) as total_cities,
  (select count(*) from public.cities c join public.regions r on c.region_id = r.id) as cities_with_valid_parents,
  (select count(*) from public.cities c where c.region_id not in (select id from public.regions)) as orphaned_cities;

-- List a few examples to sanity check IDs
select r.name as region, c.name as city, r.id as r_id, c.region_id as c_parent_id
from public.cities c
join public.regions r on c.region_id = r.id
limit 5;
