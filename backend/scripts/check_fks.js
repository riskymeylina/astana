require('dotenv').config();
const mysql = require('mysql2/promise');

async function checkFks() {
  const conn = await mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'puimey',
  });

  const [fks] = await conn.query(`
    SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME
    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
    WHERE REFERENCED_TABLE_NAME = 'properties' AND TABLE_SCHEMA = 'puimey'
  `);
  console.log('--- TABLES REFERENCING PROPERTIES ---');
  console.table(fks);

  const [gallery] = await conn.query("SELECT property_id, COUNT(*) as cnt FROM property_gallery_images GROUP BY property_id");
  console.log('--- GALLERY PER PROPERTY ---');
  console.table(gallery);

  await conn.end();
}

checkFks().catch(console.error);

