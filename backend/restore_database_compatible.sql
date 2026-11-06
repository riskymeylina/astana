USE puimey
;

SET FOREIGN_KEY_CHECKS = 0;

-- 1. Hapus tabel anak terlebih dahulu untuk menghindari galat foreign key
DROP TABLE IF EXISTS `consultation_messages`;
DROP TABLE IF EXISTS `invoices`;
DROP TABLE IF EXISTS `notifications`;
DROP TABLE IF EXISTS `password_reset_requests`;
DROP TABLE IF EXISTS `property_consultation_requests`;
DROP TABLE IF EXISTS `property_gallery_images`;
DROP TABLE IF EXISTS `property_images`;
DROP TABLE IF EXISTS `historical_sales`;
DROP TABLE IF EXISTS `buyer_records`;
DROP TABLE IF EXISTS `property_purchases`;
DROP TABLE IF EXISTS `survey_requests`;
DROP TABLE IF EXISTS `todo_lists`;
DROP TABLE IF EXISTS `user_buyer_profiles`;
DROP TABLE IF EXISTS `user_property_preferences`;
DROP TABLE IF EXISTS `properties`;
DROP TABLE IF EXISTS `users`;

-- ----------------------------------------------------------------------------
-- 1. Tabel users (Lengkap dengan kolom Social Auth & is_active)
-- ----------------------------------------------------------------------------
CREATE TABLE `users` (
  `id_user` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `email` varchar(191) NOT NULL,
  `phone` varchar(20) DEFAULT '',
  `password_hash` varchar(255) DEFAULT NULL,
  `role` enum('staf','admin','pembeli') NOT NULL DEFAULT 'pembeli',
  `profile_photo_path` varchar(255) DEFAULT NULL,
  `auth_provider` enum('local','google','facebook') NOT NULL DEFAULT 'local',
  `provider_id` varchar(191) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_user`),
  UNIQUE KEY `users_email_unique` (`email`),
  KEY `idx_users_provider` (`auth_provider`, `provider_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT INTO `users` (`id_user`, `name`, `email`, `phone`, `password_hash`, `role`, `profile_photo_path`, `auth_provider`, `provider_id`, `created_at`, `updated_at`, `is_active`) VALUES
(6, 'Illona', 'lona@gmail.com', '085158266890', '$2b$10$yud2.4wn3Wi.ys.RlYh4ZeuMQlTXLvv9urlVMqvP.DynpFlG/k5X6', 'pembeli', '/uploads/profile-photos/user-6-1782653602727.jpg', 'local', NULL, '2026-06-27 15:12:11', '2026-06-30 12:06:39', 1),
(7, 'Staf', 'staf@gmail.com', '098765432109', '$2b$10$ttSjqx23pPQazIA9xMxo4eheUa45qSSHFHBzc5zYpmb7kxjGrMiAu', 'staf', NULL, 'local', NULL, '2026-06-27 15:41:07', '2026-06-30 12:07:44', 1),
(8, 'Admin', 'admin@gmail.com', '012345678901', '$2b$10$8lMh/urnCx3ZN2WaoR3x8ei2WP5kth3ObvYPJ9tok6oLsLZYIxb8a', 'admin', NULL, 'local', NULL, '2026-06-27 15:42:12', '2026-06-30 14:45:25', 1),
(10, 'Test User', 'testuser@gmail.com', '08123456789', '$2b$10$ZSa2YWYbL.47rDr0d5KUe.6GrGD3QJxmnbFhfQvFMOMykehssY98W', 'pembeli', NULL, 'local', NULL, '2026-06-27 16:48:11', '2026-06-30 12:00:19', 1),
(11, 'Azura', 'zura@gmail.com', '085975244578', '$2b$10$P5sjZe1EdK59UcBH6YWS9uAzw2ZFJr/UKK62rgBXOWN4Zq31pfIdy', 'pembeli', NULL, 'local', NULL, '2026-06-27 16:56:21', '2026-06-27 16:56:21', 1),
(12, 'Verification User', 'verifyuser@gmail.com', '081234567890', '$2b$10$fidrZFprGefHxtW.tM6/g.8meMwc4kbVQ/VL1/e5QNNeO11lZORoO', 'pembeli', NULL, 'local', NULL, '2026-06-27 17:11:44', '2026-06-27 17:11:44', 1),
(13, 'Verification User', 'verification_user_unique_123@gmail.com', '081234567890', '$2b$10$mXB9pb.LhDXzdiX8u.guqe3h7AWc6A2CH5oHLeokXMHjvP5BydvBi', 'pembeli', NULL, 'local', NULL, '2026-06-27 17:20:48', '2026-06-27 17:20:48', 1),
(14, 'Verification User', 'verification_user_unique_456@gmail.com', '081234567890', '$2b$10$FCmzkdN4D.T/HTvlQGxdQerJYa9NiaYKrE.t.rsnTMhQWZQPqWXZe', 'pembeli', NULL, 'local', NULL, '2026-06-27 17:27:01', '2026-06-27 17:27:01', 1),
(15, 'Verification User 15', 'verifyuser15@gmail.com', '08123456789', '$2b$10$axPn3U4Qi5kk4WcymP7sPOndG/RY2WuV/vKTU9j01VqIlnOHYcNHu', 'pembeli', NULL, 'local', NULL, '2026-06-28 02:34:08', '2026-06-28 02:34:08', 1),
(16, 'staf1', 'staf1@gmail.com', '1234567890', '$2b$10$bvmeNQoHaM37/mpZqbKxdONNx88HAxutGhGSqQLniKJss3QdfRIbq', 'staf', NULL, 'local', NULL, '2026-06-30 17:10:57', '2026-06-30 17:10:57', 1),
(17, 'Meylina', 'mey@gmail.com', '085158277835', '$2b$10$gxIZV7SsMpv92y1FK3GB/uqy6/TRUcA7imHh0kfxU3efi77XpttSC', 'pembeli', NULL, 'local', NULL, '2026-07-02 04:38:17', '2026-07-02 04:38:17', 1),
(18, 'Canva', 'anva@gmail.com', '0852243457788', '$2b$10$Tz5RQlhrbJOqjeibpLgUc.BjC8lFkMMEAhVDXG5NkpIKbt/seKxHa', 'pembeli', NULL, 'local', NULL, '2026-07-02 06:06:10', '2026-07-02 06:06:10', 1);

-- ----------------------------------------------------------------------------
-- 2. Tabel properties
-- ----------------------------------------------------------------------------
CREATE TABLE `properties` (
  `id_property` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` varchar(150) NOT NULL,
  `category` varchar(50) NOT NULL,
  `location` varchar(150) NOT NULL,
  `price` bigint UNSIGNED NOT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'Tersedia',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_property`),
  KEY `properties_status_index` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT INTO `properties` (`id_property`, `title`, `category`, `location`, `price`, `status`, `created_at`, `updated_at`) VALUES
(8, 'Astana Residence Prambanan', 'rumah', 'Tlogo, Prambanan, Klaten', 185000000, 'Terjual', '2026-06-10 11:51:48', '2026-06-30 15:29:47'),
(9, 'Astana Residence Prambanan', 'rumah', 'Tlogo, Prambanan, Klaten', 245000000, 'Terjual', '2026-06-10 11:51:48', '2026-07-02 05:32:27'),
(10, 'Astana Residence Prambanan', 'rumah', 'Tlogo, Prambanan, Klaten', 320000000, 'Sedang Dibooking', '2026-06-10 11:51:48', '2026-07-02 06:07:02'),
(11, 'Astana Green Living', 'rumah', 'Bugisan, Prambanan, Klaten', 385000000, 'Tersedia', '2026-06-10 11:51:48', '2026-06-28 04:00:17'),
(12, 'Astana Garden House', 'rumah', 'Kebondalem Kidul, Prambanan, Klaten', 450000000, 'Tersedia', '2026-06-10 11:51:48', '2026-06-10 11:51:49'),
(13, 'Astana Family Residence', 'rumah', 'Tlogo, Prambanan, Klaten', 520000000, 'Tersedia', '2026-06-10 11:51:48', '2026-06-10 11:51:49'),
(14, 'Astana Premium Residence', 'rumah', 'Manisrenggo, Klaten', 650000000, 'Tersedia', '2026-06-10 11:51:48', '2026-06-28 04:00:17'),
(18, 'Kampus UTY', 'Rumah/Perumahan', 'Sleman, DIY', 1500000000, 'Tersedia', '2026-06-30 15:32:24', '2026-06-30 16:56:15');

-- ----------------------------------------------------------------------------
-- 3. Tabel property_gallery_images
-- ----------------------------------------------------------------------------
CREATE TABLE `property_gallery_images` (
  `id_property_gallery_image` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `property_id` bigint UNSIGNED NOT NULL,
  `image_url` varchar(255) NOT NULL,
  `title` varchar(120) NOT NULL,
  `subtitle` varchar(255) DEFAULT NULL,
  `detail_primary` varchar(180) DEFAULT NULL,
  `detail_secondary` varchar(180) DEFAULT NULL,
  `sort_order` smallint UNSIGNED NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_property_gallery_image`),
  KEY `property_gallery_images_property_id_index` (`property_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT INTO `property_gallery_images` (`id_property_gallery_image`, `property_id`, `image_url`, `title`, `subtitle`, `detail_primary`, `detail_secondary`, `sort_order`, `created_at`, `updated_at`) VALUES
(16, 8, 'https://images.unsplash.com/photo-1616137422495-1e9e46e2aa77?q=80&w=1631&auto=format&fit=crop', 'Tampilan Depan', 'Visual utama properti', 'Foto referensi dari aset splash', 'Gambar backend-served', 1, '2026-06-10 11:51:48', '2026-06-30 11:20:06'),
(17, 8, 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80', 'Sudut Interior', 'Area dalam properti', 'Foto referensi dari aset splash', 'Gambar backend-served', 2, '2026-06-10 11:51:48', '2026-06-10 11:51:48'),
(18, 9, 'https://images.unsplash.com/photo-1494526585095-c41746248156?auto=format&fit=crop&w=1200&q=80', 'Tampilan Depan', 'Visual utama properti', 'Foto referensi dari aset splash', 'Gambar backend-served', 1, '2026-06-10 11:51:48', '2026-06-10 11:51:48'),
(19, 9, 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80', 'Sudut Interior', 'Area dalam properti', 'Foto referensi dari aset splash', 'Gambar backend-served', 2, '2026-06-10 11:51:48', '2026-06-10 11:51:48'),
(20, 10, 'https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=1200&q=80', 'Tampilan Depan', 'Visual utama properti', 'Foto referensi dari aset splash', 'Gambar backend-served', 1, '2026-06-10 11:51:48', '2026-06-10 11:51:48'),
(21, 10, 'https://images.unsplash.com/photo-1616137422495-1e9e46e2aa77?q=80&w=1631&auto=format&fit=crop', 'Sudut Interior', 'Area dalam properti', 'Foto referensi dari aset splash', 'Gambar backend-served', 2, '2026-06-10 11:51:48', '2026-06-30 11:20:06'),
(22, 11, 'https://images.unsplash.com/photo-1616137422495-1e9e46e2aa77?q=80&w=1631&auto=format&fit=crop', 'Tampilan Depan', 'Visual utama properti', 'Foto referensi dari aset splash', 'Gambar backend-served', 1, '2026-06-10 11:51:48', '2026-06-30 11:20:06'),
(23, 11, 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80', 'Sudut Interior', 'Area dalam properti', 'Foto referensi dari aset splash', 'Gambar backend-served', 2, '2026-06-10 11:51:48', '2026-06-10 11:51:48'),
(24, 12, 'https://images.unsplash.com/photo-1616137422495-1e9e46e2aa77?q=80&w=1631&auto=format&fit=crop', 'Tampilan Depan', 'Visual utama properti', 'Foto referensi dari aset splash', 'Gambar backend-served', 1, '2026-06-10 11:51:48', '2026-06-30 11:20:06'),
(25, 12, 'https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=1200&q=80', 'Sudut Interior', 'Area dalam properti', 'Foto referensi dari aset splash', 'Gambar backend-served', 2, '2026-06-10 11:51:48', '2026-06-10 11:51:48'),
(26, 13, 'https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=1200&q=80', 'Tampilan Depan', 'Visual utama properti', 'Foto referensi dari aset splash', 'Gambar backend-served', 1, '2026-06-10 11:51:48', '2026-06-10 11:51:48'),
(27, 13, 'https://images.unsplash.com/photo-1616137422495-1e9e46e2aa77?q=80&w=1631&auto=format&fit=crop', 'Sudut Interior', 'Area dalam properti', 'Foto referensi dari aset splash', 'Gambar backend-served', 2, '2026-06-10 11:51:48', '2026-06-30 11:20:06'),
(28, 14, 'https://images.unsplash.com/photo-1494526585095-c41746248156?auto=format&fit=crop&w=1200&q=80', 'Tampilan Depan', 'Visual utama properti', 'Foto referensi dari aset splash', 'Gambar backend-served', 1, '2026-06-10 11:51:48', '2026-06-10 11:51:48'),
(47, 8, 'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=1200&q=80', 'Kamar Tidur', 'Interior', 'Kamar tidur utama', '', 3, '2026-06-10 11:51:48', '2026-06-10 11:51:48'),
(48, 8, 'https://images.unsplash.com/photo-1616137422495-1e9e46e2aa77?q=80&w=1631&auto=format&fit=crop', 'Dapur', 'Interior', 'Area dapur', '', 4, '2026-06-10 11:51:48', '2026-06-30 11:20:06'),
(49, 8, 'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=1200&q=80', 'Kamar Mandi', 'Interior', 'Kamar mandi utama', '', 5, '2026-06-10 11:51:48', '2026-06-10 11:51:48'),
(50, 8, 'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=1200&q=80', 'Halaman', 'Eksterior', 'Halaman belakang/ruang terbuka', '', 6, '2026-06-10 11:51:48', '2026-06-10 11:51:48'),
(51, 9, 'https://images.unsplash.com/photo-1616137422495-1e9e46e2aa77?q=80&w=1631&auto=format&fit=crop', 'Kamar Tidur', 'Interior', 'Kamar tidur', '', 3, '2026-06-10 11:51:48', '2026-06-30 11:20:06'),
(52, 9, 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=1200&q=80', 'Dapur', 'Interior', 'Dapur', '', 4, '2026-06-10 11:51:48', '2026-06-10 11:51:48'),
(53, 9, 'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=1200&q=80', 'Kamar Mandi', 'Interior', 'Kamar mandi', '', 5, '2026-06-10 11:51:48', '2026-06-10 11:51:48'),
(54, 9, 'https://images.unsplash.com/photo-1616137422495-1e9e46e2aa77?q=80&w=1631&auto=format&fit=crop', 'Carport', 'Eksterior', 'Carport/garasi', '', 6, '2026-06-10 11:51:48', '2026-06-30 11:20:06'),
(55, 10, 'https://images.unsplash.com/photo-1616137422495-1e9e46e2aa77?q=80&w=1631&auto=format&fit=crop', 'Kamar Tidur', 'Interior', 'Kamar tidur', '', 3, '2026-06-10 11:51:48', '2026-06-30 11:20:06'),
(56, 10, 'https://images.unsplash.com/photo-1540574163026-643ea20ade25?auto=format&fit=crop&w=1200&q=80', 'Dapur', 'Interior', 'Dapur', '', 4, '2026-06-10 11:51:48', '2026-06-10 11:51:48'),
(57, 10, 'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=1200&q=80', 'Kamar Mandi', 'Interior', 'Kamar mandi', '', 5, '2026-06-10 11:51:48', '2026-06-10 11:51:48'),
(58, 10, 'https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=1200&q=80', 'Halaman', 'Eksterior', 'Halaman belakang', '', 6, '2026-06-10 11:51:48', '2026-06-10 11:51:48'),
(59, 11, 'https://images.unsplash.com/photo-1472224371017-08207f84aaae?auto=format&fit=crop&w=1200&q=80', 'Kamar Tidur', 'Interior', 'Kamar tidur', '', 3, '2026-06-10 11:51:48', '2026-06-10 11:51:48'),
(60, 11, 'https://images.unsplash.com/photo-1616137422495-1e9e46e2aa77?q=80&w=1631&auto=format&fit=crop', 'Dapur', 'Interior', 'Dapur', '', 4, '2026-06-10 11:51:48', '2026-06-30 11:20:06'),
(61, 11, 'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=1200&q=80', 'Kamar Mandi', 'Interior', 'Kamar mandi', '', 5, '2026-06-10 11:51:48', '2026-06-10 11:51:48'),
(62, 11, 'https://images.unsplash.com/photo-1449844908441-8829872d2607?auto=format&fit=crop&w=1200&q=80', 'Halaman', 'Eksterior', 'Halaman', '', 6, '2026-06-10 11:51:48', '2026-06-10 11:51:48'),
(63, 12, 'https://images.unsplash.com/photo-1499951360447-b19be8fe80f5?auto=format&fit=crop&w=1200&q=80', 'Kamar Tidur', 'Interior', 'Kamar tidur', '', 3, '2026-06-10 11:51:48', '2026-06-10 11:51:48'),
(64, 12, 'https://images.unsplash.com/photo-1616137422495-1e9e46e2aa77?q=80&w=1631&auto=format&fit=crop', 'Dapur', 'Interior', 'Dapur', '', 4, '2026-06-10 11:51:48', '2026-06-30 11:20:06'),
(65, 12, 'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=1200&q=80', 'Kamar Mandi', 'Interior', 'Kamar mandi', '', 5, '2026-06-10 11:51:48', '2026-06-10 11:51:48'),
(66, 12, 'https://images.unsplash.com/photo-1616137422495-1e9e46e2aa77?q=80&w=1631&auto=format&fit=crop', 'Carport', 'Eksterior', 'Carport/garasi', '', 6, '2026-06-10 11:51:48', '2026-06-30 11:20:06'),
(67, 13, 'https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=1200&q=80', 'Tampilan Depan', 'Visual utama properti', 'Foto referensi dari aset splash', 'Gambar backend-served', 1, '2026-06-10 11:51:48', '2026-06-10 11:51:48'),
(68, 13, 'https://images.unsplash.com/photo-1616137422495-1e9e46e2aa77?q=80&w=1631&auto=format&fit=crop', 'Dapur', 'Interior', 'Dapur', '', 4, '2026-06-10 11:51:48', '2026-06-30 11:20:06'),
(69, 13, 'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=1200&q=80', 'Kamar Mandi', 'Interior', 'Kamar mandi', '', 5, '2026-06-10 11:51:48', '2026-06-10 11:51:48'),
(70, 13, 'https://images.unsplash.com/photo-1616137422495-1e9e46e2aa77?q=80&w=1631&auto=format&fit=crop', 'Halaman', 'Eksterior', 'Halaman', '', 6, '2026-06-10 11:51:48', '2026-06-30 11:20:06'),
(71, 14, 'https://images.unsplash.com/photo-1494526585095-c41746248156?auto=format&fit=crop&w=1200&q=80', 'Tampilan Depan', 'Visual utama properti', 'Foto referensi dari aset splash', 'Gambar backend-served', 1, '2026-06-10 11:51:48', '2026-06-10 11:51:48'),
(72, 14, 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80', 'Sudut Interior', 'Area dalam properti', 'Foto referensi dari aset splash', 'Gambar backend-served', 2, '2026-06-10 11:51:48', '2026-06-10 11:51:48'),
(116, 18, '/uploads/properties/property-18/images-1782838576220-783730443.jpg', 'Foto', '', '', '', 1, '2026-06-30 16:56:16', '2026-06-30 16:56:16'),
(117, 18, '/uploads/properties/property-18/images-1782838576229-269953039.jpg', 'Foto', '', '', '', 2, '2026-06-30 16:56:16', '2026-06-30 16:56:16'),
(118, 18, '/uploads/properties/property-18/images-1782838576237-118714521.jpg', 'Foto', '', '', '', 3, '2026-06-30 16:56:16', '2026-06-30 16:56:16'),
(119, 18, '/uploads/properties/property-18/images-1782838576239-435886646.png', 'Foto', '', '', '', 4, '2026-06-30 16:56:16', '2026-06-30 16:56:16'),
(120, 18, '/uploads/properties/property-18/images-1782838576251-556460261.png', 'Foto', '', '', '', 5, '2026-06-30 16:56:16', '2026-06-30 16:56:16');

-- ----------------------------------------------------------------------------
-- 4. Tabel property_consultation_requests
-- ----------------------------------------------------------------------------
CREATE TABLE `property_consultation_requests` (
  `id_property_consultation_request` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `buyer_user_id` bigint UNSIGNED NOT NULL,
  `property_id` bigint UNSIGNED DEFAULT NULL,
  `topic` varchar(100) NOT NULL,
  `preferred_contact_method` varchar(40) NOT NULL DEFAULT 'WhatsApp',
  `message` text NOT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'pending',
  `staff_notes` text,
  `processed_by_user_id` bigint UNSIGNED DEFAULT NULL,
  `processed_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_property_consultation_request`),
  KEY `property_consultation_requests_status_index` (`status`),
  KEY `property_consultation_requests_buyer_user_id_index` (`buyer_user_id`),
  KEY `property_consultation_requests_property_id_index` (`property_id`),
  KEY `property_consultation_requests_processed_by_user_id_index` (`processed_by_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT INTO `property_consultation_requests` (`id_property_consultation_request`, `buyer_user_id`, `property_id`, `topic`, `preferred_contact_method`, `message`, `status`, `staff_notes`, `processed_by_user_id`, `processed_at`, `created_at`, `updated_at`) VALUES
(1, 6, NULL, 'Konsultasi umum', 'Chat Aplikasi', 'Halo, ada yang bisa kami bantu?', 'contacted', 'Staf siap membantu melalui chat.', 7, '2026-06-28 20:56:11', '2026-06-28 13:56:11', '2026-06-28 13:56:11'),
(2, 10, NULL, 'Konsultasi umum', 'Chat Aplikasi', 'Halo, ada yang bisa kami bantu?', 'contacted', 'Staf siap membantu melalui chat.', 7, '2026-06-30 18:21:30', '2026-06-30 11:21:30', '2026-06-30 11:21:30');

-- ----------------------------------------------------------------------------
-- 5. Tabel consultation_messages
-- ----------------------------------------------------------------------------
CREATE TABLE `consultation_messages` (
  `id_consultation_message` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `consultation_id` bigint UNSIGNED NOT NULL,
  `sender_user_id` bigint UNSIGNED NOT NULL,
  `sender_name` varchar(100) NOT NULL,
  `sender_role` enum('staf','admin','pembeli') NOT NULL,
  `message_type` varchar(20) NOT NULL DEFAULT 'text',
  `message` text NOT NULL,
  `media_path` varchar(255) DEFAULT NULL,
  `media_name` varchar(160) DEFAULT NULL,
  `media_mime` varchar(80) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `read_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id_consultation_message`),
  KEY `consultation_messages_consultation_id_idx` (`consultation_id`),
  KEY `consultation_messages_sender_user_id_idx` (`sender_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT INTO `consultation_messages` (`id_consultation_message`, `consultation_id`, `sender_user_id`, `sender_name`, `sender_role`, `message_type`, `message`, `media_path`, `media_name`, `media_mime`, `created_at`, `read_at`) VALUES
(1, 2, 10, 'Test User', 'pembeli', 'text', 'test', NULL, NULL, NULL, '2026-06-30 11:21:38', '2026-06-30 14:27:19'),
(2, 2, 7, 'staf@gmail.com', 'staf', 'text', 'hai', NULL, NULL, NULL, '2026-06-30 14:27:25', NULL);

-- ----------------------------------------------------------------------------
-- 6. Tabel survey_requests
-- ----------------------------------------------------------------------------
CREATE TABLE `survey_requests` (
  `id_survey` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `buyer_user_id` bigint UNSIGNED NOT NULL,
  `property_id` bigint UNSIGNED NOT NULL,
  `requested_date` date NOT NULL,
  `requested_time` time DEFAULT NULL,
  `notes` text,
  `status` varchar(20) NOT NULL DEFAULT 'pending',
  `approved_schedule_date` date DEFAULT NULL,
  `approved_schedule_time` time DEFAULT NULL,
  `rejection_reason` varchar(255) DEFAULT NULL,
  `processed_by_user_id` bigint UNSIGNED DEFAULT NULL,
  `processed_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_survey`),
  KEY `survey_requests_status_index` (`status`),
  KEY `survey_requests_buyer_user_id_index` (`buyer_user_id`),
  KEY `survey_requests_property_id_index` (`property_id`),
  KEY `survey_requests_processed_by_user_id_index` (`processed_by_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT INTO `survey_requests` (`id_survey`, `buyer_user_id`, `property_id`, `requested_date`, `requested_time`, `notes`, `status`, `approved_schedule_date`, `approved_schedule_time`, `rejection_reason`, `processed_by_user_id`, `processed_at`, `created_at`, `updated_at`) VALUES
(1, 10, 8, '2026-07-01', '06:00:00', 'Jumlah pengunjung: 1\nRentang kedatangan: 06:00 – 07:00 WIB\ntest catatan', 'completed', '2026-07-01', '10:00:00', NULL, 7, '2026-06-30 21:34:47', '2026-06-30 11:42:35', '2026-06-30 14:34:47'),
(2, 10, 9, '2026-07-02', '10:00:00', 'Jumlah pengunjung: 3\nRentang kedatangan: 10:00 – 11:00 WIB\ntest\ncatatan\nhai', 'rejected', NULL, NULL, 'bentrok dengan klient lainnya', 7, '2026-06-30 21:30:29', '2026-06-30 14:29:44', '2026-06-30 14:30:29'),
(3, 17, 9, '2026-07-03', '08:00:00', 'Jumlah pengunjung: 3\nRentang kedatangan: 08:00 – 10:00 WIB\nmau survei', 'approved', '2026-07-03', '08:00:00', NULL, 7, '2026-07-02 12:32:13', '2026-07-02 04:39:16', '2026-07-02 05:32:13');

-- ----------------------------------------------------------------------------
-- 7. Tabel property_purchases (Lengkap dengan kolom Midtrans & Payment)
-- ----------------------------------------------------------------------------
CREATE TABLE `property_purchases` (
  `id_purchase` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `buyer_user_id` bigint UNSIGNED NOT NULL,
  `property_id` bigint UNSIGNED NOT NULL,
  `payment_method` varchar(30) NOT NULL,
  `payment_account_number` varchar(50) DEFAULT NULL,
  `payment_account_name` varchar(150) DEFAULT NULL,
  `payment_amount` bigint UNSIGNED DEFAULT NULL,
  `payment_due_at` datetime DEFAULT NULL,
  `cancelled_at` datetime DEFAULT NULL,
  `buyer_name_snapshot` varchar(150) NOT NULL,
  `buyer_phone_snapshot` varchar(20) DEFAULT NULL,
  `buyer_address_snapshot` text,
  `notes` text,
  `status` varchar(30) NOT NULL DEFAULT 'pending_payment',
  `payment_proof_path` varchar(500) DEFAULT NULL,
  `payment_proof_uploaded_at` datetime DEFAULT NULL,
  `processed_by_user_id` bigint UNSIGNED DEFAULT NULL,
  `processed_by_name` varchar(150) DEFAULT NULL,
  `rejection_reason` varchar(500) DEFAULT NULL,
  `processed_at` datetime DEFAULT NULL,
  `midtrans_order_id` varchar(100) DEFAULT NULL,
  `midtrans_transaction_id` varchar(100) DEFAULT NULL,
  `midtrans_qr_url` text DEFAULT NULL,
  `midtrans_payment_status` varchar(50) DEFAULT NULL,
  `midtrans_expiry_time` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_purchase`),
  KEY `pp_buyer_user_id_index` (`buyer_user_id`),
  KEY `pp_property_id_index` (`property_id`),
  KEY `pp_status_index` (`status`),
  KEY `pp_processed_by_user_id_index` (`processed_by_user_id`),
  KEY `pp_payment_due_at_index` (`payment_due_at`),
  KEY `pp_midtrans_order_id_index` (`midtrans_order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT INTO `property_purchases` (`id_purchase`, `buyer_user_id`, `property_id`, `payment_method`, `payment_account_number`, `payment_account_name`, `payment_amount`, `payment_due_at`, `cancelled_at`, `buyer_name_snapshot`, `buyer_phone_snapshot`, `buyer_address_snapshot`, `notes`, `status`, `payment_proof_path`, `payment_proof_uploaded_at`, `processed_by_user_id`, `processed_by_name`, `rejection_reason`, `processed_at`, `created_at`, `updated_at`) VALUES
(1, 10, 8, 'Transfer Bank', '1234567890', 'PT. Astana Karya Bandawasa', 185000000, '2026-07-03 19:02:53', NULL, 'Test User', '08 123 456 78', 'Jl. Jombor, Mlati, Sleman, DIY, 12345', 'Saya mau yang pintu belakangnya pintu surga', 'confirmed', '/uploads/payment-proofs/proof-1-10-1782833335352.png', '2026-06-30 22:28:55', 7, 'Staf', NULL, '2026-06-30 22:29:47', '2026-06-30 12:02:53', '2026-06-30 15:29:47'),
(2, 17, 9, 'Transfer Bank', '1234567890', 'PT. Astana Karya Bandawasa', 245000000, '2026-07-05 11:50:44', NULL, 'Meylina', '08 515 827 7835', 'Sleman', 'Saya mau ini', 'confirmed', '/uploads/payment-proofs/proof-2-17-1782967860036.jpg', '2026-07-02 11:51:00', 7, 'Staf', NULL, '2026-07-02 12:32:27', '2026-07-02 04:50:44', '2026-07-02 05:32:27'),
(3, 18, 10, 'Cash Payment', '1234567890', 'PT. Astana Karya Bandawasa', 320000000, '2026-07-05 13:07:02', NULL, 'Canva', '08 522 434 57988', 'Klaten Utara', 'pengen beli', 'payment_uploaded', '/uploads/payment-proofs/proof-3-18-1782972759974.jpg', '2026-07-02 13:12:40', NULL, NULL, NULL, NULL, '2026-07-02 06:07:02', '2026-07-02 06:12:40');

-- ----------------------------------------------------------------------------
-- 8. Tabel invoices
-- ----------------------------------------------------------------------------
CREATE TABLE `invoices` (
  `id_invoice` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `invoice_number` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `purchase_id` bigint UNSIGNED NOT NULL,
  `buyer_id` bigint UNSIGNED NOT NULL,
  `property_id` bigint UNSIGNED NOT NULL,
  `property_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `property_price` decimal(15,2) NOT NULL,
  `payment_method` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `payment_proof_url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `payment_status` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `issued_at` timestamp NULL DEFAULT NULL,
  `due_date` date DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_invoice`),
  UNIQUE KEY `invoice_number` (`invoice_number`),
  UNIQUE KEY `purchase_id` (`purchase_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT INTO `invoices` (`id_invoice`, `invoice_number`, `purchase_id`, `buyer_id`, `property_id`, `property_name`, `property_price`, `payment_method`, `payment_proof_url`, `payment_status`, `issued_at`, `due_date`, `created_at`, `updated_at`) VALUES
(1, 'INV-202606-387154', 1, 10, 8, 'Astana Residence Prambanan', 185000000.00, 'Transfer Bank', '/uploads/payment-proofs/proof-1-10-1782833335352.png', 'pending', '2026-06-30 15:29:47', '2026-07-30', '2026-06-30 15:29:47', '2026-06-30 15:29:47'),
(2, 'INV-202607-347364', 2, 17, 9, 'Astana Residence Prambanan', 245000000.00, 'Transfer Bank', '/uploads/payment-proofs/proof-2-17-1782967860036.jpg', 'pending', '2026-07-02 05:32:27', '2026-08-01', '2026-07-02 05:32:27', '2026-07-02 05:32:27');

-- ----------------------------------------------------------------------------
-- 9. Tabel buyer_records (Data Pembeli Historis & Terverifikasi Admin)
-- ----------------------------------------------------------------------------
CREATE TABLE `buyer_records` (
  `id_buyer_record` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `linked_user_id` bigint UNSIGNED DEFAULT NULL,
  `full_name` varchar(150) NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `email` varchar(191) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `data_source` enum('app_registration','manual_admin','historical_company') NOT NULL DEFAULT 'manual_admin',
  `data_label` varchar(50) DEFAULT NULL,
  `verification_status` enum('unverified','pending_verification','verified') NOT NULL DEFAULT 'unverified',
  `verified_by_user_id` bigint UNSIGNED DEFAULT NULL,
  `verified_at` datetime DEFAULT NULL,
  `recorded_by_user_id` bigint UNSIGNED NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_buyer_record`),
  UNIQUE KEY `buyer_records_linked_user_unique` (`linked_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ----------------------------------------------------------------------------
-- 10. Tabel historical_sales (Rekap Penjualan Historis)
-- ----------------------------------------------------------------------------
CREATE TABLE `historical_sales` (
  `id_historical_sale` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `buyer_record_id` bigint UNSIGNED NOT NULL,
  `property_id` bigint UNSIGNED DEFAULT NULL,
  `property_name_snapshot` varchar(255) NOT NULL,
  `transaction_date` date DEFAULT NULL,
  `transaction_value` bigint UNSIGNED DEFAULT NULL,
  `payment_method` varchar(100) DEFAULT NULL,
  `status` enum('completed','pending','cancelled') NOT NULL DEFAULT 'completed',
  `notes` text DEFAULT NULL,
  `data_label` varchar(50) DEFAULT NULL,
  `recorded_by_user_id` bigint UNSIGNED NOT NULL,
  `recorded_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_historical_sale`),
  KEY `historical_sales_buyer_record_idx` (`buyer_record_id`),
  KEY `historical_sales_property_idx` (`property_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ----------------------------------------------------------------------------
-- 11. Tabel notifications
-- ----------------------------------------------------------------------------
CREATE TABLE `notifications` (
  `id_notification` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` bigint UNSIGNED NOT NULL,
  `title` varchar(160) NOT NULL,
  `message` text NOT NULL,
  `type` varchar(40) NOT NULL DEFAULT 'info',
  `action_url` varchar(255) DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `read_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_notification`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ----------------------------------------------------------------------------
-- 12. Tabel todo_lists (Tugas Staf)
-- ----------------------------------------------------------------------------
CREATE TABLE `todo_lists` (
  `id_todo_list` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` bigint UNSIGNED NOT NULL,
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `status` enum('pending','completed') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `due_date` date DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_todo_list`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT INTO `todo_lists` (`id_todo_list`, `user_id`, `title`, `description`, `status`, `due_date`, `created_at`, `updated_at`) VALUES
(5, 7, 'Makan Siang', 'Nasi Padang dengan Rendang', 'pending', NULL, '2026-06-30 12:09:07', '2026-06-30 12:09:11');

-- ----------------------------------------------------------------------------
-- 13. Tabel user_buyer_profiles (Profil Lengkap & Alamat Calon Pembeli)
-- ----------------------------------------------------------------------------
CREATE TABLE `user_buyer_profiles` (
  `id_user_buyer_profile` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` bigint UNSIGNED NOT NULL,
  `whatsapp` varchar(20) DEFAULT NULL,
  `contact_note` varchar(255) DEFAULT NULL,
  `recipient_name` varchar(100) DEFAULT NULL,
  `address_line` varchar(255) DEFAULT NULL,
  `province` varchar(100) DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `district` varchar(100) DEFAULT NULL,
  `subdistrict` varchar(100) DEFAULT NULL,
  `postal_code` varchar(10) DEFAULT NULL,
  `landmark` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_user_buyer_profile`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT INTO `user_buyer_profiles` (`id_user_buyer_profile`, `user_id`, `whatsapp`, `contact_note`, `recipient_name`, `address_line`, `province`, `city`, `district`, `subdistrict`, `postal_code`, `landmark`, `created_at`, `updated_at`) VALUES
(1, 10, '', '', 'Test User', 'Jl. Jombor', 'DIY', 'Sleman', 'Mlati', 'Sinduadi', '12345', '', '2026-06-30 12:00:19', '2026-06-30 12:00:19');

-- ----------------------------------------------------------------------------
-- 14. Tabel user_property_preferences (Preferensi Properti Pembeli)
-- ----------------------------------------------------------------------------
CREATE TABLE `user_property_preferences` (
  `id_user_property_preference` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` bigint UNSIGNED NOT NULL,
  `preferred_categories` text NOT NULL,
  `preferred_location` varchar(150) DEFAULT NULL,
  `min_price` bigint UNSIGNED DEFAULT NULL,
  `max_price` bigint UNSIGNED DEFAULT NULL,
  `min_bedrooms` tinyint UNSIGNED DEFAULT NULL,
  `min_bathrooms` tinyint UNSIGNED DEFAULT NULL,
  `min_building_area` int UNSIGNED DEFAULT NULL,
  `min_land_area` int UNSIGNED DEFAULT NULL,
  `notes` text,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_user_property_preference`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT INTO `user_property_preferences` (`id_user_property_preference`, `user_id`, `preferred_categories`, `preferred_location`, `min_price`, `max_price`, `min_bedrooms`, `min_bathrooms`, `min_building_area`, `min_land_area`, `notes`, `created_at`, `updated_at`) VALUES
(1, 10, '[\"Rumah\"]', 'Klaten', 200000000, 800000000, NULL, NULL, NULL, NULL, 'Catatan Preferensi', '2026-06-30 12:01:36', '2026-06-30 12:01:49');

-- ----------------------------------------------------------------------------
-- 15. Tabel password_reset_requests (OTP & Reset Password)
-- ----------------------------------------------------------------------------
CREATE TABLE `password_reset_requests` (
  `id_password_reset_request` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` bigint UNSIGNED NOT NULL,
  `code_hash` varchar(255) NOT NULL,
  `expires_at` datetime NOT NULL,
  `verified_at` datetime DEFAULT NULL,
  `consumed_at` datetime DEFAULT NULL,
  `attempt_count` int NOT NULL DEFAULT '0',
  `last_sent_at` datetime NOT NULL,
  `reset_session_token_hash` varchar(255) DEFAULT NULL,
  `reset_session_expires_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_password_reset_request`),
  KEY `password_reset_requests_user_id_index` (`user_id`),
  KEY `password_reset_requests_expires_at_index` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

SET FOREIGN_KEY_CHECKS = 1;