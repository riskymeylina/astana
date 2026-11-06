const pool = require('../config/db');

const PAYMENT_DEADLINE_DAYS = 3;

let schemaEnsured = false;
async function ensureMidtransSchema() {
  if (schemaEnsured) return;
  try {
    const [cols] = await pool.query(`SHOW COLUMNS FROM property_purchases LIKE 'midtrans_order_id'`);
    if (cols.length === 0) {
      await pool.query(`
        ALTER TABLE property_purchases
          ADD COLUMN midtrans_order_id varchar(100) DEFAULT NULL,
          ADD COLUMN midtrans_transaction_id varchar(100) DEFAULT NULL,
          ADD COLUMN midtrans_qr_url text DEFAULT NULL,
          ADD COLUMN midtrans_payment_status varchar(50) DEFAULT NULL,
          ADD COLUMN midtrans_expiry_time datetime DEFAULT NULL,
          ADD KEY pp_midtrans_order_id_index (midtrans_order_id);
      `);
      console.log('[Migration] Midtrans columns added to property_purchases');
    }
    schemaEnsured = true;
  } catch (err) {
    console.warn('[Migration Warning] ensureMidtransSchema:', err.message);
  }
}

const SELECT_COLUMNS = `
  pp.id_purchase AS id,
  pp.buyer_user_id,
  pp.buyer_record_id,
  pp.property_id,
  pp.payment_method,
  pp.payment_account_number,
  pp.payment_account_name,
  pp.payment_amount,
  pp.payment_due_at,
  pp.cancelled_at,
  pp.buyer_name_snapshot,
  pp.buyer_phone_snapshot,
  pp.buyer_address_snapshot,
  pp.notes,
  pp.status,
  pp.payment_proof_path,
  pp.payment_proof_uploaded_at,
  pp.processed_by_user_id,
  pp.processed_by_name,
  pp.rejection_reason,
  pp.processed_at,
  pp.midtrans_order_id,
  pp.midtrans_transaction_id,
  pp.midtrans_qr_url,
  pp.midtrans_payment_status,
  pp.midtrans_expiry_time,
  pp.created_at,
  pp.updated_at,
  p.title    AS property_title,
  p.location AS property_location,
  (SELECT image_url FROM property_gallery_images WHERE property_id = p.id_property ORDER BY sort_order ASC, id_property_gallery_image ASC LIMIT 1) AS property_thumbnail_url,
  p.price    AS property_price
`;

const BASE_JOIN = `
  FROM property_purchases pp
  INNER JOIN properties p ON p.id_property = pp.property_id
`;

async function findPurchaseById(id) {
  const [rows] = await pool.execute(
    `SELECT ${SELECT_COLUMNS} ${BASE_JOIN} WHERE pp.id_purchase = ? LIMIT 1`,
    [id],
  );
  return rows[0] || null;
}

async function cancelOverduePendingPayments() {
  const [overdue] = await pool.execute(
    `SELECT DISTINCT property_id FROM property_purchases
     WHERE status = 'pending_payment'
       AND payment_due_at IS NOT NULL
       AND payment_due_at < NOW()`,
  );

  if (overdue.length > 0) {
    const ids = overdue.map((r) => r.property_id);
    for (const pid of ids) {
      await pool.execute(
        `UPDATE properties SET status = 'Tersedia', updated_at = CURRENT_TIMESTAMP WHERE id_property = ?`,
        [pid],
      );
    }
  }

  await pool.execute(
    `UPDATE property_purchases
     SET status = 'cancelled',
         cancelled_at = COALESCE(cancelled_at, NOW())
     WHERE status = 'pending_payment'
       AND payment_due_at IS NOT NULL
       AND payment_due_at < NOW()`,
  );
}

async function findPurchasesByBuyerId(buyerUserId) {
  const [rows] = await pool.execute(
    `SELECT ${SELECT_COLUMNS} ${BASE_JOIN}
     WHERE pp.buyer_user_id = ?
     ORDER BY FIELD(pp.status,
       'pending_payment',
       'payment_uploaded',
       'payment_review',
       'confirmed',
       'rejected',
       'cancelled'
     ), pp.created_at DESC`,
    [buyerUserId],
  );
  return rows;
}

function addDateFilters({ conditions, params, from, to, month, year }) {
  const dateExpression = 'DATE(COALESCE(pp.processed_at, pp.updated_at, pp.created_at))';

  if (from) {
    conditions.push(`${dateExpression} >= ?`);
    params.push(from);
  }

  if (to) {
    conditions.push(`${dateExpression} <= ?`);
    params.push(to);
  }

  if (month) {
    conditions.push('MONTH(COALESCE(pp.processed_at, pp.updated_at, pp.created_at)) = ?');
    params.push(month);
  }

  if (year) {
    conditions.push('YEAR(COALESCE(pp.processed_at, pp.updated_at, pp.created_at)) = ?');
    params.push(year);
  }
}

async function findAllPurchases({ status, search, from, to, month, year } = {}) {
  const params = [];
  const conditions = [];

  if (status) {
    conditions.push('pp.status = ?');
    params.push(status);
  }

  if (search && search.trim()) {
    const s = `%${search.trim()}%`;
    conditions.push('(pp.buyer_name_snapshot LIKE ? OR p.title LIKE ? OR p.location LIKE ? OR pp.midtrans_order_id LIKE ?)');
    params.push(s, s, s, s);
  }

  addDateFilters({ conditions, params, from, to, month, year });

  const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

  const [rows] = await pool.execute(
    `SELECT ${SELECT_COLUMNS} ${BASE_JOIN}
     ${whereClause}
     ORDER BY FIELD(pp.status,
       'pending_payment',
       'payment_uploaded',
       'payment_review',
       'confirmed',
       'rejected',
       'cancelled'
     ), pp.created_at DESC`,
    params,
  );
  return rows;
}

async function createPurchase({
  buyerUserId,
  propertyId,
  paymentMethod,
  buyerNameSnapshot,
  buyerPhoneSnapshot,
  buyerAddressSnapshot,
  notes,
  midtransOrderId,
  midtransTransactionId,
  midtransQrUrl,
  midtransPaymentStatus,
  midtransExpiryTime,
}) {
  await ensureMidtransSchema();

  const isQris = String(paymentMethod).toUpperCase().includes('QRIS');
  const accountNumber = isQris ? '-' : '-';
  const accountName = isQris ? 'Midtrans Payment Gateway' : 'Kasir Astana Karya';

  const [result] = await pool.execute(
    `INSERT INTO property_purchases (
       buyer_user_id, property_id, payment_method,
       payment_account_number, payment_account_name, payment_amount, payment_due_at,
       buyer_name_snapshot, buyer_phone_snapshot, buyer_address_snapshot,
       notes, status,
       midtrans_order_id, midtrans_transaction_id, midtrans_qr_url,
       midtrans_payment_status, midtrans_expiry_time
     )
     SELECT ?, ?, ?, ?, ?, p.price, DATE_ADD(NOW(), INTERVAL ? DAY), ?, ?, ?, ?, 'pending_payment',
            ?, ?, ?, ?, ?
     FROM properties p
     WHERE p.id_property = ?`,
    [
      buyerUserId,
      propertyId,
      paymentMethod,
      accountNumber,
      accountName,
      PAYMENT_DEADLINE_DAYS,
      buyerNameSnapshot,
      buyerPhoneSnapshot || null,
      buyerAddressSnapshot || null,
      notes || null,
      midtransOrderId || null,
      midtransTransactionId || null,
      midtransQrUrl || null,
      midtransPaymentStatus || (isQris ? 'pending' : null),
      midtransExpiryTime || null,
      propertyId,
    ],
  );

  await pool.execute(
    `UPDATE properties SET status = 'Sedang Dibooking', updated_at = CURRENT_TIMESTAMP WHERE id_property = ?`,
    [propertyId],
  );

  return findPurchaseById(result.insertId);
}

async function updateMidtransPayment({
  id,
  orderId,
  transactionId,
  qrUrl,
  paymentStatus,
  expiryTime,
}) {
  await ensureMidtransSchema();
  await pool.execute(
    `UPDATE property_purchases
     SET midtrans_order_id = COALESCE(?, midtrans_order_id),
         midtrans_transaction_id = COALESCE(?, midtrans_transaction_id),
         midtrans_qr_url = COALESCE(?, midtrans_qr_url),
         midtrans_payment_status = COALESCE(?, midtrans_payment_status),
         midtrans_expiry_time = COALESCE(?, midtrans_expiry_time)
     WHERE id_purchase = ?`,
    [orderId || null, transactionId || null, qrUrl || null, paymentStatus || null, expiryTime || null, id],
  );
  return findPurchaseById(id);
}

async function updateMidtransStatus({ id, paymentStatus, transactionId }) {
  await ensureMidtransSchema();
  await pool.execute(
    `UPDATE property_purchases
     SET midtrans_payment_status = ?,
         midtrans_transaction_id = COALESCE(?, midtrans_transaction_id)
     WHERE id_purchase = ?`,
    [paymentStatus, transactionId || null, id],
  );
  return findPurchaseById(id);
}

async function findPurchaseByMidtransOrderId(orderId) {
  await ensureMidtransSchema();
  const [rows] = await pool.execute(
    `SELECT ${SELECT_COLUMNS} ${BASE_JOIN} WHERE pp.midtrans_order_id = ? LIMIT 1`,
    [orderId],
  );
  return rows[0] || null;
}

async function confirmPurchaseByMidtrans({ id, transactionId }) {
  await pool.execute(
    `UPDATE property_purchases
     SET status = 'confirmed',
         midtrans_payment_status = 'settlement',
         midtrans_transaction_id = COALESCE(?, midtrans_transaction_id),
         processed_by_name = 'Midtrans Gateway',
         processed_at = NOW()
     WHERE id_purchase = ?`,
    [transactionId || null, id],
  );

  const purchase = await findPurchaseById(id);
  if (purchase) {
    await pool.execute(
      `UPDATE properties SET status = 'Terjual', updated_at = CURRENT_TIMESTAMP WHERE id_property = ?`,
      [purchase.property_id],
    );
  }

  return purchase;
}

async function setPaymentProof({ id, paymentProofPath }) {
  await pool.execute(
    `UPDATE property_purchases
     SET status = 'payment_uploaded',
         payment_proof_path = ?,
         payment_proof_uploaded_at = NOW(),
         rejection_reason = NULL,
         processed_at = NULL
     WHERE id_purchase = ? AND status IN ('pending_payment', 'rejected')`,
    [paymentProofPath, id],
  );

  const purchase = await findPurchaseById(id);
  if (purchase && purchase.status === 'payment_uploaded') {
    await pool.execute(
      `UPDATE properties SET status = 'Sedang Dibooking', updated_at = CURRENT_TIMESTAMP WHERE id_property = ?`,
      [purchase.property_id],
    );
  }
  return findPurchaseById(id);
}

async function updatePurchaseStatus({
  id,
  status,
  rejectionReason,
  processedByUserId,
  processedByName,
}) {
  await pool.execute(
    `UPDATE property_purchases
     SET status = ?,
         rejection_reason = ?,
         processed_by_user_id = ?,
         processed_by_name = ?,
         processed_at = NOW()
     WHERE id_purchase = ?`,
    [status, rejectionReason || null, processedByUserId, processedByName, id],
  );

  const purchase = await findPurchaseById(id);
  if (purchase) {
    let propertyStatus = 'Tersedia';
    if (status === 'confirmed') {
      propertyStatus = 'Terjual';
    } else if (status === 'pending_payment' || status === 'payment_uploaded' || status === 'payment_review') {
      propertyStatus = 'Sedang Dibooking';
    } else if (status === 'rejected' || status === 'cancelled') {
      propertyStatus = 'Tersedia';
    }

    await pool.execute(
      `UPDATE properties SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id_property = ?`,
      [propertyStatus, purchase.property_id],
    );
  }

  return purchase;
}

async function findPropertyForPurchase(propertyId) {
  const [rows] = await pool.execute(
    `SELECT id_property AS id, title, location, price, status FROM properties WHERE id_property = ? LIMIT 1`,
    [propertyId],
  );
  return rows[0] || null;
}

async function findBuyerProfile(userId) {
  const [rows] = await pool.execute(
    `SELECT u.name,
            ubp.whatsapp,
            ubp.recipient_name,
            ubp.address_line,
            ubp.district,
            ubp.city,
            ubp.province,
            ubp.postal_code
     FROM users u
     LEFT JOIN user_buyer_profiles ubp ON ubp.user_id = u.id_user
     WHERE u.id_user = ?
     LIMIT 1`,
    [userId],
  );
  return rows[0] || null;
}

module.exports = {
  findPurchaseById,
  cancelOverduePendingPayments,
  findPurchasesByBuyerId,
  findAllPurchases,
  createPurchase,
  updateMidtransPayment,
  updateMidtransStatus,
  findPurchaseByMidtransOrderId,
  confirmPurchaseByMidtrans,
  setPaymentProof,
  updatePurchaseStatus,
  findPropertyForPurchase,
  findBuyerProfile,
};
