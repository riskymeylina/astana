-- ============================================================
-- Seeder: 0001_seed_users
-- Description: Seed data user admin & staf PT Astana Karya Bandawasa
-- Password: admin123 / staf123
-- ============================================================

START TRANSACTION;

-- -----------------------------------------------
-- Default Users: Admin & Staf PT Astana Karya Bandawasa
-- -----------------------------------------------
INSERT INTO users (name, email, phone, password_hash, role) VALUES
  ('Admin Astana', 'admin@astana.com', '085158277835',
   '$2b$10$tAwlbhljdfDJByx.TirOdOj0q4qn0u/YmKrmXxjVEOwp8kjMFryMS', 'admin'),
  ('Staf Astana',  'staf@astana.com',  '087762004351',
   '$2b$10$xhaoY/IMRomx0vw.lhx/2.es2A6D.buOyvByu0dh5Ocdb95JJdHma', 'staf')
ON DUPLICATE KEY UPDATE
  name       = VALUES(name),
  phone      = VALUES(phone),
  role       = VALUES(role),
  password_hash = VALUES(password_hash);

COMMIT;
