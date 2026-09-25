-- Make duration_minutes nullable in appointments table
alter table appointments
alter column duration_minutes drop not null;
