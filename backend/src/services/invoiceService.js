const pool = require('../config/db');

function generateInvoiceNumber() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const timestamp = Date.now().toString().slice(-6);
  return `INV-${year}${month}-${timestamp}`;
}

async function createInvoice({
  purchaseId,
  buyerId,
  propertyId,
  propertyName,
  propertyPrice,
  paymentMethod,
  paymentProofUrl,
}) {
  try {
    const [existingRows] = await pool.execute(
      `SELECT id_invoice, invoice_number
       FROM invoices
       WHERE purchase_id = ?
       LIMIT 1`,
      [purchaseId],
    );
    if (existingRows.length > 0) {
      return {
        success: true,
        invoiceId: existingRows[0].id_invoice,
        invoiceNumber: existingRows[0].invoice_number,
        error: null,
      };
    }

    const invoiceNumber = generateInvoiceNumber();
    const issuedAt = new Date();
    const dueDate = new Date(issuedAt.getTime() + 30 * 24 * 60 * 60 * 1000);

    const [result] = await pool.execute(
      `INSERT INTO invoices
       (invoice_number, purchase_id, buyer_id, property_id, property_name, property_price,
        payment_method, payment_proof_url, payment_status, issued_at, due_date)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        invoiceNumber,
        purchaseId,
        buyerId,
        propertyId,
        propertyName,
        propertyPrice,
        paymentMethod || null,
        paymentProofUrl || null,
        'pending',
        issuedAt,
        dueDate,
      ]
    );

    return {
      success: true,
      invoiceId: result.insertId,
      invoiceNumber,
      error: null,
    };
  } catch (err) {
    console.error('[invoiceService] createInvoice error:', err);
    return { success: false, error: err };
  }
}

async function getInvoiceByPurchaseId(purchaseId) {
  try {
    const [rows] = await pool.execute(
      `SELECT id_invoice AS id, i.* FROM invoices i WHERE i.purchase_id = ?`,
      [purchaseId]
    );
    return { invoice: rows[0] || null, error: null };
  } catch (err) {
    console.error('[invoiceService] getInvoiceByPurchaseId error:', err);
    return { invoice: null, error: err };
  }
}

async function getInvoiceById(invoiceId) {
  try {
    const [rows] = await pool.execute(
      `SELECT id_invoice AS id, i.* FROM invoices i WHERE i.id_invoice = ?`,
      [invoiceId]
    );
    return { invoice: rows[0] || null, error: null };
  } catch (err) {
    console.error('[invoiceService] getInvoiceById error:', err);
    return { invoice: null, error: err };
  }
}

async function getInvoiceByInvoiceNumber(invoiceNumber) {
  try {
    const [rows] = await pool.execute(
      `SELECT id_invoice AS id, i.* FROM invoices i WHERE i.invoice_number = ?`,
      [invoiceNumber]
    );
    return { invoice: rows[0] || null, error: null };
  } catch (err) {
    console.error('[invoiceService] getInvoiceByInvoiceNumber error:', err);
    return { invoice: null, error: err };
  }
}

async function updateInvoiceStatus(invoiceId, paymentStatus) {
  try {
    const [result] = await pool.execute(
      `UPDATE invoices SET payment_status = ?, updated_at = NOW() WHERE id_invoice = ?`,
      [paymentStatus, invoiceId]
    );
    return { success: result.affectedRows > 0, error: null };
  } catch (err) {
    console.error('[invoiceService] updateInvoiceStatus error:', err);
    return { success: false, error: err };
  }
}

async function getInvoicesByBuyerId(buyerId, { limit = 20, offset = 0 } = {}) {
  try {
    const safeLimit = Math.max(1, Math.min(100, parseInt(limit, 10) || 20));
    const safeOffset = Math.max(0, parseInt(offset, 10) || 0);
    const [rows] = await pool.query(
      "SELECT id_invoice AS id, i.* FROM invoices i WHERE i.buyer_id = ? ORDER BY i.created_at DESC LIMIT " + safeLimit + " OFFSET " + safeOffset,
      [buyerId]
    );
    return { invoices: rows, error: null };
  } catch (err) {
    console.error("[invoiceService] getInvoicesByBuyerId error:", err);
    return { invoices: [], error: err };
  }
}

async function getAllInvoices({ limit = 20, offset = 0 } = {}) {
  try {
    const safeLimit = Math.max(1, Math.min(100, parseInt(limit, 10) || 20));
    const safeOffset = Math.max(0, parseInt(offset, 10) || 0);
    const [rows] = await pool.query(
      "SELECT id_invoice AS id, i.*, u.name as buyer_name FROM invoices i LEFT JOIN users u ON i.buyer_id = u.id_user ORDER BY i.created_at DESC LIMIT " + safeLimit + " OFFSET " + safeOffset
    );
    return { invoices: rows, error: null };
  } catch (err) {
    console.error("[invoiceService] getAllInvoices error:", err);
    return { invoices: [], error: err };
  }
}
module.exports = {
  generateInvoiceNumber,
  createInvoice,
  getInvoiceById,
  getInvoiceByInvoiceNumber,
  getInvoiceByPurchaseId,
  updateInvoiceStatus,
  getInvoicesByBuyerId,
  getAllInvoices,
};
