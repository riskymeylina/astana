const pool = require('../config/db');

// ─── Helpers ─────────────────────────────────────────────────────────────────

const BUYER_RECORD_COLUMNS = `
  br.id_buyer_record  AS id,
  br.linked_user_id,
  br.full_name,
  br.phone,
  br.email,
  br.address,
  br.notes,
  br.data_source,
  br.data_label,
  br.verification_status,
  br.verified_by_user_id,
  br.verified_at,
  br.recorded_by_user_id,
  br.created_at,
  br.updated_at,
  u_linked.name      AS linked_user_name,
  u_linked.email     AS linked_user_email,
  u_linked.phone     AS linked_user_phone,
  u_recorder.name    AS recorded_by_name,
  u_verifier.name    AS verified_by_name
`;

const BUYER_RECORD_JOINS = `
  FROM buyer_records br
  LEFT JOIN users u_linked    ON u_linked.id_user = br.linked_user_id
  LEFT JOIN users u_recorder  ON u_recorder.id_user = br.recorded_by_user_id
  LEFT JOIN users u_verifier  ON u_verifier.id_user = br.verified_by_user_id
`;

// ─── BUYER RECORDS ────────────────────────────────────────────────────────────

async function findBuyerRecords({ search, dataSource, verificationStatus, page = 1, limit = 20 } = {}) {
  const conditions = [];
  const params = [];

  if (search && search.trim()) {
    const s = `%${search.trim()}%`;
    conditions.push('(br.full_name LIKE ? OR br.phone LIKE ? OR br.email LIKE ?)');
    params.push(s, s, s);
  }

  if (dataSource) {
    conditions.push('br.data_source = ?');
    params.push(dataSource);
  }

  if (verificationStatus) {
    conditions.push('br.verification_status = ?');
    params.push(verificationStatus);
  }

  const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
  const offset = (Number(page) - 1) * Number(limit);

  const [countRows] = await pool.execute(
    `SELECT COUNT(*) AS total ${BUYER_RECORD_JOINS} ${whereClause}`,
    params,
  );
  const total = Number(countRows[0].total);

  const [rows] = await pool.query(
    `SELECT ${BUYER_RECORD_COLUMNS} ${BUYER_RECORD_JOINS} ${whereClause}
     ORDER BY br.created_at DESC, br.id_buyer_record DESC
     LIMIT ? OFFSET ?`,
    [...params, parseInt(limit, 10), parseInt(offset, 10)],
  );

  return { rows, total };
}

async function findBuyerRecordById(id) {
  const [rows] = await pool.execute(
    `SELECT ${BUYER_RECORD_COLUMNS} ${BUYER_RECORD_JOINS}
     WHERE br.id_buyer_record = ? LIMIT 1`,
    [id],
  );
  return rows[0] || null;
}

async function findBuyerRecordByLinkedUserId(userId) {
  const [rows] = await pool.execute(
    `SELECT ${BUYER_RECORD_COLUMNS} ${BUYER_RECORD_JOINS}
     WHERE br.linked_user_id = ? LIMIT 1`,
    [userId],
  );
  return rows[0] || null;
}

async function createBuyerRecord({ full_name, phone, email, address, notes, data_source, data_label, linked_user_id, recorded_by_user_id }) {
  const [result] = await pool.execute(
    `INSERT INTO buyer_records
       (full_name, phone, email, address, notes, data_source, data_label, linked_user_id, recorded_by_user_id)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      full_name,
      phone || null,
      email ? email.toLowerCase().trim() : null,
      address || null,
      notes || null,
      data_source || 'manual_admin',
      data_label || null,
      linked_user_id || null,
      recorded_by_user_id,
    ],
  );
  return findBuyerRecordById(result.insertId);
}

async function updateBuyerRecord(id, { full_name, phone, email, address, notes, data_source, data_label, linked_user_id }) {
  await pool.execute(
    `UPDATE buyer_records
     SET full_name = ?, phone = ?, email = ?, address = ?, notes = ?,
         data_source = ?, data_label = ?, linked_user_id = ?,
         updated_at = CURRENT_TIMESTAMP
     WHERE id_buyer_record = ?`,
    [
      full_name,
      phone || null,
      email ? email.toLowerCase().trim() : null,
      address || null,
      notes || null,
      data_source || 'manual_admin',
      data_label || null,
      linked_user_id || null,
      id,
    ],
  );
  return findBuyerRecordById(id);
}

async function updateBuyerRecordVerification(id, { verification_status, verified_by_user_id }) {
  const now = verification_status === 'verified' ? new Date() : null;
  await pool.execute(
    `UPDATE buyer_records
     SET verification_status = ?, verified_by_user_id = ?, verified_at = ?,
         updated_at = CURRENT_TIMESTAMP
     WHERE id_buyer_record = ?`,
    [verification_status, verified_by_user_id || null, now, id],
  );
  return findBuyerRecordById(id);
}

async function deleteBuyerRecord(id) {
  const [result] = await pool.execute(
    'DELETE FROM buyer_records WHERE id_buyer_record = ?',
    [id],
  );
  return result.affectedRows > 0;
}

// ─── HISTORICAL SALES ────────────────────────────────────────────────────────

const HIST_SALE_COLUMNS = `
  hs.id_historical_sale,
  hs.buyer_record_id,
  hs.property_id,
  hs.property_name_snapshot,
  hs.transaction_date,
  hs.transaction_value,
  hs.payment_method,
  hs.status,
  hs.notes,
  hs.data_label,
  hs.recorded_by_user_id,
  hs.recorded_at,
  hs.updated_at,
  br.full_name          AS buyer_full_name,
  br.phone              AS buyer_phone,
  br.data_source        AS buyer_data_source,
  u_rec.name            AS recorded_by_name,
  p.title               AS property_title_current,
  p.location            AS property_location,
  p.status              AS property_status_current,
  (SELECT image_url FROM property_gallery_images
   WHERE property_id = p.id_property
   ORDER BY sort_order ASC, id_property_gallery_image ASC LIMIT 1) AS property_thumbnail_url
`;

const HIST_SALE_JOINS = `
  FROM historical_sales hs
  INNER JOIN buyer_records br ON br.id_buyer_record = hs.buyer_record_id
  LEFT JOIN users u_rec ON u_rec.id_user = hs.recorded_by_user_id
  LEFT JOIN properties p ON p.id_property = hs.property_id
`;

async function findHistoricalSales({ buyerRecordId, propertyId, status, from, to, page = 1, limit = 20 } = {}) {
  const conditions = [];
  const params = [];

  if (buyerRecordId) {
    conditions.push('hs.buyer_record_id = ?');
    params.push(buyerRecordId);
  }
  if (propertyId) {
    conditions.push('hs.property_id = ?');
    params.push(propertyId);
  }
  if (status) {
    conditions.push('hs.status = ?');
    params.push(status);
  }
  if (from) {
    conditions.push('hs.transaction_date >= ?');
    params.push(from);
  }
  if (to) {
    conditions.push('hs.transaction_date <= ?');
    params.push(to);
  }

  const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
  const offset = (Number(page) - 1) * Number(limit);

  const [countRows] = await pool.execute(
    `SELECT COUNT(*) AS total ${HIST_SALE_JOINS} ${whereClause}`,
    params,
  );
  const total = Number(countRows[0].total);

  const [rows] = await pool.query(
    `SELECT ${HIST_SALE_COLUMNS} ${HIST_SALE_JOINS} ${whereClause}
     ORDER BY hs.transaction_date DESC, hs.id_historical_sale DESC
     LIMIT ? OFFSET ?`,
    [...params, parseInt(limit, 10), parseInt(offset, 10)],
  );

  return { rows, total };
}

async function findHistoricalSaleById(id) {
  const [rows] = await pool.execute(
    `SELECT ${HIST_SALE_COLUMNS} ${HIST_SALE_JOINS}
     WHERE hs.id_historical_sale = ? LIMIT 1`,
    [id],
  );
  return rows[0] || null;
}

async function createHistoricalSale({
  buyer_record_id,
  property_id,
  property_name_snapshot,
  transaction_date,
  transaction_value,
  payment_method,
  status,
  notes,
  data_label,
  recorded_by_user_id,
}) {
  const resolvedPropertyId = property_id ? Number(property_id) : null;

  const [result] = await pool.execute(
    `INSERT INTO historical_sales
       (buyer_record_id, property_id, property_name_snapshot, transaction_date,
        transaction_value, payment_method, status, notes, data_label, recorded_by_user_id)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      buyer_record_id,
      resolvedPropertyId || null,
      property_name_snapshot,
      transaction_date || null,
      transaction_value ?? null,
      payment_method || null,
      status || 'completed',
      notes || null,
      data_label || null,
      recorded_by_user_id,
    ],
  );

  return findHistoricalSaleById(result.insertId);
}

async function updateHistoricalSale(id, {
  property_id,
  property_name_snapshot,
  transaction_date,
  transaction_value,
  payment_method,
  status,
  notes,
  data_label,
}) {
  const existing = await findHistoricalSaleById(id);

  const resolvedPropertyId = property_id ? Number(property_id) : (existing?.property_id ? Number(existing.property_id) : null);

  await pool.execute(
    `UPDATE historical_sales
     SET property_id = ?, property_name_snapshot = ?, transaction_date = ?,
         transaction_value = ?, payment_method = ?, status = ?, notes = ?,
         data_label = ?, updated_at = CURRENT_TIMESTAMP
     WHERE id_historical_sale = ?`,
    [
      resolvedPropertyId || null,
      property_name_snapshot,
      transaction_date || null,
      transaction_value ?? null,
      payment_method || null,
      status || 'completed',
      notes || null,
      data_label || null,
      id,
    ],
  );

  return findHistoricalSaleById(id);
}

async function deleteHistoricalSale(id) {
  const [result] = await pool.execute(
    'DELETE FROM historical_sales WHERE id_historical_sale = ?',
    [id],
  );
  return result.affectedRows > 0;
}

// Mendapatkan semua aktivitas seorang buyer_record: transaksi online + historis + survei
async function getBuyerRecordActivity(buyerRecordId) {
  const record = await findBuyerRecordById(buyerRecordId);
  if (!record) return null;

  const { rows: historicalSales } = await findHistoricalSales({ buyerRecordId });

  let onlinePurchases = [];
  let surveys = [];

  const [purchaseRows] = await pool.execute(
    `SELECT pp.id_purchase, pp.property_id, pp.status, pp.payment_method,
            pp.payment_amount, pp.buyer_name_snapshot, pp.created_at, pp.processed_at,
            p.title AS property_title, p.price AS property_price
     FROM property_purchases pp
     INNER JOIN properties p ON p.id_property = pp.property_id
     WHERE pp.buyer_record_id = ? OR (pp.buyer_user_id IS NOT NULL AND pp.buyer_user_id = ?)
     ORDER BY pp.created_at DESC`,
    [buyerRecordId, record.linked_user_id || 0],
  );
  onlinePurchases = purchaseRows;

  if (record.linked_user_id) {
    const [surveyRows] = await pool.execute(
      `SELECT sr.id_survey, sr.property_id, sr.status, sr.requested_date,
              sr.approved_schedule_date, sr.created_at,
              p.title AS property_title
       FROM survey_requests sr
       INNER JOIN properties p ON p.id_property = sr.property_id
       WHERE sr.buyer_user_id = ?
       ORDER BY sr.created_at DESC`,
      [record.linked_user_id],
    );
    surveys = surveyRows;
  }

  return { record, historicalSales, onlinePurchases, surveys };
}

module.exports = {
  findBuyerRecords,
  findBuyerRecordById,
  findBuyerRecordByLinkedUserId,
  createBuyerRecord,
  updateBuyerRecord,
  updateBuyerRecordVerification,
  deleteBuyerRecord,
  findHistoricalSales,
  findHistoricalSaleById,
  createHistoricalSale,
  updateHistoricalSale,
  deleteHistoricalSale,
  getBuyerRecordActivity,
};
