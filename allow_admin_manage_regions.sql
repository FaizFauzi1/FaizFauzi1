-- Enable Write Access for Authenticated Users (Admins/Vendors) to manage Regions/Cities
-- NOTE: In a real production app, you should restrict this to ONLY Admins via a role check or dedicated table.
-- For this development phase, we allow 'authenticated' role to manage it.

-- 1. Regions Policies
create policy "Authenticated users can insert regions"
  on public.regions for insert
  with check (auth.role() = 'authenticated');

create policy "Authenticated users can update regions"
  on public.regions for update
  using (auth.role() = 'authenticated');

create policy "Authenticated users can delete regions"
  on public.regions for delete
  using (auth.role() = 'authenticated');

-- 2. Cities Policies
create policy "Authenticated users can insert cities"
  on public.cities for insert
  with check (auth.role() = 'authenticated');

create policy "Authenticated users can update cities"
  on public.cities for update
  using (auth.role() = 'authenticated');

create policy "Authenticated users can delete cities"
  on public.cities for delete
  using (auth.role() = 'authenticated');
