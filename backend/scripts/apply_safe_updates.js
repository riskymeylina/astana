require('dotenv').config();
const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');

async function run() {
  const conn = await mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'puimey',
    multipleStatements: true,
  });

  console.log('Connected to MySQL puimey');

  // 1. Delete Kampus UTY if exists (dummy property)
  const [delRes] = await conn.query("DELETE FROM properties WHERE title LIKE '%Kampus%' OR title LIKE '%UTY%'");
  console.log('Deleted dummy properties (Kampus/UTY):', delRes.affectedRows);

  // 2. Find admin user id
  const [adminUser] = await conn.query("SELECT id_user FROM users WHERE role = 'admin' LIMIT 1");
  const adminId = adminUser[0]?.id_user || 1;

  // 3. Insert 2 verified social media buyers into buyer_records
  // Bapak Hendra Kusuma (Instagram PT Astana Karya Bandawasa)
  await conn.query(`
    INSERT INTO buyer_records (
      full_name, phone, email, address, notes,
      data_source, data_label, verification_status, recorded_by_user_id
    )
    SELECT 'Bapak Hendra Kusuma', '081234567890', 'hendra.kusuma@gmail.com',
           'Jl. Palagan Tentara Pelajar No. 12, Sleman, DIY',
           'Pembeli unit Prambanan Village Tipe 65 (Grand Limasan). Lunas via transfer BRI. Data resmi dari Instagram @astanakaryabandawasa.',
           'manual_admin', 'TERVERIFIKASI', 'verified', ?
    WHERE NOT EXISTS (SELECT 1 FROM buyer_records WHERE email = 'hendra.kusuma@gmail.com')
  `, [adminId]);

  // Ibu Ratna Dewi Susanti (Facebook PT Astana Karya Bandawasa)
  await conn.query(`
    INSERT INTO buyer_records (
      full_name, phone, email, address, notes,
      data_source, data_label, verification_status, recorded_by_user_id
    )
    SELECT 'Ibu Ratna Dewi Susanti', '085678901234', 'ratna.dewi@yahoo.com',
           'Jl. Godean Km 5, Gamping, Sleman, DIY',
           'Pembeli unit Bhumi Svarga Tipe Joglo Bata Klasik. Cicilan selesai 24 bulan lunas. Data resmi dari Facebook PT Astana Karya Bandawasa.',
           'manual_admin', 'TERVERIFIKASI', 'verified', ?
    WHERE NOT EXISTS (SELECT 1 FROM buyer_records WHERE email = 'ratna.dewi@yahoo.com')
  `, [adminId]);

  // Meylina (Registered App buyer)
  await conn.query(`
    INSERT INTO buyer_records (
      linked_user_id, full_name, phone, email, address, notes,
      data_source, data_label, verification_status, recorded_by_user_id
    )
    SELECT 3, 'Meylina', '085158277835', 'mey@gmail.com', 'Sleman, DIY',
           'Pembeli terdaftar dari aplikasi dengan transaksi terkonfirmasi.',
           'app_registration', 'TERVERIFIKASI', 'verified', ?
    WHERE NOT EXISTS (SELECT 1 FROM buyer_records WHERE email = 'mey@gmail.com')
  `, [adminId]);

  // 4. Insert real properties from seeders (Prambanan Village, Joglo Amerta, Bhumi Svarga)
  const seedFiles = [
    '0002_seed_prambanan_village.sql',
    '0003_seed_joglo_amerta.sql',
    '0004_seed_bhumi_svarga.sql'
  ];

  for (const file of seedFiles) {
    const filePath = path.join(__dirname, '..', 'seeders', file);
    if (fs.existsSync(filePath)) {
      const sql = fs.readFileSync(filePath, 'utf8');
      const lines = sql.split('\n');
      const titles = [];
      for (const line of lines) {
        const match = line.match(/VALUES\s*\('([^']+)',/i);
        if (match) titles.push(match[1]);
      }

      let needRun = false;
      for (const t of titles) {
        const [existing] = await conn.query('SELECT id_property FROM properties WHERE title = ?', [t]);
        if (existing.length === 0) {
          needRun = true;
          break;
        }
      }

      if (needRun) {
        console.log('Executing seeder:', file);
        await conn.query(sql);
      } else {
        console.log('Seeder already applied:', file);
      }
    }
  }

  // 5. Update buyer_record_id on property_purchases for Meylina
  const [meyRecord] = await conn.query("SELECT id_buyer_record FROM buyer_records WHERE email = 'mey@gmail.com'");
  if (meyRecord.length > 0) {
    await conn.query("UPDATE property_purchases SET buyer_record_id = ? WHERE buyer_name_snapshot LIKE '%Meylina%'", [meyRecord[0].id_buyer_record]);
  }

  // 6. Print summary
  const [buyers] = await conn.query('SELECT id_buyer_record, full_name, email, phone, data_source, verification_status FROM buyer_records');
  console.log('\n=== BUYER RECORDS IN DATABASE ===');
  console.table(buyers);

  const [props] = await conn.query('SELECT id_property, title, category, price, status FROM properties ORDER BY id_property');
  console.log('\n=== PROPERTIES IN DATABASE (' + props.length + ') ===');
  console.table(props);

  await conn.end();
  console.log('\nDone safely without deleting user data!');
}

run().catch(err => {
  console.error('Migration error:', err);
  process.exit(1);
});

async function addHistoricalSales() {
  const mysql = require('mysql2/promise');
  const conn = await mysql.createConnection({
    host: 'localhost', user: 'root', password: '', database: 'puimey'
  });
  const [adminUser] = await conn.query("SELECT id_user FROM users WHERE role = 'admin' LIMIT 1");
  const adminId = adminUser[0]?.id_user || 1;

  await conn.query(`
    INSERT INTO historical_sales (
      buyer_record_id, property_id, property_name_snapshot,
      transaction_date, transaction_value, payment_method, status, notes,
      data_label, recorded_by_user_id
    )
    SELECT 1, 20, 'Prambanan Village - Tipe 65 (Grand Limasan)',
           '2026-10-15', 495000000, 'Transfer BRI', 'completed',
           'Lunas penuh transfer bank. Data resmi sosmed Instagram PT Astana Karya Bandawasa.',
           'TERVERIFIKASI', ?
    WHERE NOT EXISTS (SELECT 1 FROM historical_sales WHERE buyer_record_id = 1)
  `, [adminId]);

  await conn.query(`
    INSERT INTO historical_sales (
      buyer_record_id, property_id, property_name_snapshot,
      transaction_date, transaction_value, payment_method, status, notes,
      data_label, recorded_by_user_id
    )
    SELECT 2, 24, 'Bhumi Svarga Prambanan - Tipe Joglo Bata Klasik',
           '2026-10-28', 495000000, 'Cicilan 24 Bulan', 'completed',
           'Cicilan lunas 24 bulan. Data resmi sosmed Facebook PT Astana Karya Bandawasa.',
           'TERVERIFIKASI', ?
    WHERE NOT EXISTS (SELECT 1 FROM historical_sales WHERE buyer_record_id = 2)
  `, [adminId]);

  const [sales] = await conn.query('SELECT id_historical_sale, buyer_record_id, property_name_snapshot, transaction_value, payment_method FROM historical_sales');
  console.log('\n=== HISTORICAL SALES ===');
  console.table(sales);

  await conn.end();
}
addHistoricalSales().catch(console.error);
