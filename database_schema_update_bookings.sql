-- Add missing columns to bookings table to match the App Model
ALTER TABLE bookings 
ADD COLUMN IF NOT EXISTS duration TEXT,
ADD COLUMN IF NOT EXISTS package_name TEXT,
ADD COLUMN IF NOT EXISTS location TEXT;

-- Ensure RLS or policies allow access (implicit in this context)
