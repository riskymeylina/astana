-- ================================================================
-- Migration: 0004_add_buyer_records
-- Description: Tambah tabel buyer_records untuk data pembeli historis
--              (pembeli lama yang dicatat admin sebelum ada aplikasi)
--              dan kolom data_source ke property_purchases
-- ================================================================

SET FOREIGN_KEY_CHECKS = 0;

-- Tabel data pembeli historis
-- Digunakan untuk pembeli lama yang dicatat admin dari catatan perusahaan
-- Bisa terhubung ke users.id_user jika pembeli sudah punya akun aplikasi
CREATE TABLE IF NOT EXISTS `buyer_records` (
  `id_buyer_record`   bigint unsigned NOT NULL AUTO_INCREMENT,
  `linked_user_id`    bigint unsigned DEFAULT NULL COMMENT 'FK ke users.id_user jika pembeli sudah punya akun',
  `full_name`         varchar(150) NOT NULL,
  `phone`             varchar(20) DEFAULT NULL,
  `email`             varchar(191) DEFAULT NULL,
  `address`           text DEFAULT NULL,
  `notes`             text DEFAULT NULL COMMENT 'Catatan tambahan admin',
  `data_source`       enum('app_registration','manual_admin','historical_company') NOT NULL DEFAULT 'manual_admin' COMMENT 'app_registration=daftar sendiri, manual_admin=diinput admin, historical_company=data historis perusahaan',
  `data_label`        varchar(50) DEFAULT NULL COMMENT 'Label opsional: SIMULASI, TERVERIFIKASI, PERLU_KONFIRMASI dsb',
  `verification_status` enum('unverified','pending_verification','verified') NOT NULL DEFAULT 'unverified',
  `verified_by_user_id` bigint unsigned DEFAULT NULL,
  `verified_at`       datetime DEFAULT NULL,
  `recorded_by_user_id` bigint unsigned NOT NULL COMMENT 'Admin yang mencatat data ini',
  `created_at`        timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_buyer_record`),
  UNIQUE KEY `buyer_records_linked_user_unique` (`linked_user_id`),
  KEY `buyer_records_full_name_idx` (`full_name`),
  KEY `buyer_records_phone_idx` (`phone`),
  KEY `buyer_records_email_idx` (`email`),
  KEY `buyer_records_data_source_idx` (`data_source`),
  KEY `buyer_records_verification_status_idx` (`verification_status`),
  KEY `buyer_records_recorded_by_idx` (`recorded_by_user_id`),
  CONSTRAINT `fk_buyer_records_linked_user` FOREIGN KEY (`linked_user_id`) REFERENCES `users` (`id_user`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_buyer_records_recorded_by` FOREIGN KEY (`recorded_by_user_id`) REFERENCES `users` (`id_user`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_buyer_records_verified_by` FOREIGN KEY (`verified_by_user_id`) REFERENCES `users` (`id_user`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Data pembeli historis dan yang diinput manual admin';

-- Tabel transaksi historis (penjualan lama yang dicatat admin)
-- Berbeda dengan property_purchases yang digunakan untuk transaksi online
CREATE TABLE IF NOT EXISTS `historical_sales` (
  `id_historical_sale`  bigint unsigned NOT NULL AUTO_INCREMENT,
  `buyer_record_id`     bigint unsigned NOT NULL COMMENT 'FK ke buyer_records',
  `property_id`         bigint unsigned DEFAULT NULL COMMENT 'NULL jika properti tidak lagi tercatat di sistem',
  `property_name_snapshot` varchar(255) NOT NULL COMMENT 'Nama properti saat transaksi dicatat',
  `transaction_date`    date DEFAULT NULL COMMENT 'Tanggal transaksi historis (dari catatan perusahaan)',
  `transaction_value`   bigint unsigned DEFAULT NULL COMMENT 'Nilai transaksi (Rupiah)',
  `payment_method`      varchar(100) DEFAULT NULL,
  `status`              enum('completed','pending','cancelled') NOT NULL DEFAULT 'completed',
  `notes`               text DEFAULT NULL,
  `data_label`          varchar(50) DEFAULT NULL COMMENT 'SIMULASI / TERVERIFIKASI / dsb',
  `recorded_by_user_id` bigint unsigned NOT NULL,
  `recorded_at`         timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_historical_sale`),
  KEY `historical_sales_buyer_record_idx` (`buyer_record_id`),
  KEY `historical_sales_property_idx` (`property_id`),
  KEY `historical_sales_date_idx` (`transaction_date`),
  KEY `historical_sales_status_idx` (`status`),
  CONSTRAINT `fk_historical_sales_buyer_record` FOREIGN KEY (`buyer_record_id`) REFERENCES `buyer_records` (`id_buyer_record`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_historical_sales_property` FOREIGN KEY (`property_id`) REFERENCES `properties` (`id_property`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_historical_sales_recorded_by` FOREIGN KEY (`recorded_by_user_id`) REFERENCES `users` (`id_user`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Riwayat penjualan historis yang diinput manual oleh admin';

SET FOREIGN_KEY_CHECKS = 1;
