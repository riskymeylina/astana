-- Migration: 0003_add_midtrans_payment_columns
-- Description: Add Midtrans payment gateway columns to property_purchases

ALTER TABLE `property_purchases`
  ADD COLUMN `midtrans_order_id` varchar(100) DEFAULT NULL,
  ADD COLUMN `midtrans_transaction_id` varchar(100) DEFAULT NULL,
  ADD COLUMN `midtrans_qr_url` text DEFAULT NULL,
  ADD COLUMN `midtrans_payment_status` varchar(50) DEFAULT NULL,
  ADD COLUMN `midtrans_expiry_time` datetime DEFAULT NULL,
  ADD KEY `pp_midtrans_order_id_index` (`midtrans_order_id`);
