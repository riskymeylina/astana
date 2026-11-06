const pool = require('../config/db');
const purchaseService = require('./purchaseService');

function applyDateFilters({ conditions, params, from, to, month, year, alias = 'pp' }) {
  const dateExpression = `DATE(COALESCE(${alias}.processed_at, ${alias}.updated_at, ${alias}.created_at))`;

  if (from) {
    conditions.push(`${dateExpression} >= ?`);
    params.push(from);
  }

  if (to) {
    conditions.push(`${dateExpression} <= ?`);
    params.push(to);
  }

  if (month) {
    conditions.push(`MONTH(COALESCE(${alias}.processed_at, ${alias}.updated_at, ${alias}.created_at)) = ?`);
    params.push(month);
  }

  if (year) {
    conditions.push(`YEAR(COALESCE(${alias}.processed_at, ${alias}.updated_at, ${alias}.created_at)) = ?`);
    params.push(year);
  }
}

function buildDateConditions({ status, from, to, month, year } = {}) {
  const conditions = [];
  const params = [];
  if (status) {
    conditions.push('pp.status = ?');
    params.push(status);
  }
  applyDateFilters({ conditions, params, from, to, month, year });

  return { conditions, params };
}

function normalizeText(value) {
  return String(value || '')
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .trim()
    .replace(/\s+/g, ' ');
}

function normalizePhone(value) {
  return String(value || '').replace(/\D/g, '');
}

function hasValue(value) {
  return value !== null && value !== undefined && String(value).trim() !== '';
}

function getBuyerIdentity(row) {
  return {
    ids: [
      ...(hasValue(row.buyer_record_id) ? [`record:${row.buyer_record_id}`] : []),
      ...(hasValue(row.buyer_linked_user_id) ? [`user:${row.buyer_linked_user_id}`] : []),
      ...(hasValue(row.buyer_user_id) ? [`user:${row.buyer_user_id}`] : []),
    ],
    phone: normalizePhone(row.buyer_phone_snapshot || row.buyer_phone),
    name: normalizeText(row.buyer_name_snapshot || row.buyer_full_name),
  };
}

function sameBuyer(left, right) {
  const leftIdentity = getBuyerIdentity(left);
  const rightIdentity = getBuyerIdentity(right);
  if (leftIdentity.ids.length > 0 && rightIdentity.ids.length > 0) {
    return leftIdentity.ids.some((id) => rightIdentity.ids.includes(id));
  }
  if (leftIdentity.phone && rightIdentity.phone) {
    return leftIdentity.phone === rightIdentity.phone;
  }
  return Boolean(leftIdentity.name && leftIdentity.name === rightIdentity.name);
}

function getPropertyIdentity(row) {
  return {
    id: hasValue(row.property_id) ? String(row.property_id) : null,
    title: normalizeText(row.property_title || row.property_name_snapshot || row.property_title_current),
  };
}

function sameProperty(left, right) {
  const leftIdentity = getPropertyIdentity(left);
  const rightIdentity = getPropertyIdentity(right);
  if (leftIdentity.id && rightIdentity.id) return leftIdentity.id === rightIdentity.id;
  return Boolean(leftIdentity.title && leftIdentity.title === rightIdentity.title);
}

function getTransactionStatusRank(row) {
  if (row.status === 'confirmed' || row.status === 'completed') return 2;
  if (['pending_payment', 'payment_uploaded', 'payment_review', 'pending'].includes(row.status)) return 1;
  return 0;
}

function getTransactionTimestamp(row, source) {
  const value = source === 'online'
    ? row.processed_at || row.updated_at || row.created_at
    : row.transaction_date || row.updated_at || row.recorded_at;
  const timestamp = Date.parse(value || '');
  return Number.isFinite(timestamp) ? timestamp : 0;
}

function getCanonicalTransactions(onlineRows, historicalRows) {
  const canonicalRows = [];

  for (const [source, rows] of [
    ['online', onlineRows],
    ['historical', historicalRows],
  ]) {
    for (const row of rows) {
      const candidate = { ...row, source };
      const duplicateIndex = canonicalRows.findIndex(
        (existing) => sameBuyer(existing, candidate) && sameProperty(existing, candidate),
      );
      if (duplicateIndex === -1) {
        canonicalRows.push(candidate);
        continue;
      }

      const existing = canonicalRows[duplicateIndex];
      const rankDifference = getTransactionStatusRank(candidate) - getTransactionStatusRank(existing);
      const bothCompleted = getTransactionStatusRank(candidate) === 2
        && getTransactionStatusRank(existing) === 2;
      const replaceForSourcePriority = bothCompleted
        && candidate.source === 'online'
        && existing.source === 'historical';
      const replaceForRecency = candidate.source !== existing.source
        && getTransactionTimestamp(candidate, candidate.source)
          > getTransactionTimestamp(existing, existing.source);

      if (rankDifference > 0 || replaceForSourcePriority || (rankDifference === 0 && replaceForRecency)) {
        canonicalRows[duplicateIndex] = candidate;
      }
    }
  }

  return canonicalRows;
}

function countUniqueBuyers(rows) {
  const buyers = [];
  for (const row of rows) {
    if (!buyers.some((buyer) => sameBuyer(buyer, row))) buyers.push(row);
  }
  return buyers.length;
}

function getCompletedTransactions(rows) {
  return rows.filter((row) => row.status === 'confirmed' || row.status === 'completed');
}

function getOnlineRevenue(row) {
  return Number(row.payment_amount) || Number(row.property_price) || 0;
}

function sumConfirmedRevenue(rows) {
  return rows.reduce((total, row) => {
    const amount = row.source === 'historical' ? row.transaction_value : getOnlineRevenue(row);
    const numericAmount = Number(amount);
    return total + (Number.isFinite(numericAmount) ? numericAmount : 0);
  }, 0);
}

async function getSalesReport({ status, from, to, month, year } = {}) {
  const { conditions, params } = buildDateConditions({ status, from, to, month, year });
  const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

  const [rows] = await pool.execute(
    `SELECT pp.id_purchase AS id,
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
            pp.created_at,
            pp.updated_at,
            p.title AS property_title,
            br.linked_user_id AS buyer_linked_user_id,
            br.full_name AS buyer_full_name,
            br.phone AS buyer_phone,
            p.location AS property_location,
            (SELECT image_url FROM property_gallery_images WHERE property_id = p.id_property ORDER BY sort_order ASC, id_property_gallery_image ASC LIMIT 1) AS property_thumbnail_url,
            p.price AS property_price
     FROM property_purchases pp
     INNER JOIN properties p ON p.id_property = pp.property_id
     LEFT JOIN buyer_records br
       ON br.id_buyer_record = pp.buyer_record_id
       OR (pp.buyer_record_id IS NULL AND br.linked_user_id = pp.buyer_user_id)
     ${whereClause}
     ORDER BY COALESCE(pp.processed_at, pp.updated_at, pp.created_at) DESC`,
    params,
  );

  const totalRevenue = rows
    .filter((row) => row.status === 'confirmed')
    .reduce((total, row) => total + getOnlineRevenue(row), 0);
  return { rows, totalRevenue };
}

async function getAvailabilityReport({ from, to, month, year } = {}) {
  const propertyConditions = [];
  const propertyParams = [];

  if (from) {
    propertyConditions.push('DATE(updated_at) >= ?');
    propertyParams.push(from);
  }

  if (to) {
    propertyConditions.push('DATE(updated_at) <= ?');
    propertyParams.push(to);
  }

  if (month) {
    propertyConditions.push('MONTH(updated_at) = ?');
    propertyParams.push(month);
  }

  if (year) {
    propertyConditions.push('YEAR(updated_at) = ?');
    propertyParams.push(year);
  }

  const whereClause = propertyConditions.length > 0 ? `WHERE ${propertyConditions.join(' AND ')}` : '';

  const [summaryRows] = await pool.execute(
    `SELECT status, COUNT(*) AS total
     FROM properties
     ${whereClause}
     GROUP BY status
     ORDER BY status ASC`,
    propertyParams,
  );

  const [properties] = await pool.execute(
    `SELECT id_property AS id, title, category, location, price, status, updated_at
     FROM properties
     ${whereClause}
     ORDER BY status ASC, title ASC`,
    propertyParams,
  );

  return { summaryRows, properties };
}

async function getGlobalReport({ from, to, month, year } = {}) {
  const [summaryRows] = await pool.execute(
    `SELECT
       (SELECT COUNT(*) FROM properties) AS total_properties,
       (SELECT COUNT(*) FROM properties WHERE status IN ('Tersedia', 'available')) AS available_properties,
       (SELECT COUNT(*) FROM properties WHERE status IN ('Sedang Dibooking', 'booking')) AS booking_properties,
       (SELECT COUNT(*) FROM properties WHERE status IN ('Terjual', 'sold')) AS sold_properties,
       (SELECT COUNT(*) FROM buyer_records) AS total_buyers,
       (SELECT COUNT(*) FROM users WHERE role = 'staf') AS total_staff`,
    [],
  );

  const [onlineRows, historicalRows] = await Promise.all([
    getSalesReport({ from, to, month, year }),
    getHistoricalSalesReport({ from, to, month, year }),
  ]);
  const canonicalRows = getCanonicalTransactions(onlineRows.rows, historicalRows);
  const transactionCount = canonicalRows.length;
  const confirmedTransactions = canonicalRows.filter((row) => row.source === 'online').length;
  const completedHistoricalTransactions = canonicalRows.filter((row) => row.source === 'historical').length;
  const completedTransactions = getCompletedTransactions(canonicalRows);
  const confirmedRevenue = sumConfirmedRevenue(
    completedTransactions.filter((row) => row.source === 'online'),
  );
  const completedHistoricalRevenue = sumConfirmedRevenue(
    completedTransactions.filter((row) => row.source === 'historical'),
  );

  return {
    ...summaryRows[0],
    total_transactions: transactionCount,
    confirmed_transactions: canonicalRows.filter(
      (row) => row.source === 'online' && row.status === 'confirmed',
    ).length,
    completed_historical_transactions: canonicalRows.filter(
      (row) => row.source === 'historical' && row.status === 'completed',
    ).length,
    online_transactions: confirmedTransactions,
    historical_transactions: completedHistoricalTransactions,
    sold_units: completedTransactions.length,
    unique_transacting_buyers: countUniqueBuyers(canonicalRows),
    total_revenue: confirmedRevenue + completedHistoricalRevenue,
    confirmed_revenue: confirmedRevenue,
    completed_historical_revenue: completedHistoricalRevenue,
  };
}

async function getTransactions({ status, from, to, month, year } = {}) {
  return purchaseService.findAllPurchases({ status, from, to, month, year });
}

async function getHistoricalSalesReport({ status, from, to, month, year } = {}) {
  const conditions = [];
  const params = [];

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
  if (month) {
    conditions.push('MONTH(hs.transaction_date) = ?');
    params.push(month);
  }
  if (year) {
    conditions.push('YEAR(hs.transaction_date) = ?');
    params.push(year);
  }

  const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
  const [rows] = await pool.execute(
    `SELECT hs.id_historical_sale,
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
            br.full_name AS buyer_full_name,
            br.phone AS buyer_phone,
            br.linked_user_id AS buyer_linked_user_id,
            br.data_source AS buyer_data_source,
            u_rec.name AS recorded_by_name,
            p.title AS property_title_current,
            p.location AS property_location,
            p.status AS property_status_current,
            (SELECT image_url
             FROM property_gallery_images
             WHERE property_id = p.id_property
             ORDER BY sort_order ASC, id_property_gallery_image ASC
             LIMIT 1) AS property_thumbnail_url
     FROM historical_sales hs
     INNER JOIN buyer_records br ON br.id_buyer_record = hs.buyer_record_id
     LEFT JOIN users u_rec ON u_rec.id_user = hs.recorded_by_user_id
     LEFT JOIN properties p ON p.id_property = hs.property_id
     ${whereClause}
     ORDER BY hs.transaction_date DESC, hs.id_historical_sale DESC`,
    params,
  );
  return rows;
}

module.exports = {
  getSalesReport,
  getAvailabilityReport,
  getGlobalReport,
  getTransactions,
  getHistoricalSalesReport,
};
