const fs = require('fs');
require('dotenv').config();
const mysql = require('mysql2/promise');

async function runMigration() {
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'puimey',
    multipleStatements: true
  });
  
  const sql = fs.readFileSync('./migrations/0004_add_buyer_records.sql', 'utf8');
  await conn.query(sql);
  console.log('Migration 0004 applied successfully to database:', process.env.DB_NAME || 'puimey');
  
  const [tables] = await conn.query("SHOW TABLES LIKE 'buyer_records'");
  console.log('buyer_records table exists:', tables.length > 0);
  
  const [tables2] = await conn.query("SHOW TABLES LIKE 'historical_sales'");
  console.log('historical_sales table exists:', tables2.length > 0);
  
  await conn.end();
  process.exit(0);
}

runMigration().catch(err => {
  console.error('Migration error:', err.message);
  process.exit(1);
});
