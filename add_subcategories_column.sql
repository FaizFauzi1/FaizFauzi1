-- Add subcategories support to admin_service_categories
alter table public.admin_service_categories
add column if not exists subcategories jsonb default '[]'::jsonb;

-- Update existing sample categories with some defaults (optional, but good for testing)
update public.admin_service_categories
set subcategories = '["Wedding Catering", "Corporate Catering", "Party Catering"]'::jsonb
where name = 'Catering';

update public.admin_service_categories
set subcategories = '["Wedding Photography", "Event Photography", "Portrait"]'::jsonb
where name = 'Photography';
