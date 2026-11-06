const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, '../src/services/invoiceService.js');
let code = fs.readFileSync(filePath, 'utf8');

const oldGetBuyer = code.indexOf('async function getInvoicesByBuyerId');
const oldExport = code.indexOf('module.exports = {');

const replacement = [
  'async function getInvoicesByBuyerId(buyerId, { limit = 20, offset = 0 } = {}) {',
  '  try {',
  '    const safeLimit = Math.max(1, Math.min(100, parseInt(limit, 10) || 20));',
  '    const safeOffset = Math.max(0, parseInt(offset, 10) || 0);',
  '    const [rows] = await pool.query(',
  '      "SELECT id_invoice AS id, i.* FROM invoices i WHERE i.buyer_id = ? ORDER BY i.created_at DESC LIMIT " + safeLimit + " OFFSET " + safeOffset,',
  '      [buyerId]',
  '    );',
  '    return { invoices: rows, error: null };',
  '  } catch (err) {',
  '    console.error("[invoiceService] getInvoicesByBuyerId error:", err);',
  '    return { invoices: [], error: err };',
  '  }',
  '}',
  '',
  'async function getAllInvoices({ limit = 20, offset = 0 } = {}) {',
  '  try {',
  '    const safeLimit = Math.max(1, Math.min(100, parseInt(limit, 10) || 20));',
  '    const safeOffset = Math.max(0, parseInt(offset, 10) || 0);',
  '    const [rows] = await pool.query(',
  '      "SELECT id_invoice AS id, i.*, u.name as buyer_name FROM invoices i LEFT JOIN users u ON i.buyer_id = u.id_user ORDER BY i.created_at DESC LIMIT " + safeLimit + " OFFSET " + safeOffset',
  '    );',
  '    return { invoices: rows, error: null };',
  '  } catch (err) {',
  '    console.error("[invoiceService] getAllInvoices error:", err);',
  '    return { invoices: [], error: err };',
  '  }',
  '}',
  '',
].join('\n');

const newCode = code.slice(0, oldGetBuyer) + replacement + code.slice(oldExport);
fs.writeFileSync(filePath, newCode, 'utf8');
console.log('Successfully patched invoiceService.js');
