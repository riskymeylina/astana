const pool = require('../config/db');

async function getTodos(userId, filterDate) {
  let query = `SELECT id_todo_list AS id, user_id, title, description, status, due_date, created_at, updated_at FROM todo_lists WHERE user_id = ?`;
  const params = [userId];

  if (filterDate) {
    if (filterDate === 'today') {
      query += ` AND DATE(created_at) = CURDATE()`;
    } else if (filterDate === 'yesterday') {
      query += ` AND DATE(created_at) = CURDATE() - INTERVAL 1 DAY`;
    } else if (filterDate === 'this_week') {
      query += ` AND YEARWEEK(created_at, 1) = YEARWEEK(CURDATE(), 1)`;
    } else if (filterDate === 'this_month') {
      query += ` AND MONTH(created_at) = MONTH(CURDATE()) AND YEAR(created_at) = YEAR(CURDATE())`;
    } else if (filterDate === 'this_year') {
      query += ` AND YEAR(created_at) = YEAR(CURDATE())`;
    }
  }

  query += ` ORDER BY created_at DESC`;

  const [rows] = await pool.query(query, params);
  return rows;
}

async function createTodo(userId, title, description, dueDate) {
  const [result] = await pool.query(
    `INSERT INTO todo_lists (user_id, title, description, due_date) VALUES (?, ?, ?, ?)`,
    [userId, title, description || null, dueDate || null]
  );
  return getTodoById(result.insertId);
}

async function getTodoById(id) {
  const [rows] = await pool.query(`SELECT id_todo_list AS id, user_id, title, description, status, due_date, created_at, updated_at FROM todo_lists WHERE id_todo_list = ?`, [id]);
  return rows[0] || null;
}

async function updateTodo(id, title, description, dueDate, status) {
  await pool.query(
    `UPDATE todo_lists SET title = ?, description = ?, due_date = ?, status = ? WHERE id_todo_list = ?`,
    [title, description || null, dueDate || null, status, id]
  );
  return getTodoById(id);
}

async function deleteTodo(id) {
  await pool.query(`DELETE FROM todo_lists WHERE id_todo_list = ?`, [id]);
}

module.exports = {
  getTodos,
  createTodo,
  getTodoById,
  updateTodo,
  deleteTodo,
};
