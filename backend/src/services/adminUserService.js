const pool = require('../config/db');

let _hasIdUser = null;
let _hasIsActive = null;

async function checkSchema() {
  if (_hasIdUser !== null && _hasIsActive !== null) {
    return { hasIdUser: _hasIdUser, hasIsActive: _hasIsActive };
  }
  try {
    const [cols] = await pool.query('SHOW COLUMNS FROM users');
    const fields = cols.map((c) => c.Field);
    _hasIdUser = fields.includes('id_user');
    _hasIsActive = fields.includes('is_active');
  } catch (e) {
    _hasIdUser = false;
    _hasIsActive = false;
  }
  return { hasIdUser: _hasIdUser, hasIsActive: _hasIsActive };
}

async function findUsers({ role } = {}) {
  const { hasIdUser, hasIsActive } = await checkSchema();
  const idCol = hasIdUser ? 'id_user' : 'id';
  const isActiveCol = hasIsActive ? 'is_active' : '1 AS is_active';

  const params = [];
  const conditions = [];

  if (role) {
    conditions.push('role = ?');
    params.push(role);
  }

  const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
  const [rows] = await pool.execute(
    `SELECT ${idCol} AS id, name, email, phone, role, ${isActiveCol}, profile_photo_path, created_at, updated_at
     FROM users
     ${whereClause}
     ORDER BY created_at DESC, ${idCol} DESC`,
    params,
  );

  return rows;
}

async function findUserById(id) {
  const { hasIdUser, hasIsActive } = await checkSchema();
  const idCol = hasIdUser ? 'id_user' : 'id';
  const isActiveCol = hasIsActive ? 'is_active' : '1 AS is_active';

  const [rows] = await pool.execute(
    `SELECT ${idCol} AS id, name, email, phone, role, ${isActiveCol}, profile_photo_path, created_at, updated_at
     FROM users
     WHERE ${idCol} = ?
     LIMIT 1`,
    [id],
  );
  return rows[0] || null;
}

async function createStaff({ name, email, phone, password }) {
  const { hasIsActive } = await checkSchema();
  const { hashPassword } = require('../utils/password');
  const passwordHash = await hashPassword(password);

  const [result] = hasIsActive
    ? await pool.execute(
        `INSERT INTO users (name, email, phone, password_hash, role, is_active)
         VALUES (?, ?, ?, ?, 'staf', 1)`,
        [name, email, phone, passwordHash],
      )
    : await pool.execute(
        `INSERT INTO users (name, email, phone, password_hash, role)
         VALUES (?, ?, ?, ?, 'staf')`,
        [name, email, phone, passwordHash],
      );

  return findUserById(result.insertId);
}

async function updateUser(id, { name, email, phone, isActive }) {
  const { hasIdUser, hasIsActive } = await checkSchema();
  const idCol = hasIdUser ? 'id_user' : 'id';

  if (hasIsActive) {
    await pool.execute(
      `UPDATE users
       SET name = ?, email = ?, phone = ?, is_active = ?, updated_at = CURRENT_TIMESTAMP
       WHERE ${idCol} = ?`,
      [name, email, phone, isActive ? 1 : 0, id],
    );
  } else {
    await pool.execute(
      `UPDATE users
       SET name = ?, email = ?, phone = ?, updated_at = CURRENT_TIMESTAMP
       WHERE ${idCol} = ?`,
      [name, email, phone, id],
    );
  }
  return findUserById(id);
}

async function updateUserRole(id, role) {
  const { hasIdUser } = await checkSchema();
  const idCol = hasIdUser ? 'id_user' : 'id';

  await pool.execute(
    `UPDATE users
     SET role = ?, updated_at = CURRENT_TIMESTAMP
     WHERE ${idCol} = ?`,
    [role, id],
  );
  return findUserById(id);
}

async function deleteUser(id) {
  const { hasIdUser } = await checkSchema();
  const idCol = hasIdUser ? 'id_user' : 'id';

  const [result] = await pool.execute(`DELETE FROM users WHERE ${idCol} = ?`, [id]);
  return result.affectedRows > 0;
}

module.exports = {
  findUsers,
  findUserById,
  createStaff,
  updateUser,
  updateUserRole,
  deleteUser,
};
