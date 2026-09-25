-- ===========================================
-- ENHANCED NOTIFICATION SCHEMA
-- ===========================================

-- 1. Add new columns to notifications table
ALTER TABLE notifications 
ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'normal',
ADD COLUMN IF NOT EXISTS channel TEXT DEFAULT 'inapp',
ADD COLUMN IF NOT EXISTS notification_status TEXT DEFAULT 'delivered',
ADD COLUMN IF NOT EXISTS related_id TEXT;

-- 2. Update existing records with default values if necessary
UPDATE notifications 
SET priority = 'normal', channel = 'inapp', notification_status = 'delivered'
WHERE priority IS NULL OR channel IS NULL OR notification_status IS NULL;

-- 3. Add check constraints for data integrity
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_priority_check;
ALTER TABLE notifications ADD CONSTRAINT notifications_priority_check 
CHECK (priority IN ('low', 'normal', 'high', 'urgent'));

ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_channel_check;
ALTER TABLE notifications ADD CONSTRAINT notifications_channel_check 
CHECK (channel IN ('push', 'email', 'inapp', 'sms'));

ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_status_check;
ALTER TABLE notifications ADD CONSTRAINT notifications_status_check 
CHECK (notification_status IN ('sent', 'delivered', 'read', 'failed'));

-- 4. Create an index on user_id and created_at for performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id_created_at ON notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_related_id ON notifications(related_id);
