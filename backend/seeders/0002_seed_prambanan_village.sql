-- ============================================================
-- Seeder: 0002_seed_prambanan_village
-- Description: Seed data 4 Tipe Properti Prambanan Village
-- ============================================================

START TRANSACTION;

-- 1. Tipe 85 (2 Lantai)
INSERT INTO properties (title, category, location, price, status)
VALUES ('Prambanan Village - Tipe 85 (2 Lantai)', 'Prambanan Village', 'Prambanan Village III, Area Sawah, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454', 685000000, 'Tersedia');
SET @p1_id = LAST_INSERT_ID();

INSERT INTO property_gallery_images (property_id, image_url, title, subtitle, detail_primary, detail_secondary, sort_order) VALUES
  (@p1_id, '/uploads/properties/prambanan_tipe_85.jpg', 'Tampak Depan (2 Lantai)', 'Fasad Utama Limasan Modern 2 Lantai', 'Bata ekspos & ukiran kayu jati', 'Balkon atas & carport luas', 1),
  (@p1_id, '/uploads/properties/pv_85_ruang_tamu.jpg', 'Ruang Tamu', 'Interior Mewah 2 Lantai Nuansa Jawa', 'Ruang tamu elegan dengan plafon void tinggi', 'Pintu gebyok ukir jati & lantai granit premium', 2),
  (@p1_id, '/uploads/properties/pv_85_ruang_keluarga.jpg', 'Ruang Keluarga', 'Area Kumpul Keluarga 2 Lantai', 'Pencahayaan alami & sirkulasi udara baik', 'Dekat taman samping & balkon', 3),
  (@p1_id, '/uploads/properties/pv_85_kamar_tidur.jpg', 'Kamar Tidur Utama', 'Master Bedroom Lantai 1 Mewah', 'Desain hangat & estetik, headboard ukir jati', 'Kamar mandi dalam & balkon pribadi', 4),
  (@p1_id, '/uploads/properties/pv_85_kamar_tidur2.jpg', 'Kamar Tidur Lantai 2', 'Kamar Tidur View Pegunungan Klaten', 'View menghadap pegunungan & sawah hijau', 'Balkon lantai 2 & jendela panoramik', 5),
  (@p1_id, '/uploads/properties/pv_85_dapur.jpg', 'Dapur Bersih', 'Area Dapur Modern 2 Lantai', 'Kitchen set minimalis rapi & modern', 'Wastafel stainless & rak bumbu lengkap', 6),
  (@p1_id, '/uploads/properties/pv_85_kamar_mandi.jpg', 'Kamar Mandi', 'Kamar Mandi Bersih Modern', 'Sanitair modern & shower', 'Keramik premium anti-slip', 7);

-- 2. Tipe 65 (Grand Limasan)
INSERT INTO properties (title, category, location, price, status)
VALUES ('Prambanan Village - Tipe 65 (Grand Limasan)', 'Prambanan Village', 'Prambanan Village III, Area Sawah, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454', 495000000, 'Tersedia');
SET @p2_id = LAST_INSERT_ID();

INSERT INTO property_gallery_images (property_id, image_url, title, subtitle, detail_primary, detail_secondary, sort_order) VALUES
  (@p2_id, '/uploads/properties/prambanan_tipe_65.jpg', 'Tampak Depan (Grand Limasan)', 'Fasad Lebar Etnik Jawa Modern', 'Pintu Gebyok ukir jati mewah', 'Halaman & carport paving luas', 1),
  (@p2_id, '/uploads/properties/pv_65_ruang_tamu.jpg', 'Ruang Tamu', 'Interior Limasan Klasik Jawa Tradisional', 'Langit-langit kayu tinggi khas Limasan & dekorasi batik', 'Pintu gebyok ukir & suasana asri alami', 2),
  (@p2_id, '/uploads/properties/pv_65_kamar_tidur.jpg', 'Kamar Tidur Utama', 'Kamar Tidur Nyaman Grand Limasan', 'Ruangan luas & jendela lebar kayu jati', 'Pencahayaan alami maksimal', 3),
  (@p2_id, '/uploads/properties/pv_65_kamar_tidur2.jpg', 'Kamar Tidur Anak', 'Kamar Tidur Kedua', 'Cocok untuk anak/ruang kerja', 'Kusen kayu jati & sirkulasi baik', 4),
  (@p2_id, '/uploads/properties/pv_65_dapur.jpg', 'Dapur Minimalis', 'Dapur & Meja Makan Tipe 65', 'Area memasak bersih & lapang', 'Ventilasi udara terbuka alami', 5),
  (@p2_id, '/uploads/properties/pv_65_kamar_mandi.jpg', 'Kamar Mandi', 'Kamar Mandi Modern Tipe 65', 'Shower & closet duduk berkualitas', 'Keramik anti-slip estetik', 6);

-- 3. Tipe 45 (Joglo Modern)
INSERT INTO properties (title, category, location, price, status)
VALUES ('Prambanan Village - Tipe 45 (Joglo Modern)', 'Prambanan Village', 'Prambanan Village III, Area Sawah, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454', 385000000, 'Tersedia');
SET @p3_id = LAST_INSERT_ID();

INSERT INTO property_gallery_images (property_id, image_url, title, subtitle, detail_primary, detail_secondary, sort_order) VALUES
  (@p3_id, '/uploads/properties/prambanan_tipe_45.jpg', 'Tampak Depan (Joglo Asri)', 'Fasad Joglo Tropis Modern Bata Ekspos', 'Bata ekspos merah & ukiran kayu jendela', 'Taman bunga & teras depan asri', 1),
  (@p3_id, '/uploads/properties/pv_45_ruang_tamu.jpg', 'Ruang Tamu', 'Interior Joglo Modern - View Candi Prambanan', 'Bata ekspos & kayu jati, nuansa etnik modern', 'View candi Prambanan dari jendela panoramik', 2),
  (@p3_id, '/uploads/properties/pv_45_kamar_tidur.jpg', 'Kamar Tidur Utama', 'Kamar Tidur Nyaman Joglo', 'Penataan fungsional & tenang', 'Sirkulasi udara segar alami dari taman', 3),
  (@p3_id, '/uploads/properties/pv_45_dapur.jpg', 'Dapur', 'Dapur Bersih Kompak Tipe 45', 'Meja dapur cor & kitchen sink modern', 'Mudah dibersihkan & ventilasi baik', 4),
  (@p3_id, '/uploads/properties/pv_45_kamar_mandi.jpg', 'Kamar Mandi', 'Kamar Mandi Bersih Tipe 45', 'Shower & kloset berkualitas', 'Dinding keramik estetik', 5);

-- 4. Tipe 36 (Limasan Minimalis)
INSERT INTO properties (title, category, location, price, status)
VALUES ('Prambanan Village - Tipe 36 (Limasan Minimalis)', 'Prambanan Village', 'Prambanan Village III, Area Sawah, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454', 295000000, 'Tersedia');
SET @p4_id = LAST_INSERT_ID();

INSERT INTO property_gallery_images (property_id, image_url, title, subtitle, detail_primary, detail_secondary, sort_order) VALUES
  (@p4_id, '/uploads/properties/prambanan_tipe_36.jpg', 'Tampak Depan (Limasan Minimalis)', 'Fasad Limasan Compact & Elegan', 'Lisplang ukir putih & bata ekspos', 'Carport & jalan setapak batu alam', 1),
  (@p4_id, '/uploads/properties/pv_36_ruang_tamu.jpg', 'Ruang Tamu', 'Interior Limasan Minimalis Nyaman', 'Ruangan compact hangat & nyaman nuansa Jawa', 'Plafon kayu tinggi & jendela ventilasi jati', 2),
  (@p4_id, '/uploads/properties/pv_36_kamar_tidur.jpg', 'Kamar Tidur', 'Kamar Tidur Fungsional Tipe 36', 'Kenyamanan istirahat maksimal', 'Jendela ventilasi asri & sirkulasi udara', 3),
  (@p4_id, '/uploads/properties/pv_36_dapur.jpg', 'Dapur', 'Dapur Kompak Efisien Tipe 36', 'Penataan hemat ruang & praktis', 'Fasilitas memasak lengkap', 4),
  (@p4_id, '/uploads/properties/pv_36_kamar_mandi.jpg', 'Kamar Mandi', 'Kamar Mandi Bersih Tipe 36', 'Bersih & higienis', 'Shower & closet duduk', 5);

COMMIT;
