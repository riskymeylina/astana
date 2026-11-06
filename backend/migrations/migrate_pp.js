const pool = require('../src/config/db');

async function migrate() {
  try {
    const [cols] = await pool.query("SHOW COLUMNS FROM property_purchases LIKE 'buyer_record_id'");
    if (cols.length === 0) {
      await pool.query("ALTER TABLE property_purchases ADD COLUMN buyer_record_id bigint unsigned NULL AFTER buyer_user_id");
      console.log('Added buyer_record_id column');
    }

    await pool.query("ALTER TABLE property_purchases MODIFY buyer_user_id bigint unsigned NULL");
    console.log('Modified buyer_user_id to be NULLABLE');

    try {
      await pool.query("ALTER TABLE property_purchases ADD CONSTRAINT pp_buyer_record_id_foreign FOREIGN KEY (buyer_record_id) REFERENCES buyer_records (id_buyer_record) ON DELETE SET NULL");
      console.log('Added foreign key for buyer_record_id');
    } catch (e) {
      console.log('Foreign key note:', e.message);
    }

    console.log('property_purchases migration complete!');
    process.exit(0);
  } catch (err) {
    console.error('Migration error:', err);
    process.exit(1);
  }
}

migrate();
