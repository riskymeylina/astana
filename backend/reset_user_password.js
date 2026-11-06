const pool = require('./src/config/db');
const { hashPassword } = require('./src/utils/password');

async function resetPassword(email, newPlainPassword) {
  try {
    const hash = await hashPassword(newPlainPassword);
    const [cols] = await pool.query('SHOW COLUMNS FROM users');
    const hasIdUser = cols.some(c => c.Field === 'id_user');
    const idCol = hasIdUser ? 'id_user' : 'id';

    const [res] = await pool.execute(
      `UPDATE users SET password_hash = ? WHERE LOWER(TRIM(email)) = LOWER(TRIM(?))`,
      [hash, email]
    );

    if (res.affectedRows > 0) {
      console.log(`\n[SUCCESS] Password untuk user ${email} berhasil diupdate ke: "${newPlainPassword}"`);
    } else {
      console.log(`\n[NOT FOUND] User dengan email ${email} tidak ditemukan di database.`);
    }
  } catch (err) {
    console.error('Error updating password:', err);
  } finally {
    process.exit(0);
  }
}

const email = process.argv[2];
const pass = process.argv[3];

if (!email || !pass) {
  console.log('Usage: node reset_user_password.js <email> <password_baru>');
  process.exit(1);
}

resetPassword(email, pass);

