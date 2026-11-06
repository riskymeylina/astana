-- Migration: 0002_add_social_auth_columns
-- Description: Add social auth support to users table

ALTER TABLE `users`
  MODIFY COLUMN `password_hash` varchar(255) NULL,
  MODIFY COLUMN `phone` varchar(20) NULL DEFAULT '',
  ADD COLUMN `auth_provider` enum('local', 'google', 'facebook') NOT NULL DEFAULT 'local',
  ADD COLUMN `provider_id` varchar(191) NULL DEFAULT NULL,
  ADD KEY `idx_users_provider` (`auth_provider`, `provider_id`);
