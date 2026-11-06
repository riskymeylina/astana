const pool = require('./src/config/db');

async function listUsers() {
  try {
    const [cols] = await pool.query('SHOW COLUMNS FROM users');
    console.log('\n--- Columns in users table ---');
    console.log(cols.map(c => `${c.Field} (${c.Type})`));

    const [rows] = await pool.query('SELECT * FROM users');
    console.log(`\n--- Total Users Found: ${rows.length} ---`);
    for (const r of rows) {
      console.log({
        id: r.id || r.id_user,
        email: r.email,
        name: r.name,
        role: r.role,
        hasPasswordHash: !!r.password_hash,
        hashPrefix: r.password_hash ? r.password_hash.substring(0, 10) + '...' : null
      });
    }
  } catch (err) {
    console.error('Error querying users:', err);
  } finally {
    process.exit(0);
  }
}

listUsers();

