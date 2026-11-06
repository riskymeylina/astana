require('dotenv').config();
const mysql = require('mysql2/promise');

async function syncAllData() {
  const conn = await mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'puimey',
  });

  console.log('Connected to puimey DB');

  // 1. Remove dummy Test User from invoices and property_purchases
  await conn.query("DELETE FROM invoices WHERE purchase_id = 1");
  await conn.query("DELETE FROM property_purchases WHERE id_purchase = 1 OR buyer_name_snapshot = 'Test User'");
  console.log('Removed dummy Test User purchase');

  // Set property 8 back to Tersedia
  await conn.query("UPDATE properties SET status = 'Tersedia' WHERE id_property = 8");

  // 2. Synchronize Hendra Kusuma into property_purchases if not exists
  const [existingHendra] = await conn.query("SELECT id_purchase FROM property_purchases WHERE buyer_record_id = 1");
  if (existingHendra.length === 0) {
    await conn.query(`
      INSERT INTO property_purchases (
        buyer_user_id, buyer_record_id, property_id, payment_method,
        payment_amount, buyer_name_snapshot, buyer_phone_snapshot, buyer_address_snapshot,
        notes, status, processed_by_user_id, processed_by_name, processed_at, created_at, updated_at
      ) VALUES (
        1, 1, 20, 'Transfer Bank',
        495000000, 'Bapak Hendra Kusuma', '081234567890', 'Jl. Palagan Tentara Pelajar No. 12, Sleman, DIY',
        'Pembelian unit Prambanan Village Tipe 65 - Lunas via transfer BRI (Sosmed Instagram)',
        'confirmed', 1, 'Admin Astana', '2026-10-15 11:00:00', '2026-10-15 10:30:00', '2026-10-15 11:00:00'
      )
    `);
    console.log('Inserted purchase for Hendra Kusuma');
  }

  // 3. Synchronize Ratna Dewi into property_purchases if not exists
  const [existingRatna] = await conn.query("SELECT id_purchase FROM property_purchases WHERE buyer_record_id = 2");
  if (existingRatna.length === 0) {
    await conn.query(`
      INSERT INTO property_purchases (
        buyer_user_id, buyer_record_id, property_id, payment_method,
        payment_amount, buyer_name_snapshot, buyer_phone_snapshot, buyer_address_snapshot,
        notes, status, processed_by_user_id, processed_by_name, processed_at, created_at, updated_at
      ) VALUES (
        1, 2, 24, 'Cicilan',
        495000000, 'Ibu Ratna Dewi Susanti', '085678901234', 'Jl. Godean Km 5, Gamping, Sleman, DIY',
        'Pembelian unit Bhumi Svarga Tipe Joglo Bata Klasik - Cicilan selesai 24 bulan lunas (Sosmed Facebook)',
        'confirmed', 1, 'Admin Astana', '2026-10-28 15:00:00', '2026-10-28 14:15:00', '2026-10-28 15:00:00'
      )
    `);
    console.log('Inserted purchase for Ratna Dewi');
  }

  // 4. Update sold status for property 20 and 24
  await conn.query("UPDATE properties SET status = 'Terjual' WHERE id_property IN (9, 20, 24)");

  // 5. Audit all counts and sums
  const [purchases] = await conn.query(`
    SELECT pp.id_purchase, pp.buyer_name_snapshot, pp.status, pp.payment_amount, p.title AS property_title
    FROM property_purchases pp
    JOIN properties p ON p.id_property = pp.property_id
    ORDER BY pp.id_purchase
  `);
  console.log('\n=== CURRENT PURCHASES ===');
  console.table(purchases);

  const [revResult] = await conn.query(`
    SELECT
      COUNT(*) AS total_transactions,
      SUM(CASE WHEN status = 'confirmed' THEN 1 ELSE 0 END) AS confirmed_count,
      SUM(CASE WHEN status = 'confirmed' THEN payment_amount ELSE 0 END) AS total_revenue
    FROM property_purchases
  `);
  console.log('\n=== REVENUE SUMMARY ===');
  console.table(revResult);

  const [propSummary] = await conn.query(`
    SELECT
      COUNT(*) AS total_properties,
      SUM(CASE WHEN status = 'Tersedia' THEN 1 ELSE 0 END) AS available,
      SUM(CASE WHEN status LIKE '%Booking%' THEN 1 ELSE 0 END) AS booking,
      SUM(CASE WHEN status = 'Terjual' THEN 1 ELSE 0 END) AS sold
    FROM properties
  `);
  console.log('\n=== PROPERTY SUMMARY ===');
  console.table(propSummary);

  const [buyerCount] = await conn.query('SELECT COUNT(*) AS total_buyers FROM buyer_records');
  console.log('\n=== TOTAL BUYERS ===', buyerCount[0].total_buyers);

  await conn.end();
}

syncAllData().catch(console.error);

