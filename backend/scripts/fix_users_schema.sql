-- ============================================================
-- Migration: Fix users table schema mismatch
-- Database: puimey
-- Run once after MySQL starts
-- ============================================================

USE puimey;

-- Step 1: Check current columns
SELECT COLUMN_NAME, DATA_TYPE, COLUMN_KEY, EXTRA 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'puimey' AND TABLE_NAME = 'users'
ORDER BY ORDINAL_POSITION;

-- Step 2: Rename 'id' to 'id_user' (if 'id_user' doesn't exist yet)
SET @col_exists = (
  SELECT COUNT(*) FROM information_schema.COLUMNS 
  WHERE TABLE_SCHEMA = 'puimey' AND TABLE_NAME = 'users' AND COLUMN_NAME = 'id_user'
);

-- Only rename if id_user doesn't exist and id does
-- Run manually if needed:
-- ALTER TABLE users CHANGE `id` `id_user` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT;

-- Step 3: Add is_active column if it doesn't exist
SET @is_active_exists = (
  SELECT COUNT(*) FROM information_schema.COLUMNS 
  WHERE TABLE_SCHEMA = 'puimey' AND TABLE_NAME = 'users' AND COLUMN_NAME = 'is_active'
);

-- Run manually if needed:
-- ALTER TABLE users ADD COLUMN `is_active` TINYINT(1) NOT NULL DEFAULT 1 AFTER `role`;

-- ============================================================
-- ACTUAL FIX COMMANDS (run these):
-- ============================================================

-- 1. If column is named 'id' (not 'id_user'):
ALTER TABLE users CHANGE `id` `id_user` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT;

-- 2. If is_active column doesn't exist:
ALTER TABLE users ADD COLUMN `is_active` TINYINT(1) NOT NULL DEFAULT 1;

-- 3. Add missing columns that backend may need (if not exist):
ALTER TABLE users ADD COLUMN IF NOT EXISTS `auth_provider` VARCHAR(20) DEFAULT 'local';
ALTER TABLE users ADD COLUMN IF NOT EXISTS `provider_id` VARCHAR(255) DEFAULT NULL;

-- 4. Verify
SELECT id_user, name, email, role, is_active FROM users LIMIT 5;

