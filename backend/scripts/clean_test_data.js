require('dotenv').config();
const { createMigrationConnection } = require('../src/utils/migration');

(async () => {
  const db = await createMigrationConnection();
  
  // Check active orders on property 26
  const [orders] = await db.query(
    `SELECT id, status, payment_method, buyer_name, created_at FROM purchase_orders WHERE property_id = 26`
  );
  console.log('All orders on property 26:', orders);

  // Check property status
  const [p] = await db.query('SELECT id_property, title, status FROM properties WHERE id_property = 26');
  console.log('Property 26 current status:', p[0]);

  // Remove test orders that might be blocking
  const [del] = await db.query(`DELETE FROM purchase_orders WHERE buyer_name LIKE '%Test%' OR buyer_name LIKE '%test%'`);
  console.log('Deleted test orders:', del.affectedRows);

  // Reset property 26 status to Tersedia  
  await db.query(`UPDATE properties SET status = 'Tersedia' WHERE id_property = 26`);
  console.log('Reset property 26 -> Tersedia');

  await db.end();
})();
