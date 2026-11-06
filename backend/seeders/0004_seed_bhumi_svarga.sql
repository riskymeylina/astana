-- ============================================================
-- Seeder: 0004_seed_bhumi_svarga
-- Description: Seed data 5 Tipe Properti Bhumi Svarga Prambanan
-- Lokasi 1: Bhumi Svarga Prambanan (Blok A) - Bugisan Sawah
-- Lokasi 2: Bhumi Svarga Prambanan Blok C
-- ============================================================

START TRANSACTION;

-- Lokasi 1: Tipe Joglo Bata Klasik, Limasan Kembar, Joglo Modern, Limasan Luas
-- (Area Sawah, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454)

-- 1. Tipe Joglo Bata Klasik
INSERT INTO properties (title, category, location, price, status)
VALUES ('Bhumi Svarga Prambanan - Tipe Joglo Bata Klasik', 'Bhumi Svarga', 'Bhumi Svarga Prambanan, Area Sawah, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454', 495000000, 'Tersedia');
SET @bs1_id = LAST_INSERT_ID();

INSERT INTO property_gallery_images (property_id, image_url, title, subtitle, detail_primary, detail_secondary, sort_order) VALUES
  (@bs1_id, '/uploads/properties/bhumi_svarga_tipe_joglo_bata.jpg', 'Tampak Depan (Joglo Bata Klasik)', 'Fasad Joglo Bata Ekspos Klasik Jawa', 'Bata ekspos merah & atap genteng joglo', 'Pintu gebyok ukir jati & taman depan', 1),
  (@bs1_id, '/uploads/properties/bs_joglo_bata_ruang_tamu.jpg', 'Ruang Tamu', 'Interior Klasik Jawa Modern', 'Suasana hangat & plafon tinggi khas joglo', 'Lantai keramik premium & ventilasi baik', 2),
  (@bs1_id, '/uploads/properties/bs_joglo_bata_kamar_tidur.jpg', 'Kamar Tidur Utama', 'Kamar Tidur Nyaman Joglo Bata', 'Desain tenang & fungsional nuansa Jawa', 'Pencahayaan alami dari jendela kayu jati', 3),
  (@bs1_id, '/uploads/properties/bs_joglo_bata_dapur.jpg', 'Dapur', 'Dapur Bersih Tipe Joglo Bata', 'Kitchen set rapi & modern', 'Ventilasi baik & bersih', 4),
  (@bs1_id, '/uploads/properties/bs_joglo_bata_kamar_mandi.jpg', 'Kamar Mandi', 'Kamar Mandi Modern Joglo Bata', 'Sanitair lengkap & shower', 'Keramik estetik premium', 5);

-- 2. Tipe Limasan Kembar
INSERT INTO properties (title, category, location, price, status)
VALUES ('Bhumi Svarga Prambanan - Tipe Limasan Kembar', 'Bhumi Svarga', 'Bhumi Svarga Prambanan, Area Sawah, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454', 385000000, 'Tersedia');
SET @bs2_id = LAST_INSERT_ID();

INSERT INTO property_gallery_images (property_id, image_url, title, subtitle, detail_primary, detail_secondary, sort_order) VALUES
  (@bs2_id, '/uploads/properties/bhumi_svarga_tipe_limasan_kembar.jpg', 'Tampak Depan (Limasan Kembar)', 'Unit Kembar Limasan Area Sawah', 'Desain serasi berpasangan & taman kolektif', 'View area sawah & suasana asri', 1),
  (@bs2_id, '/uploads/properties/bs_limasan_kembar_ruang_tamu.jpg', 'Ruang Tamu', 'Interior Limasan Kembar Hangat', 'Ruangan lapang & sirkulasi baik khas limasan', 'Pintu ukir kayu jati & dekorasi etnik', 2),
  (@bs2_id, '/uploads/properties/bs_limasan_kembar_kamar_tidur.jpg', 'Kamar Tidur Utama', 'Kamar Tidur Limasan Kembar', 'Ruangan fungsional & estetik nuansa kayu', 'Jendela lebar & ventilasi asri sawah', 3),
  (@bs2_id, '/uploads/properties/bs_limasan_kembar_dapur.jpg', 'Dapur', 'Dapur Kompak Limasan Kembar', 'Area memasak bersih & lapang', 'Fasilitas dapur lengkap', 4),
  (@bs2_id, '/uploads/properties/bs_limasan_kembar_kamar_mandi.jpg', 'Kamar Mandi', 'Kamar Mandi Limasan Kembar', 'Shower & closet duduk berkualitas', 'Keramik anti-slip premium', 5);

-- 3. Tipe Joglo Modern
INSERT INTO properties (title, category, location, price, status)
VALUES ('Bhumi Svarga Prambanan - Tipe Joglo Modern', 'Bhumi Svarga', 'Bhumi Svarga Prambanan, Area Sawah, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454', 350000000, 'Tersedia');
SET @bs3_id = LAST_INSERT_ID();

INSERT INTO property_gallery_images (property_id, image_url, title, subtitle, detail_primary, detail_secondary, sort_order) VALUES
  (@bs3_id, '/uploads/properties/bhumi_svarga_tipe_joglo_modern.jpg', 'Tampak Depan (Joglo Modern)', 'Fasad Joglo Modern Putih & Bata', 'Cat putih bersih & atap joglo genteng merah', 'Taman bunga depan & jalan setapak', 1),
  (@bs3_id, '/uploads/properties/bs_joglo_modern_ruang_tamu.jpg', 'Ruang Tamu', 'Ruang Tamu Cerah Joglo Modern', 'Interior terang & modern nuansa Jawa kontemporer', 'Plafon tinggi khas joglo & lantai premium', 2),
  (@bs3_id, '/uploads/properties/bs_joglo_modern_kamar_tidur.jpg', 'Kamar Tidur Utama', 'Kamar Tidur Joglo Modern', 'Desain minimalis & nyaman', 'Pencahayaan alami maksimal dari jendela lebar', 3),
  (@bs3_id, '/uploads/properties/bs_joglo_modern_dapur.jpg', 'Dapur', 'Dapur Minimalis Joglo Modern', 'Penataan rapi & efisien', 'Kitchen sink modern & bersih', 4),
  (@bs3_id, '/uploads/properties/bs_joglo_modern_kamar_mandi.jpg', 'Kamar Mandi', 'Kamar Mandi Joglo Modern', 'Bersih & modern sanitair lengkap', 'Shower & closet duduk premium', 5);

-- 4. Tipe Limasan Luas (Lokasi 1 juga)
INSERT INTO properties (title, category, location, price, status)
VALUES ('Bhumi Svarga Prambanan - Tipe Limasan Luas', 'Bhumi Svarga', 'Bhumi Svarga Prambanan, Area Sawah, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454', 445000000, 'Tersedia');
SET @bs4_id = LAST_INSERT_ID();

INSERT INTO property_gallery_images (property_id, image_url, title, subtitle, detail_primary, detail_secondary, sort_order) VALUES
  (@bs4_id, '/uploads/properties/bhumi_svarga_tipe_limasan_luas.jpg', 'Tampak Depan (Limasan Luas)', 'Fasad Limasan Bata Lebar Motif Jawa', 'Bata ekspos luas & pagar motif batik Jawa', 'Carport lebar & halaman representatif', 1),
  (@bs4_id, '/uploads/properties/bs_limasan_luas_ruang_tamu.jpg', 'Ruang Tamu', 'Ruang Tamu Luas Elegan', 'Ruangan lega & elegan khas limasan luas', 'Lantai granit & pencahayaan hangat optimal', 2),
  (@bs4_id, '/uploads/properties/bs_limasan_luas_ruang_keluarga.jpg', 'Ruang Keluarga', 'Area Kumpul Keluarga Limasan', 'Ruang keluarga lapang & nyaman', 'Sirkulasi udara optimal & ventilasi baik', 3),
  (@bs4_id, '/uploads/properties/bs_limasan_luas_kamar_tidur.jpg', 'Kamar Tidur Utama', 'Kamar Tidur Utama Limasan Luas', 'Desain hangat & luas nuansa Jawa', 'Kamar mandi dalam & sirkulasi baik', 4),
  (@bs4_id, '/uploads/properties/bs_limasan_luas_kamar_tidur2.jpg', 'Kamar Tidur 2', 'Kamar Tidur Kedua Limasan Luas', 'Fungsional & nyaman dengan jendela lebar', 'Pencahayaan alami & sirkulasi baik', 5),
  (@bs4_id, '/uploads/properties/bs_limasan_luas_dapur.jpg', 'Dapur', 'Dapur Luas Limasan', 'Area memasak lega & modern lengkap', 'Ventilasi udara terbuka & kitchen set rapi', 6),
  (@bs4_id, '/uploads/properties/bs_limasan_luas_kamar_mandi.jpg', 'Kamar Mandi', 'Kamar Mandi Limasan Luas', 'Sanitair lengkap & modern premium', 'Keramik premium & anti-slip', 7);

-- ============================================================
-- Lokasi 2: Tipe 2 Lantai
-- Bhumi Svarga Prambanan Blok C, Jl. Bhumi Svarga Blok C no. 2,
-- Area Sawah, Bugisan, Prambanan, Klaten Regency, Central Java 57454
-- ============================================================

-- 5. Tipe 2 Lantai
INSERT INTO properties (title, category, location, price, status)
VALUES ('Bhumi Svarga Prambanan - Tipe 2 Lantai (Blok C)', 'Bhumi Svarga', 'Bhumi Svarga Prambanan Blok C, Jl. Bhumi Svarga Blok C no. 2, Area Sawah, Bugisan, Prambanan, Kabupaten Klaten, Jawa Tengah 57454', 685000000, 'Tersedia');
SET @bs5_id = LAST_INSERT_ID();

INSERT INTO property_gallery_images (property_id, image_url, title, subtitle, detail_primary, detail_secondary, sort_order) VALUES
  (@bs5_id, '/uploads/properties/bhumi_svarga_tipe_2lantai.jpg', 'Tampak Depan (2 Lantai)', 'Fasad Joglo 2 Lantai Bata Ekspos Premium', 'Bata ekspos 2 lantai & atap joglo bertingkat', 'Balkon lantai 2, taman bunga & view pegunungan', 1),
  (@bs5_id, '/uploads/properties/bs_2lantai_ruang_tamu.jpg', 'Ruang Tamu', 'Ruang Tamu Lantai 1 Mewah', 'Interior elegan dengan plafon tinggi khas joglo', 'Pintu ukir gebyok & lantai granit premium', 2),
  (@bs5_id, '/uploads/properties/bs_2lantai_ruang_keluarga.jpg', 'Ruang Keluarga', 'Ruang Keluarga Lantai 1', 'Area santai keluarga yang lapang & nyaman', 'Pencahayaan alami & sirkulasi baik', 3),
  (@bs5_id, '/uploads/properties/bs_2lantai_kamar_tidur.jpg', 'Kamar Tidur Utama', 'Master Bedroom Lantai 1 Premium', 'Desain mewah & tenang khas Jawa modern', 'Kamar mandi dalam & walk-in closet', 4),
  (@bs5_id, '/uploads/properties/bs_2lantai_kamar_tidur2.jpg', 'Kamar Tidur Lantai 2', 'Kamar Tidur Lantai 2 View Balkon', 'View balkon & pegunungan Klaten indah', 'Kamar luas & pencahayaan maksimal', 5),
  (@bs5_id, '/uploads/properties/bs_2lantai_dapur.jpg', 'Dapur Modern', 'Dapur Bersih 2 Lantai Premium', 'Kitchen set lengkap & modern', 'Wastafel & area memasak luas rapi', 6),
  (@bs5_id, '/uploads/properties/bs_2lantai_kamar_mandi.jpg', 'Kamar Mandi', 'Kamar Mandi Premium 2 Lantai', 'Sanitair mewah & shower modern', 'Keramik premium & dinding estetik', 7);

COMMIT;

