-- Add birthday column to customer_user table
ALTER TABLE customer_user ADD COLUMN IF NOT EXISTS birthday DATE;
