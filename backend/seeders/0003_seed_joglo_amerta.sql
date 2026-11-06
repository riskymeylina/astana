-- ============================================================
-- Seeder: 0003_seed_joglo_amerta
-- Description: Seed data Joglo Amerta Prambanan
-- ============================================================

START TRANSACTION;

-- 1. Joglo Amerta Prambanan
INSERT INTO properties (title, category, location, price, status)
VALUES ('Joglo Amerta Prambanan', 'Joglo Amerta', 'Joglo Amerta Prambanan, Jl. Manisrenggo, Bener, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454', 425000000, 'Tersedia');
SET @p_amerta_id = LAST_INSERT_ID();

INSERT INTO property_gallery_images (property_id, image_url, title, subtitle, detail_primary, detail_secondary, sort_order) VALUES
  (@p_amerta_id, '/uploads/properties/joglo_amerta_prambanan.jpg', 'Tampak Depan (Klasik Modern)', 'Fasad Mewah Klasik Modern Eropa-Jawa', 'Pilar lengkung megah & pintu tinggi elegan', 'Halaman depan & carport luas', 1),
  (@p_amerta_id, '/uploads/properties/ja_ruang_tamu.jpg', 'Ruang Tamu', 'Interior Ruang Tamu Mewah Joglo Amerta', 'Plafon tinggi & pencahayaan hangat nuansa premium', 'Lantai granit premium & ornamen mewah', 2),
  (@p_amerta_id, '/uploads/properties/ja_ruang_keluarga.jpg', 'Ruang Keluarga', 'Area Kumpul Keluarga Joglo Amerta', 'Ruangan lapang & sirkulasi udara optimal', 'Kaca jendela besar & view taman', 3),
  (@p_amerta_id, '/uploads/properties/ja_kamar_tidur.jpg', 'Kamar Tidur Utama', 'Master Bedroom Joglo Amerta', 'Desain estetik & tenang nuansa Jawa', 'Kamar mandi dalam & pencahayaan mewah', 4),
  (@p_amerta_id, '/uploads/properties/ja_kamar_tidur2.jpg', 'Kamar Tidur Anak', 'Kamar Tidur Kedua Joglo Amerta', 'Fungsional untuk anak atau ruang kerja', 'Pencahayaan alami & sirkulasi udara baik', 5),
  (@p_amerta_id, '/uploads/properties/ja_dapur.jpg', 'Dapur Minimalis', 'Dapur Bersih Joglo Amerta', 'Kitchen counter cor & wastafel modern', 'Ventilasi udara baik & bersih', 6),
  (@p_amerta_id, '/uploads/properties/ja_kamar_mandi.jpg', 'Kamar Mandi', 'Kamar Mandi Modern Joglo Amerta', 'Sanitair lengkap, shower & closet duduk', 'Keramik dinding estetik premium', 7);

COMMIT;

