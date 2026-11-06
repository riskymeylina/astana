const buyerRecordService = require('../services/buyerRecordService');
const authService = require('../services/authService');

function createError(message, statusCode) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

function validateId(value, label = 'ID') {
  const id = Number.parseInt(String(value || ''), 10);
  if (!Number.isInteger(id) || id <= 0) throw createError(`${label} tidak valid`, 400);
  return id;
}

function buildBuyerRecordPayload(r) {
  return {
    id: r.id,
    linkedUserId: r.linked_user_id,
    fullName: r.full_name,
    phone: r.phone,
    email: r.email,
    address: r.address,
    notes: r.notes,
    dataSource: r.data_source,
    dataLabel: r.data_label,
    verificationStatus: r.verification_status,
    verifiedByUserId: r.verified_by_user_id,
    verifiedAt: r.verified_at,
    recordedByUserId: r.recorded_by_user_id,
    createdAt: r.created_at,
    updatedAt: r.updated_at,
    // Joined fields
    linkedUserName: r.linked_user_name,
    linkedUserEmail: r.linked_user_email,
    linkedUserPhone: r.linked_user_phone,
    recordedByName: r.recorded_by_name,
    verifiedByName: r.verified_by_name,
  };
}

function buildHistoricalSalePayload(s) {
  return {
    id: s.id_historical_sale,
    buyerRecordId: s.buyer_record_id,
    propertyId: s.property_id,
    propertyNameSnapshot: s.property_name_snapshot,
    transactionDate: s.transaction_date,
    transactionValue: s.transaction_value,
    paymentMethod: s.payment_method,
    status: s.status,
    notes: s.notes,
    dataLabel: s.data_label,
    recordedByUserId: s.recorded_by_user_id,
    recordedAt: s.recorded_at,
    updatedAt: s.updated_at,
    // Joined fields
    buyerFullName: s.buyer_full_name,
    buyerPhone: s.buyer_phone,
    buyerDataSource: s.buyer_data_source,
    recordedByName: s.recorded_by_name,
    propertyTitleCurrent: s.property_title_current,
    propertyLocation: s.property_location,
    propertyStatusCurrent: s.property_status_current,
    propertyThumbnailUrl: s.property_thumbnail_url,
  };
}

// ─── Buyer Records ────────────────────────────────────────────────────────────

async function listBuyerRecords(req, res, next) {
  try {
    const { search, dataSource, verificationStatus, page = 1, limit = 20 } = req.query;
    const { rows, total } = await buyerRecordService.findBuyerRecords({
      search,
      dataSource,
      verificationStatus,
      page: Number(page),
      limit: Math.min(Number(limit), 100),
    });
    return res.status(200).json({
      message: 'Data pembeli berhasil diambil',
      buyerRecords: rows.map(buildBuyerRecordPayload),
      total,
      page: Number(page),
      limit: Number(limit),
    });
  } catch (error) {
    return next(error);
  }
}

async function getBuyerRecord(req, res, next) {
  try {
    const id = validateId(req.params.id);
    const record = await buyerRecordService.findBuyerRecordById(id);
    if (!record) throw createError('Data pembeli tidak ditemukan', 404);
    return res.status(200).json({
      message: 'Data pembeli ditemukan',
      buyerRecord: buildBuyerRecordPayload(record),
    });
  } catch (error) {
    return next(error);
  }
}

async function getBuyerRecordActivity(req, res, next) {
  try {
    const id = validateId(req.params.id);
    const activity = await buyerRecordService.getBuyerRecordActivity(id);
    if (!activity) throw createError('Data pembeli tidak ditemukan', 404);
    return res.status(200).json({
      message: 'Aktivitas pembeli berhasil diambil',
      buyerRecord: buildBuyerRecordPayload(activity.record),
      historicalSales: activity.historicalSales.map(buildHistoricalSalePayload),
      onlinePurchases: activity.onlinePurchases,
      surveys: activity.surveys,
    });
  } catch (error) {
    return next(error);
  }
}

async function createBuyerRecord(req, res, next) {
  try {
    const { fullName, phone, email, address, notes, dataSource, dataLabel, linkedUserId } = req.body;

    if (!fullName?.trim()) throw createError('Nama lengkap wajib diisi', 400);

    const validSources = ['manual_admin', 'historical_company', 'app_registration'];
    const resolvedSource = validSources.includes(dataSource) ? dataSource : 'manual_admin';

    // Cek duplikat linked user
    if (linkedUserId) {
      const existingLink = await buyerRecordService.findBuyerRecordByLinkedUserId(linkedUserId);
      if (existingLink) throw createError('Akun pembeli ini sudah terhubung ke data pembeli lain', 409);
      // Verifikasi user exists dan berperan sebagai pembeli
      const user = await authService.findUserById(linkedUserId);
      if (!user) throw createError('Akun pengguna yang ditautkan tidak ditemukan', 404);
      if (user.role !== 'pembeli') throw createError('Hanya akun dengan peran pembeli yang dapat ditautkan', 400);
    }

    const record = await buyerRecordService.createBuyerRecord({
      full_name: fullName.trim(),
      phone: phone?.trim() || null,
      email: email?.trim() || null,
      address: address?.trim() || null,
      notes: notes?.trim() || null,
      data_source: resolvedSource,
      data_label: dataLabel?.trim() || null,
      linked_user_id: linkedUserId || null,
      recorded_by_user_id: req.user.id,
    });

    return res.status(201).json({
      message: 'Data pembeli berhasil ditambahkan',
      buyerRecord: buildBuyerRecordPayload(record),
    });
  } catch (error) {
    return next(error);
  }
}

async function updateBuyerRecord(req, res, next) {
  try {
    const id = validateId(req.params.id);
    const { fullName, phone, email, address, notes, dataSource, dataLabel, linkedUserId } = req.body;

    if (!fullName?.trim()) throw createError('Nama lengkap wajib diisi', 400);

    const existing = await buyerRecordService.findBuyerRecordById(id);
    if (!existing) throw createError('Data pembeli tidak ditemukan', 404);

    const validSources = ['manual_admin', 'historical_company', 'app_registration'];
    const resolvedSource = validSources.includes(dataSource) ? dataSource : 'manual_admin';

    // Cek duplikat linked user (selain record ini sendiri)
    if (linkedUserId && Number(linkedUserId) !== Number(existing.linked_user_id)) {
      const existingLink = await buyerRecordService.findBuyerRecordByLinkedUserId(linkedUserId);
      if (existingLink && existingLink.id !== id) {
        throw createError('Akun pembeli ini sudah terhubung ke data pembeli lain', 409);
      }
      const user = await authService.findUserById(linkedUserId);
      if (!user) throw createError('Akun pengguna yang ditautkan tidak ditemukan', 404);
      if (user.role !== 'pembeli') throw createError('Hanya akun dengan peran pembeli yang dapat ditautkan', 400);
    }

    const updated = await buyerRecordService.updateBuyerRecord(id, {
      full_name: fullName.trim(),
      phone: phone?.trim() || null,
      email: email?.trim() || null,
      address: address?.trim() || null,
      notes: notes?.trim() || null,
      data_source: resolvedSource,
      data_label: dataLabel?.trim() || null,
      linked_user_id: linkedUserId || null,
    });

    return res.status(200).json({
      message: 'Data pembeli berhasil diperbarui',
      buyerRecord: buildBuyerRecordPayload(updated),
    });
  } catch (error) {
    return next(error);
  }
}

async function verifyBuyerRecord(req, res, next) {
  try {
    const id = validateId(req.params.id);
    const { verificationStatus } = req.body;
    const validStatuses = ['unverified', 'pending_verification', 'verified'];
    if (!validStatuses.includes(verificationStatus)) {
      throw createError('Status verifikasi tidak valid', 400);
    }
    const existing = await buyerRecordService.findBuyerRecordById(id);
    if (!existing) throw createError('Data pembeli tidak ditemukan', 404);

    const updated = await buyerRecordService.updateBuyerRecordVerification(id, {
      verification_status: verificationStatus,
      verified_by_user_id: req.user.id,
    });

    return res.status(200).json({
      message: 'Status verifikasi berhasil diperbarui',
      buyerRecord: buildBuyerRecordPayload(updated),
    });
  } catch (error) {
    return next(error);
  }
}

async function deleteBuyerRecord(req, res, next) {
  try {
    const id = validateId(req.params.id);
    const existing = await buyerRecordService.findBuyerRecordById(id);
    if (!existing) throw createError('Data pembeli tidak ditemukan', 404);
    await buyerRecordService.deleteBuyerRecord(id);
    return res.status(200).json({ message: 'Data pembeli berhasil dihapus' });
  } catch (error) {
    return next(error);
  }
}

// ─── Historical Sales ─────────────────────────────────────────────────────────

async function listHistoricalSales(req, res, next) {
  try {
    const { buyerRecordId, propertyId, status, from, to, page = 1, limit = 20 } = req.query;
    const { rows, total } = await buyerRecordService.findHistoricalSales({
      buyerRecordId: buyerRecordId ? Number(buyerRecordId) : undefined,
      propertyId: propertyId ? Number(propertyId) : undefined,
      status,
      from,
      to,
      page: Number(page),
      limit: Math.min(Number(limit), 100),
    });
    return res.status(200).json({
      message: 'Data penjualan historis berhasil diambil',
      historicalSales: rows.map(buildHistoricalSalePayload),
      total,
    });
  } catch (error) {
    return next(error);
  }
}

async function getHistoricalSale(req, res, next) {
  try {
    const id = validateId(req.params.id);
    const sale = await buyerRecordService.findHistoricalSaleById(id);
    if (!sale) throw createError('Data penjualan historis tidak ditemukan', 404);
    return res.status(200).json({
      message: 'Data penjualan historis ditemukan',
      historicalSale: buildHistoricalSalePayload(sale),
    });
  } catch (error) {
    return next(error);
  }
}

async function createHistoricalSale(req, res, next) {
  try {
    const { buyerRecordId, propertyId, propertyNameSnapshot, transactionDate, transactionValue, paymentMethod, status, notes, dataLabel } = req.body;

    if (!buyerRecordId) throw createError('ID data pembeli wajib diisi', 400);
    if (!propertyNameSnapshot?.trim()) throw createError('Nama properti wajib diisi', 400);

    // Verifikasi buyer record exists
    const buyerRecord = await buyerRecordService.findBuyerRecordById(Number(buyerRecordId));
    if (!buyerRecord) throw createError('Data pembeli tidak ditemukan', 404);

    const sale = await buyerRecordService.createHistoricalSale({
      buyer_record_id: Number(buyerRecordId),
      property_id: propertyId ? Number(propertyId) : null,
      property_name_snapshot: propertyNameSnapshot.trim(),
      transaction_date: transactionDate || null,
      transaction_value: transactionValue ? Number(transactionValue) : null,
      payment_method: paymentMethod?.trim() || null,
      status: status || 'completed',
      notes: notes?.trim() || null,
      data_label: dataLabel?.trim() || null,
      recorded_by_user_id: req.user.id,
    });

    return res.status(201).json({
      message: 'Data penjualan historis berhasil ditambahkan',
      historicalSale: buildHistoricalSalePayload(sale),
    });
  } catch (error) {
    return next(error);
  }
}

async function updateHistoricalSale(req, res, next) {
  try {
    const id = validateId(req.params.id);
    const { propertyId, propertyNameSnapshot, transactionDate, transactionValue, paymentMethod, status, notes, dataLabel } = req.body;

    if (!propertyNameSnapshot?.trim()) throw createError('Nama properti wajib diisi', 400);

    const existing = await buyerRecordService.findHistoricalSaleById(id);
    if (!existing) throw createError('Data penjualan historis tidak ditemukan', 404);

    const updated = await buyerRecordService.updateHistoricalSale(id, {
      property_id: propertyId ? Number(propertyId) : null,
      property_name_snapshot: propertyNameSnapshot.trim(),
      transaction_date: transactionDate || null,
      transaction_value: transactionValue ? Number(transactionValue) : null,
      payment_method: paymentMethod?.trim() || null,
      status: status || 'completed',
      notes: notes?.trim() || null,
      data_label: dataLabel?.trim() || null,
    });

    return res.status(200).json({
      message: 'Data penjualan historis berhasil diperbarui',
      historicalSale: buildHistoricalSalePayload(updated),
    });
  } catch (error) {
    return next(error);
  }
}

async function deleteHistoricalSale(req, res, next) {
  try {
    const id = validateId(req.params.id);
    const existing = await buyerRecordService.findHistoricalSaleById(id);
    if (!existing) throw createError('Data penjualan historis tidak ditemukan', 404);
    await buyerRecordService.deleteHistoricalSale(id);
    return res.status(200).json({ message: 'Data penjualan historis berhasil dihapus' });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  // Buyer Records
  listBuyerRecords,
  getBuyerRecord,
  getBuyerRecordActivity,
  createBuyerRecord,
  updateBuyerRecord,
  verifyBuyerRecord,
  deleteBuyerRecord,
  // Historical Sales
  listHistoricalSales,
  getHistoricalSale,
  createHistoricalSale,
  updateHistoricalSale,
  deleteHistoricalSale,
};
