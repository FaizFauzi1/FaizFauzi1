-- Enable Write Access for Authenticated Users (Admins) to manage Service Categories
-- Allows Create, Update, Delete on admin_service_categories

-- 1. Enable RLS (if not already enabled, though standard tables usually are)
alter table public.admin_service_categories enable row level security;

-- 2. Create Policies for Authenticated Users
create policy "Authenticated users can insert categories"
  on public.admin_service_categories for insert
  with check (auth.role() = 'authenticated');

create policy "Authenticated users can update categories"
  on public.admin_service_categories for update
  using (auth.role() = 'authenticated');

create policy "Authenticated users can delete categories"
  on public.admin_service_categories for delete
  using (auth.role() = 'authenticated');

-- Note: 'Select' policy presumably exists or is public. If not, we add it:
create policy "Public can read categories"
  on public.admin_service_categories for select
  using (true);
