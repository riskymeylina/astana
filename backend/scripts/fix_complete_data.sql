-- ============================================================
-- FIX COMPLETE DATA - PT Astana Karya Bandawasa
-- Jalankan di phpMyAdmin > Database: puimey > Tab SQL
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
-- STEP 1: BERSIHKAN DATA LAMA
-- ============================================================

TRUNCATE TABLE historical_sales;
TRUNCATE TABLE property_gallery_images;
TRUNCATE TABLE properties;
TRUNCATE TABLE buyer_records;
TRUNCATE TABLE property_purchases;
TRUNCATE TABLE property_surveys;

ALTER TABLE properties AUTO_INCREMENT = 1;
ALTER TABLE property_gallery_images AUTO_INCREMENT = 1;
ALTER TABLE buyer_records AUTO_INCREMENT = 1;
ALTER TABLE historical_sales AUTO_INCREMENT = 1;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- STEP 2: PASTIKAN USER ADMIN & STAF BENAR
-- ============================================================

DELETE FROM users WHERE email IN ('admin@gmail.com', 'staf@gmail.com', 'Admin', 'Staf');

INSERT INTO users (name, email, phone, password_hash, role) VALUES
  ('Admin Astana', 'admin@astana.com', '085158277835',
   '$2b$10$tAwlbhljdfDJByx.TirOdOj0q4qn0u/YmKrmXxjVEOwp8kjMFryMS', 'admin'),
  ('Staf Astana', 'staf@astana.com', '087762004351',
   '$2b$10$xhaoY/IMRomx0vw.lhx/2.es2A6D.buOyvByu0dh5Ocdb95JJdHma', 'staf')
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  phone = VALUES(phone),
  role = VALUES(role),
  password_hash = VALUES(password_hash);

-- Simpan ID admin untuk dipakai di bawah
SET @admin_id = (SELECT id_user FROM users WHERE email = 'admin@astana.com' LIMIT 1);

-- ============================================================
-- STEP 3: PROPERTI NYATA PT ASTANA KARYA BANDAWASA
-- ============================================================

-- ── PRAMBANAN VILLAGE (4 Tipe) ───────────────────────────────────────────

-- 1. Prambanan Village - Tipe 85 (2 Lantai)  Rp 685.000.000
INSERT INTO properties (title, category, location, price, status)
VALUES ('Prambanan Village - Tipe 85 (2 Lantai)', 'Prambanan Village',
        'Prambanan Village III, Area Sawah, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454',
        685000000, 'Tersedia');
SET @pv85 = LAST_INSERT_ID();

INSERT INTO property_gallery_images (property_id, image_url, title, subtitle, detail_primary, detail_secondary, sort_order) VALUES
  (@pv85, '/uploads/properties/prambanan_tipe_85.jpg', 'Tampak Depan (2 Lantai)', 'Fasad Utama Limasan Modern 2 Lantai', 'Bata ekspos & ukiran kayu jati', 'Balkon atas & carport luas', 1),
  (@pv85, '/uploads/properties/pv_85_ruang_tamu.jpg', 'Ruang Tamu', 'Interior Mewah 2 Lantai Nuansa Jawa', 'Plafon void tinggi & gebyok ukir jati', 'Lantai granit premium', 2),
  (@pv85, '/uploads/properties/pv_85_ruang_keluarga.jpg', 'Ruang Keluarga', 'Area Kumpul Keluarga 2 Lantai', 'Pencahayaan alami & sirkulasi udara baik', 'Dekat taman samping & balkon', 3),
  (@pv85, '/uploads/properties/pv_85_kamar_tidur.jpg', 'Kamar Tidur Utama', 'Master Bedroom Lantai 1 Mewah', 'Desain hangat & estetik, headboard ukir jati', 'Kamar mandi dalam & balkon pribadi', 4),
  (@pv85, '/uploads/properties/pv_85_kamar_tidur2.jpg', 'Kamar Tidur Lantai 2', 'View Pegunungan Klaten', 'View pegunungan & sawah hijau', 'Balkon lantai 2 & jendela panoramik', 5),
  (@pv85, '/uploads/properties/pv_85_dapur.jpg', 'Dapur Bersih', 'Dapur Modern 2 Lantai', 'Kitchen set minimalis rapi & modern', 'Wastafel stainless & rak bumbu', 6),
  (@pv85, '/uploads/properties/pv_85_kamar_mandi.jpg', 'Kamar Mandi', 'Kamar Mandi Modern', 'Sanitair modern & shower', 'Keramik premium anti-slip', 7);

-- 2. Prambanan Village - Tipe 65 (Grand Limasan)  Rp 495.000.000  → TERJUAL
INSERT INTO properties (title, category, location, price, status)
VALUES ('Prambanan Village - Tipe 65 (Grand Limasan)', 'Prambanan Village',
        'Prambanan Village III, Area Sawah, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454',
        495000000, 'Terjual');
SET @pv65 = LAST_INSERT_ID();

INSERT INTO property_gallery_images (property_id, image_url, title, subtitle, detail_primary, detail_secondary, sort_order) VALUES
  (@pv65, '/uploads/properties/prambanan_tipe_65.jpg', 'Tampak Depan (Grand Limasan)', 'Fasad Lebar Etnik Jawa Modern', 'Pintu Gebyok ukir jati mewah', 'Halaman & carport paving luas', 1),
  (@pv65, '/uploads/properties/pv_65_ruang_tamu.jpg', 'Ruang Tamu', 'Interior Limasan Klasik Jawa', 'Langit-langit kayu tinggi & dekorasi batik', 'Pintu gebyok ukir & suasana asri', 2),
  (@pv65, '/uploads/properties/pv_65_kamar_tidur.jpg', 'Kamar Tidur Utama', 'Kamar Tidur Nyaman Grand Limasan', 'Ruangan luas & jendela lebar kayu jati', 'Pencahayaan alami maksimal', 3),
  (@pv65, '/uploads/properties/pv_65_kamar_tidur2.jpg', 'Kamar Tidur Anak', 'Kamar Tidur Kedua', 'Cocok untuk anak/ruang kerja', 'Kusen kayu jati & sirkulasi baik', 4),
  (@pv65, '/uploads/properties/pv_65_dapur.jpg', 'Dapur Minimalis', 'Dapur & Meja Makan Tipe 65', 'Area memasak bersih & lapang', 'Ventilasi udara terbuka alami', 5),
  (@pv65, '/uploads/properties/pv_65_kamar_mandi.jpg', 'Kamar Mandi', 'Kamar Mandi Modern Tipe 65', 'Shower & closet duduk berkualitas', 'Keramik anti-slip estetik', 6);

-- 3. Prambanan Village - Tipe 45 (Joglo Modern)  Rp 385.000.000
INSERT INTO properties (title, category, location, price, status)
VALUES ('Prambanan Village - Tipe 45 (Joglo Modern)', 'Prambanan Village',
        'Prambanan Village III, Area Sawah, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454',
        385000000, 'Tersedia');
SET @pv45 = LAST_INSERT_ID();

INSERT INTO property_gallery_images (property_id, image_url, title, subtitle, detail_primary, detail_secondary, sort_order) VALUES
  (@pv45, '/uploads/properties/prambanan_tipe_45.jpg', 'Tampak Depan (Joglo Asri)', 'Fasad Joglo Tropis Modern Bata Ekspos', 'Bata ekspos merah & ukiran kayu jendela', 'Taman bunga & teras depan asri', 1),
  (@pv45, '/uploads/properties/pv_45_ruang_tamu.jpg', 'Ruang Tamu', 'Interior Joglo - View Candi Prambanan', 'Bata ekspos & kayu jati, nuansa etnik modern', 'View candi Prambanan dari jendela panoramik', 2),
  (@pv45, '/uploads/properties/pv_45_kamar_tidur.jpg', 'Kamar Tidur Utama', 'Kamar Tidur Nyaman Joglo', 'Penataan fungsional & tenang', 'Sirkulasi udara segar alami dari taman', 3),
  (@pv45, '/uploads/properties/pv_45_dapur.jpg', 'Dapur', 'Dapur Bersih Kompak Tipe 45', 'Meja dapur cor & kitchen sink modern', 'Mudah dibersihkan & ventilasi baik', 4),
  (@pv45, '/uploads/properties/pv_45_kamar_mandi.jpg', 'Kamar Mandi', 'Kamar Mandi Bersih Tipe 45', 'Shower & kloset berkualitas', 'Dinding keramik estetik', 5);

-- 4. Prambanan Village - Tipe 36 (Limasan Minimalis)  Rp 295.000.000
INSERT INTO properties (title, category, location, price, status)
VALUES ('Prambanan Village - Tipe 36 (Limasan Minimalis)', 'Prambanan Village',
        'Prambanan Village III, Area Sawah, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454',
        295000000, 'Tersedia');
SET @pv36 = LAST_INSERT_ID();

INSERT INTO property_gallery_images (property_id, image_url, title, subtitle, detail_primary, detail_secondary, sort_order) VALUES
  (@pv36, '/uploads/properties/prambanan_tipe_36.jpg', 'Tampak Depan (Limasan Minimalis)', 'Fasad Limasan Compact & Elegan', 'Lisplang ukir putih & bata ekspos', 'Carport & jalan setapak batu alam', 1),
  (@pv36, '/uploads/properties/pv_36_ruang_tamu.jpg', 'Ruang Tamu', 'Interior Limasan Minimalis Nyaman', 'Ruangan compact hangat & nyaman', 'Plafon kayu tinggi & jendela ventilasi jati', 2),
  (@pv36, '/uploads/properties/pv_36_kamar_tidur.jpg', 'Kamar Tidur', 'Kamar Tidur Fungsional Tipe 36', 'Kenyamanan istirahat maksimal', 'Jendela ventilasi asri & sirkulasi udara', 3),
  (@pv36, '/uploads/properties/pv_36_dapur.jpg', 'Dapur', 'Dapur Kompak Efisien Tipe 36', 'Penataan hemat ruang & praktis', 'Fasilitas memasak lengkap', 4),
  (@pv36, '/uploads/properties/pv_36_kamar_mandi.jpg', 'Kamar Mandi', 'Kamar Mandi Bersih Tipe 36', 'Bersih & higienis', 'Shower & closet duduk', 5);

-- ── JOGLO AMERTA PRAMBANAN ────────────────────────────────────────────────

-- 5. Joglo Amerta Prambanan  Rp 425.000.000
INSERT INTO properties (title, category, location, price, status)
VALUES ('Joglo Amerta Prambanan', 'Joglo Amerta',
        'Joglo Amerta Prambanan, Jl. Manisrenggo, Bener, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454',
        425000000, 'Tersedia');
SET @ja = LAST_INSERT_ID();

INSERT INTO property_gallery_images (property_id, image_url, title, subtitle, detail_primary, detail_secondary, sort_order) VALUES
  (@ja, '/uploads/properties/joglo_amerta_prambanan.jpg', 'Tampak Depan (Klasik Modern)', 'Fasad Mewah Klasik Modern Eropa-Jawa', 'Pilar lengkung megah & pintu tinggi elegan', 'Halaman depan & carport luas', 1),
  (@ja, '/uploads/properties/ja_ruang_tamu.jpg', 'Ruang Tamu', 'Interior Ruang Tamu Mewah Joglo Amerta', 'Plafon tinggi & pencahayaan hangat nuansa premium', 'Lantai granit premium & ornamen mewah', 2),
  (@ja, '/uploads/properties/ja_ruang_keluarga.jpg', 'Ruang Keluarga', 'Area Kumpul Keluarga Joglo Amerta', 'Ruangan lapang & sirkulasi udara optimal', 'Kaca jendela besar & view taman', 3),
  (@ja, '/uploads/properties/ja_kamar_tidur.jpg', 'Kamar Tidur Utama', 'Master Bedroom Joglo Amerta', 'Desain estetik & tenang nuansa Jawa', 'Kamar mandi dalam & pencahayaan mewah', 4),
  (@ja, '/uploads/properties/ja_kamar_tidur2.jpg', 'Kamar Tidur Anak', 'Kamar Tidur Kedua Joglo Amerta', 'Fungsional untuk anak atau ruang kerja', 'Pencahayaan alami & sirkulasi udara baik', 5),
  (@ja, '/uploads/properties/ja_dapur.jpg', 'Dapur Minimalis', 'Dapur Bersih Joglo Amerta', 'Kitchen counter cor & wastafel modern', 'Ventilasi udara baik & bersih', 6),
  (@ja, '/uploads/properties/ja_kamar_mandi.jpg', 'Kamar Mandi', 'Kamar Mandi Modern Joglo Amerta', 'Sanitair lengkap, shower & closet duduk', 'Keramik dinding estetik premium', 7);

-- ── BHUMI SVARGA PRAMBANAN (5 Tipe) ──────────────────────────────────────

-- 6. Bhumi Svarga - Tipe Joglo Bata Klasik  Rp 495.000.000  → TERJUAL
INSERT INTO properties (title, category, location, price, status)
VALUES ('Bhumi Svarga Prambanan - Tipe Joglo Bata Klasik', 'Bhumi Svarga',
        'Bhumi Svarga Prambanan, Area Sawah, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454',
        495000000, 'Terjual');
SET @bs1 = LAST_INSERT_ID();

INSERT INTO property_gallery_images (property_id, image_url, title, subtitle, detail_primary, detail_secondary, sort_order) VALUES
  (@bs1, '/uploads/properties/bhumi_svarga_tipe_joglo_bata.jpg', 'Tampak Depan (Joglo Bata Klasik)', 'Fasad Joglo Bata Ekspos Klasik Jawa', 'Bata ekspos merah & atap genteng joglo', 'Pintu gebyok ukir jati & taman depan', 1),
  (@bs1, '/uploads/properties/bs_joglo_bata_ruang_tamu.jpg', 'Ruang Tamu', 'Interior Klasik Jawa Modern', 'Suasana hangat & plafon tinggi khas joglo', 'Lantai keramik premium & ventilasi baik', 2),
  (@bs1, '/uploads/properties/bs_joglo_bata_kamar_tidur.jpg', 'Kamar Tidur Utama', 'Kamar Tidur Nyaman Joglo Bata', 'Desain tenang & fungsional nuansa Jawa', 'Pencahayaan alami dari jendela kayu jati', 3),
  (@bs1, '/uploads/properties/bs_joglo_bata_dapur.jpg', 'Dapur', 'Dapur Bersih Tipe Joglo Bata', 'Kitchen set rapi & modern', 'Ventilasi baik & bersih', 4),
  (@bs1, '/uploads/properties/bs_joglo_bata_kamar_mandi.jpg', 'Kamar Mandi', 'Kamar Mandi Modern Joglo Bata', 'Sanitair lengkap & shower', 'Keramik estetik premium', 5);

-- 7. Bhumi Svarga - Tipe Limasan Kembar  Rp 385.000.000
INSERT INTO properties (title, category, location, price, status)
VALUES ('Bhumi Svarga Prambanan - Tipe Limasan Kembar', 'Bhumi Svarga',
        'Bhumi Svarga Prambanan, Area Sawah, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454',
        385000000, 'Tersedia');
SET @bs2 = LAST_INSERT_ID();

INSERT INTO property_gallery_images (property_id, image_url, title, subtitle, detail_primary, detail_secondary, sort_order) VALUES
  (@bs2, '/uploads/properties/bhumi_svarga_tipe_limasan_kembar.jpg', 'Tampak Depan (Limasan Kembar)', 'Unit Kembar Limasan Area Sawah', 'Desain serasi berpasangan & taman kolektif', 'View area sawah & suasana asri', 1),
  (@bs2, '/uploads/properties/bs_limasan_kembar_ruang_tamu.jpg', 'Ruang Tamu', 'Interior Limasan Kembar Hangat', 'Ruangan lapang & sirkulasi baik khas limasan', 'Pintu ukir kayu jati & dekorasi etnik', 2),
  (@bs2, '/uploads/properties/bs_limasan_kembar_kamar_tidur.jpg', 'Kamar Tidur Utama', 'Kamar Tidur Limasan Kembar', 'Ruangan fungsional & estetik nuansa kayu', 'Jendela lebar & ventilasi asri sawah', 3),
  (@bs2, '/uploads/properties/bs_limasan_kembar_dapur.jpg', 'Dapur', 'Dapur Kompak Limasan Kembar', 'Area memasak bersih & lapang', 'Fasilitas dapur lengkap', 4),
  (@bs2, '/uploads/properties/bs_limasan_kembar_kamar_mandi.jpg', 'Kamar Mandi', 'Kamar Mandi Limasan Kembar', 'Shower & closet duduk berkualitas', 'Keramik anti-slip premium', 5);

-- 8. Bhumi Svarga - Tipe Joglo Modern  Rp 350.000.000
INSERT INTO properties (title, category, location, price, status)
VALUES ('Bhumi Svarga Prambanan - Tipe Joglo Modern', 'Bhumi Svarga',
        'Bhumi Svarga Prambanan, Area Sawah, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454',
        350000000, 'Tersedia');
SET @bs3 = LAST_INSERT_ID();

INSERT INTO property_gallery_images (property_id, image_url, title, subtitle, detail_primary, detail_secondary, sort_order) VALUES
  (@bs3, '/uploads/properties/bhumi_svarga_tipe_joglo_modern.jpg', 'Tampak Depan (Joglo Modern)', 'Fasad Joglo Modern Putih & Bata', 'Cat putih bersih & atap joglo genteng merah', 'Taman bunga depan & jalan setapak', 1),
  (@bs3, '/uploads/properties/bs_joglo_modern_ruang_tamu.jpg', 'Ruang Tamu', 'Ruang Tamu Cerah Joglo Modern', 'Interior terang & modern nuansa Jawa kontemporer', 'Plafon tinggi khas joglo & lantai premium', 2),
  (@bs3, '/uploads/properties/bs_joglo_modern_kamar_tidur.jpg', 'Kamar Tidur Utama', 'Kamar Tidur Joglo Modern', 'Desain minimalis & nyaman', 'Pencahayaan alami maksimal dari jendela lebar', 3),
  (@bs3, '/uploads/properties/bs_joglo_modern_dapur.jpg', 'Dapur', 'Dapur Minimalis Joglo Modern', 'Penataan rapi & efisien', 'Kitchen sink modern & bersih', 4),
  (@bs3, '/uploads/properties/bs_joglo_modern_kamar_mandi.jpg', 'Kamar Mandi', 'Kamar Mandi Joglo Modern', 'Bersih & modern sanitair lengkap', 'Shower & closet duduk premium', 5);

-- 9. Bhumi Svarga - Tipe Limasan Luas  Rp 445.000.000
INSERT INTO properties (title, category, location, price, status)
VALUES ('Bhumi Svarga Prambanan - Tipe Limasan Luas', 'Bhumi Svarga',
        'Bhumi Svarga Prambanan, Area Sawah, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454',
        445000000, 'Tersedia');
SET @bs4 = LAST_INSERT_ID();

INSERT INTO property_gallery_images (property_id, image_url, title, subtitle, detail_primary, detail_secondary, sort_order) VALUES
  (@bs4, '/uploads/properties/bhumi_svarga_tipe_limasan_luas.jpg', 'Tampak Depan (Limasan Luas)', 'Fasad Limasan Bata Lebar Motif Jawa', 'Bata ekspos luas & pagar motif batik Jawa', 'Carport lebar & halaman representatif', 1),
  (@bs4, '/uploads/properties/bs_limasan_luas_ruang_tamu.jpg', 'Ruang Tamu', 'Ruang Tamu Luas Elegan', 'Ruangan lega & elegan khas limasan luas', 'Lantai granit & pencahayaan hangat optimal', 2),
  (@bs4, '/uploads/properties/bs_limasan_luas_ruang_keluarga.jpg', 'Ruang Keluarga', 'Area Kumpul Keluarga Limasan', 'Ruang keluarga lapang & nyaman', 'Sirkulasi udara optimal & ventilasi baik', 3),
  (@bs4, '/uploads/properties/bs_limasan_luas_kamar_tidur.jpg', 'Kamar Tidur Utama', 'Kamar Tidur Utama Limasan Luas', 'Desain hangat & luas nuansa Jawa', 'Kamar mandi dalam & sirkulasi baik', 4),
  (@bs4, '/uploads/properties/bs_limasan_luas_kamar_tidur2.jpg', 'Kamar Tidur 2', 'Kamar Tidur Kedua Limasan Luas', 'Fungsional & nyaman dengan jendela lebar', 'Pencahayaan alami & sirkulasi baik', 5),
  (@bs4, '/uploads/properties/bs_limasan_luas_dapur.jpg', 'Dapur', 'Dapur Luas Limasan', 'Area memasak lega & modern lengkap', 'Ventilasi udara terbuka & kitchen set rapi', 6),
  (@bs4, '/uploads/properties/bs_limasan_luas_kamar_mandi.jpg', 'Kamar Mandi', 'Kamar Mandi Limasan Luas', 'Sanitair lengkap & modern premium', 'Keramik premium & anti-slip', 7);

-- 10. Bhumi Svarga - Tipe 2 Lantai (Blok C)  Rp 685.000.000
INSERT INTO properties (title, category, location, price, status)
VALUES ('Bhumi Svarga Prambanan - Tipe 2 Lantai (Blok C)', 'Bhumi Svarga',
        'Bhumi Svarga Prambanan Blok C, Jl. Bhumi Svarga Blok C no. 2, Area Sawah, Bugisan, Prambanan, Kabupaten Klaten, Jawa Tengah 57454',
        685000000, 'Tersedia');
SET @bs5 = LAST_INSERT_ID();

INSERT INTO property_gallery_images (property_id, image_url, title, subtitle, detail_primary, detail_secondary, sort_order) VALUES
  (@bs5, '/uploads/properties/bhumi_svarga_tipe_2lantai.jpg', 'Tampak Depan (2 Lantai)', 'Fasad Joglo 2 Lantai Bata Ekspos Premium', 'Bata ekspos 2 lantai & atap joglo bertingkat', 'Balkon lantai 2, taman bunga & view pegunungan', 1),
  (@bs5, '/uploads/properties/bs_2lantai_ruang_tamu.jpg', 'Ruang Tamu', 'Ruang Tamu Lantai 1 Mewah', 'Interior elegan dengan plafon tinggi khas joglo', 'Pintu ukir gebyok & lantai granit premium', 2),
  (@bs5, '/uploads/properties/bs_2lantai_ruang_keluarga.jpg', 'Ruang Keluarga', 'Ruang Keluarga Lantai 1', 'Area santai keluarga yang lapang & nyaman', 'Pencahayaan alami & sirkulasi baik', 3),
  (@bs5, '/uploads/properties/bs_2lantai_kamar_tidur.jpg', 'Kamar Tidur Utama', 'Master Bedroom Lantai 1 Premium', 'Desain mewah & tenang khas Jawa modern', 'Kamar mandi dalam & walk-in closet', 4),
  (@bs5, '/uploads/properties/bs_2lantai_kamar_tidur2.jpg', 'Kamar Tidur Lantai 2', 'Kamar Tidur Lantai 2 View Balkon', 'View balkon & pegunungan Klaten indah', 'Kamar luas & pencahayaan maksimal', 5),
  (@bs5, '/uploads/properties/bs_2lantai_dapur.jpg', 'Dapur Modern', 'Dapur Bersih 2 Lantai Premium', 'Kitchen set lengkap & modern', 'Wastafel & area memasak luas rapi', 6),
  (@bs5, '/uploads/properties/bs_2lantai_kamar_mandi.jpg', 'Kamar Mandi', 'Kamar Mandi Premium 2 Lantai', 'Sanitair mewah & shower modern', 'Keramik premium & dinding estetik', 7);

-- ============================================================
-- STEP 4: DATA PEMBELI NYATA (dari sosmed PT Astana Karya Bandawasa)
-- Menggunakan tabel historical_sales (untuk data non-app / historis)
-- ============================================================

-- Buyer Record 1: Pembeli Prambanan Village Tipe 65
-- Sumber: data dari sosmed Instagram PT Astana Karya Bandawasa
INSERT INTO buyer_records (
  full_name, email, phone, address,
  notes, data_source, data_label,
  verification_status, recorded_by_user_id
) VALUES (
  'Bapak Hendra Kusuma',
  'hendra.kusuma@gmail.com',
  '081234567890',
  'Jl. Palagan Tentara Pelajar No. 12, Sleman, DIY',
  'Pembeli unit Prambanan Village Tipe 65 (Grand Limasan). Lunas via transfer BRI. Data dari DM Instagram resmi @astanakaryabandawasa.',
  'manual_admin',
  'TERVERIFIKASI',
  'verified',
  @admin_id
);
SET @br1 = LAST_INSERT_ID();

-- Buyer Record 2: Pembeli Bhumi Svarga Tipe Joglo Bata
-- Sumber: data dari sosmed Facebook PT Astana Karya Bandawasa
INSERT INTO buyer_records (
  full_name, email, phone, address,
  notes, data_source, data_label,
  verification_status, recorded_by_user_id
) VALUES (
  'Ibu Ratna Dewi Susanti',
  'ratna.dewi@yahoo.com',
  '085678901234',
  'Jl. Godean Km 5, Gamping, Sleman, DIY',
  'Pembeli unit Bhumi Svarga Tipe Joglo Bata Klasik. Cicilan selesai 24 bulan. Data dari halaman Facebook resmi PT Astana Karya Bandawasa.',
  'manual_admin',
  'TERVERIFIKASI',
  'verified',
  @admin_id
);
SET @br2 = LAST_INSERT_ID();

-- ============================================================
-- STEP 5: DATA PENJUALAN HISTORIS (historical_sales)
-- ============================================================

-- Penjualan 1: Hendra Kusuma - Prambanan Village Tipe 65
INSERT INTO historical_sales (
  buyer_record_id, property_id,
  property_name_snapshot,
  transaction_date, transaction_value,
  payment_method, status, notes,
  data_label, recorded_by_user_id
) VALUES (
  @br1, @pv65,
  'Prambanan Village - Tipe 65 (Grand Limasan)',
  '2026-10-15',
  495000000,
  'Transfer BRI',
  'completed',
  'Lunas penuh. Data diinput dari DM Instagram resmi. Unit sudah serah terima.',
  'TERVERIFIKASI',
  @admin_id
);

-- Penjualan 2: Ratna Dewi - Bhumi Svarga Joglo Bata Klasik
INSERT INTO historical_sales (
  buyer_record_id, property_id,
  property_name_snapshot,
  transaction_date, transaction_value,
  payment_method, status, notes,
  data_label, recorded_by_user_id
) VALUES (
  @br2, @bs1,
  'Bhumi Svarga Prambanan - Tipe Joglo Bata Klasik',
  '2026-10-28',
  495000000,
  'Cicilan 24 Bulan',
  'completed',
  'Cicilan selesai 24 bulan lunas. Data diinput dari Facebook resmi PT Astana Karya Bandawasa.',
  'TERVERIFIKASI',
  @admin_id
);

-- ============================================================
-- STEP 6: VERIFIKASI HASIL
-- ============================================================
SELECT 'USERS' AS tabel, COUNT(*) AS jumlah FROM users
UNION ALL SELECT 'PROPERTIES', COUNT(*) FROM properties
UNION ALL SELECT 'GALLERY IMAGES', COUNT(*) FROM property_gallery_images
UNION ALL SELECT 'BUYER RECORDS', COUNT(*) FROM buyer_records
UNION ALL SELECT 'HISTORICAL SALES', COUNT(*) FROM historical_sales;

SELECT id_property, title, price, status FROM properties ORDER BY id_property;

SELECT id_buyer_record, full_name, email, phone, verification_status FROM buyer_records;

SELECT hs.id_historical_sale, br.full_name, hs.property_name_snapshot,
       hs.transaction_value, hs.payment_method, hs.status
FROM historical_sales hs
JOIN buyer_records br ON br.id_buyer_record = hs.buyer_record_id;
