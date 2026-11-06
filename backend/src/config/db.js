const mysql = require('mysql2/promise');

function getDatabaseName() {
  return process.env.DB_NAME || 'puimey';
}

function getDbConfig({ includeDatabase = true, multipleStatements = false } = {}) {
  return {
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    ...(includeDatabase ? { database: getDatabaseName() } : {}),
    ...(multipleStatements ? { multipleStatements: true } : {}),
  };
}

const pool = mysql.createPool({
  ...getDbConfig(),
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

module.exports = pool;
module.exports.getDbConfig = getDbConfig;
module.exports.getDatabaseName = getDatabaseName;
