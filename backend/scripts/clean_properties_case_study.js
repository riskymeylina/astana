require('dotenv').config();
const mysql = require('mysql2/promise');

async function cleanProperties() {
  const conn = await mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'puimey',
  });

  console.log('Connected to puimey DB');

  // 1. Delete test purchases on dummy properties (Canva / Test User)
  await conn.query("DELETE FROM invoices WHERE purchase_id IN (1, 3)");
  await conn.query("DELETE FROM property_purchases WHERE id_purchase IN (1, 3)");
  console.log('Deleted dummy purchases (1 and 3)');

  // 2. Reassign Meylina (id_purchase: 2) to Prambanan Village Tipe 36 (id_property: 22)
  await conn.query(`
    UPDATE property_purchases
    SET property_id = 22, payment_amount = 295000000
    WHERE id_purchase = 2
  `);
  await conn.query(`
    UPDATE invoices
    SET property_id = 22,
        property_name = 'Prambanan Village - Tipe 36 (Limasan Minimalis)',
        property_price = 295000000
    WHERE purchase_id = 2
  `);
  console.log('Reassigned Meylina purchase to Prambanan Village Tipe 36');

  // 3. Delete gallery images of dummy properties
  const dummyIds = [8, 9, 10, 11, 12, 13, 14, 18];
  await conn.query("DELETE FROM property_gallery_images WHERE property_id IN (?)", [dummyIds]);
  console.log('Deleted gallery images of dummy properties');

  // Also delete from property_images if exists
  try {
    await conn.query("DELETE FROM property_images WHERE property_id IN (?)", [dummyIds]);
  } catch (_) {}

  // 4. Delete dummy properties from properties table
  await conn.query("DELETE FROM properties WHERE id_property IN (?)", [dummyIds]);
  console.log('Deleted dummy properties from properties table');

  // Also delete any other property not matching our 3 case studies
  await conn.query(`
    DELETE FROM properties
    WHERE category NOT IN ('Prambanan Village', 'Joglo Amerta', 'Bhumi Svarga')
  `);

  // 5. Update statuses of real properties
  // Terjual:
  // - 20: Prambanan Village Tipe 65 (Bpk Hendra Kusuma)
  // - 24: Bhumi Svarga Tipe Joglo Bata (Ibu Ratna Dewi)
  // - 22: Prambanan Village Tipe 36 (Meylina)
  // Tersedia: all others
  await conn.query("UPDATE properties SET status = 'Tersedia'");
  await conn.query("UPDATE properties SET status = 'Terjual' WHERE id_property IN (20, 22, 24)");

  // 6. Verification
  const [props] = await conn.query("SELECT id_property, title, category, price, status FROM properties ORDER BY id_property");
  console.log('\n=== REAL PROPERTIES IN DATABASE (' + props.length + ') ===');
  console.table(props);

  const [purchases] = await conn.query(`
    SELECT pp.id_purchase, pp.buyer_name_snapshot, p.title, pp.payment_amount, pp.status
    FROM property_purchases pp
    JOIN properties p ON p.id_property = pp.property_id
  `);
  console.log('\n=== PURCHASES (' + purchases.length + ') ===');
  console.table(purchases);

  const [globalStats] = await conn.query(`
    SELECT
      (SELECT COUNT(*) FROM properties) AS total_properties,
      (SELECT COUNT(*) FROM properties WHERE status = 'Tersedia') AS available,
      (SELECT COUNT(*) FROM properties WHERE status = 'Terjual') AS sold,
      (SELECT COUNT(*) FROM buyer_records) AS total_buyers,
      (SELECT COUNT(*) FROM property_purchases WHERE status = 'confirmed') AS confirmed_tx,
      (SELECT SUM(payment_amount) FROM property_purchases WHERE status = 'confirmed') AS total_revenue
  `);
  console.log('\n=== GLOBAL STATS ===');
  console.table(globalStats);

  await conn.end();
}

cleanProperties().catch(console.error);

