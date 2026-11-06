const purchaseService = require('../services/purchaseService');
const authService = require('../services/authService');
const invoiceService = require('../services/invoiceService');
const notificationService = require('../services/notificationService');
const midtransService = require('../services/midtransService');

const VALID_PAYMENT_METHODS = new Set(['Cash Payment', 'QRIS']);
const VALID_REVIEW_STATUSES = new Set(['confirmed', 'rejected']);
const VALID_FILTER_STATUSES = new Set([
  'pending_payment',
  'payment_uploaded',
  'payment_review',
  'confirmed',
  'rejected',
  'cancelled',
]);

function createError(message, statusCode) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

function validatePurchaseId(value) {
  const id = Number.parseInt(String(value || ''), 10);

  if (!Number.isInteger(id) || id <= 0) {
    throw createError('ID pemesanan tidak valid', 400);
  }

  return id;
}

function validatePropertyId(value) {
  const id = Number.parseInt(String(value || ''), 10);

  if (!Number.isInteger(id) || id <= 0) {
    throw createError('Properti tidak valid', 400);
  }

  return id;
}

function validateCreateBody(body) {
  const propertyId = validatePropertyId(body.propertyId);

  const paymentMethod = String(body.paymentMethod || '').trim();
  if (!VALID_PAYMENT_METHODS.has(paymentMethod)) {
    throw createError('Metode pembayaran tidak valid. Pilih: Cash Payment atau QRIS', 400);
  }

  const buyerName = String(body.buyerName || '').trim();
  const buyerPhone = String(body.buyerPhone || '').trim();
  const buyerAddress = String(body.buyerAddress || '').trim();
  const notes = String(body.notes || '').trim();

  if (!buyerName) {
    throw createError('Nama pemesan wajib diisi', 400);
  }

  return {
    propertyId,
    paymentMethod,
    buyerName,
    buyerPhone: buyerPhone || null,
    buyerAddress: buyerAddress || null,
    notes: notes || null,
  };
}

function validateStatusUpdateBody(body) {
  const status = String(body.status || '').trim().toLowerCase();

  if (!VALID_REVIEW_STATUSES.has(status)) {
    throw createError('Status tidak valid. Gunakan: confirmed atau rejected', 400);
  }

  if (status === 'rejected') {
    const reason = String(body.rejectionReason || '').trim();
    if (!reason) {
      throw createError('Alasan penolakan wajib diisi', 400);
    }
    return { status, rejectionReason: reason };
  }

  return { status, rejectionReason: null };
}

function normalizeDate(value, fieldName) {
  const text = String(value || '').trim();
  if (!text) return null;
  if (!/^\d{4}-\d{2}-\d{2}$/.test(text)) {
    throw createError(`${fieldName} harus memakai format YYYY-MM-DD`, 400);
  }
  return text;
}

function normalizeMonth(value) {
  const text = String(value || '').trim();
  if (!text) return null;
  const month = Number.parseInt(text, 10);
  if (!Number.isInteger(month) || month < 1 || month > 12) {
    throw createError('Bulan filter harus bernilai 1-12', 400);
  }
  return month;
}

function normalizeYear(value) {
  const text = String(value || '').trim();
  if (!text) return null;
  const year = Number.parseInt(text, 10);
  if (!Number.isInteger(year) || year < 2000 || year > 2100) {
    throw createError('Tahun filter tidak valid', 400);
  }
  return year;
}

function resolveAssetUrl(req, relPath) {
  if (!relPath) return null;
  if (/^https?:\/\//i.test(relPath)) return relPath;
  const normalised = relPath.startsWith('/') ? relPath : `/${relPath}`;
  return `${req.protocol}://${req.get('host')}${normalised}`;
}

function buildPurchasePayload(req, item) {
  const isQris = String(item.payment_method).toUpperCase().includes('QRIS');

  return {
    id: item.id,
    buyerUserId: item.buyer_user_id,
    buyerRecordId: item.buyer_record_id,
    propertyId: item.property_id,
    propertyTitle: item.property_title,
    propertyLocation: item.property_location,
    propertyThumbnailUrl: resolveAssetUrl(req, item.property_thumbnail_url),
    propertyPrice: item.property_price,
    paymentMethod: item.payment_method,
    paymentAccountNumber: item.payment_account_number || '-',
    paymentAccountName: item.payment_account_name || (isQris ? 'Midtrans Payment Gateway' : 'Kasir Astana Karya'),
    paymentBankNote: isQris ? 'Midtrans QRIS' : 'Tunai di Kantor Pemasaran',
    paymentAmount: item.payment_amount,
    paymentDueAt: item.payment_due_at,
    cancelledAt: item.cancelled_at,
    buyerNameSnapshot: item.buyer_name_snapshot,
    buyerPhoneSnapshot: item.buyer_phone_snapshot,
    buyerAddressSnapshot: item.buyer_address_snapshot,
    notes: item.notes,
    status: item.status,
    paymentProofUrl: resolveAssetUrl(req, item.payment_proof_path),
    paymentProofUploadedAt: item.payment_proof_uploaded_at,
    processedByUserId: item.processed_by_user_id,
    processedByName: item.processed_by_name,
    rejectionReason: item.rejection_reason,
    processedAt: item.processed_at,
    midtransOrderId: item.midtrans_order_id || null,
    midtransTransactionId: item.midtrans_transaction_id || null,
    midtransQrUrl: item.midtrans_qr_url || null,
    midtransPaymentStatus: item.midtrans_payment_status || (isQris ? 'pending' : null),
    midtransExpiryTime: item.midtrans_expiry_time || null,
    createdAt: item.created_at,
    updatedAt: item.updated_at,
  };
}

async function createPurchase(req, res, next) {
  try {
    await purchaseService.cancelOverduePendingPayments();
    const {
      propertyId,
      paymentMethod,
      buyerName,
      buyerPhone,
      buyerAddress,
      notes,
    } = validateCreateBody(req.body);

    const property = await purchaseService.findPropertyForPurchase(propertyId);
    if (!property || property.status === 'Terjual' || property.status === 'Sedang Dibooking') {
      throw createError('Properti tidak tersedia untuk dipesan (sudah dibooking atau terjual)', 400);
    }

    const purchase = await purchaseService.createPurchase({
      buyerUserId: req.user.sub,
      propertyId,
      paymentMethod,
      buyerNameSnapshot: buyerName,
      buyerPhoneSnapshot: buyerPhone,
      buyerAddressSnapshot: buyerAddress,
      notes,
    });

    let finalPurchase = purchase;

    // Jika metode pembayaran QRIS, langsung buat transaksi di Midtrans
    if (paymentMethod === 'QRIS') {
      try {
        const midtransData = await midtransService.createQrisTransaction({
          purchaseId: purchase.id,
          grossAmount: purchase.property_price || property.price,
          buyerName,
          buyerPhone,
          propertyTitle: property.title,
        });

        finalPurchase = await purchaseService.updateMidtransPayment({
          id: purchase.id,
          orderId: midtransData.orderId,
          transactionId: midtransData.transactionId,
          qrUrl: midtransData.qrUrl,
          paymentStatus: midtransData.paymentStatus,
          expiryTime: midtransData.expiryTime,
        });
      } catch (err) {
        console.error('[createPurchase QRIS Midtrans Error]', err.message);
        throw createError(
          'Pembayaran QRIS gagal dibuat di Midtrans. Silakan coba lagi.',
          502,
        );
      }
    }

    try {
      await notificationService.notifyStaffAndAdmins({
        title: 'Pesanan Baru',
        message: `Pemesanan properti baru untuk: ${property.title} (${paymentMethod}).`,
        type: 'purchase',
        actionUrl: '/purchase-status',
      });
    } catch (_) {}

    return res.status(201).json({
      message: 'Pesanan berhasil dibuat',
      purchase: buildPurchasePayload(req, finalPurchase),
    });
  } catch (error) {
    return next(error);
  }
}

async function listMyOrders(req, res, next) {
  try {
    await purchaseService.cancelOverduePendingPayments();
    const purchases = await purchaseService.findPurchasesByBuyerId(req.user.sub);
    return res.status(200).json({
      message: 'Data pemesanan berhasil diambil',
      purchases: purchases.map((item) => buildPurchasePayload(req, item)),
    });
  } catch (error) {
    return next(error);
  }
}

async function listAllOrders(req, res, next) {
  try {
    await purchaseService.cancelOverduePendingPayments();
    const rawStatus = String(req.query.status || '').trim().toLowerCase();
    const status = rawStatus && VALID_FILTER_STATUSES.has(rawStatus) ? rawStatus : null;
    const search = String(req.query.search || '').trim() || null;
    const from = normalizeDate(req.query.from, 'Tanggal awal');
    const to = normalizeDate(req.query.to, 'Tanggal akhir');
    const month = normalizeMonth(req.query.month);
    const year = normalizeYear(req.query.year);

    const purchases = await purchaseService.findAllPurchases({ status, search, from, to, month, year });
    return res.status(200).json({
      message: 'Data semua pemesanan berhasil diambil',
      purchases: purchases.map((item) => buildPurchasePayload(req, item)),
    });
  } catch (error) {
    return next(error);
  }
}

async function getPurchaseDetail(req, res, next) {
  try {
    await purchaseService.cancelOverduePendingPayments();
    const purchaseId = validatePurchaseId(req.params.id);
    const purchase = await purchaseService.findPurchaseById(purchaseId);

    if (!purchase) {
      throw createError('Data pemesanan tidak ditemukan', 404);
    }

    const userRole = String(req.user?.role || '').toLowerCase();
    if (userRole === 'pembeli' && purchase.buyer_user_id !== req.user.sub) {
      throw createError('Anda tidak memiliki akses ke pemesanan ini', 403);
    }

    return res.status(200).json({
      message: 'Detail pemesanan berhasil diambil',
      purchase: buildPurchasePayload(req, purchase),
    });
  } catch (error) {
    return next(error);
  }
}

async function uploadPaymentProof(req, res, next) {
  try {
    await purchaseService.cancelOverduePendingPayments();
    const purchaseId = validatePurchaseId(req.params.id);
    const purchase = await purchaseService.findPurchaseById(purchaseId);

    if (!purchase) {
      throw createError('Data pemesanan tidak ditemukan', 404);
    }

    if (purchase.buyer_user_id !== req.user.sub) {
      throw createError('Anda tidak memiliki akses ke pemesanan ini', 403);
    }

    if (purchase.status !== 'pending_payment' && purchase.status !== 'rejected') {
      throw createError(
        purchase.status === 'cancelled'
          ? 'Pesanan otomatis dibatalkan karena melewati batas waktu pembayaran'
          : 'Bukti pembayaran hanya dapat diunggah saat status masih "Menunggu Pembayaran" atau "Ditolak"',
        400,
      );
    }

    if (!req.file) {
      throw createError('File bukti pembayaran wajib diunggah', 400);
    }

    const relativePath = `/uploads/payment-proofs/${req.file.filename}`;

    const updated = await purchaseService.setPaymentProof({
      id: purchaseId,
      paymentProofPath: relativePath,
    });

    try {
      await notificationService.notifyStaffAndAdmins({
        title: 'Bukti Pembayaran Diunggah',
        message: `Pembeli telah mengunggah bukti pembayaran untuk properti: ${purchase.property_title || 'Properti'}.`,
        type: 'purchase',
        actionUrl: '/purchase-status',
      });
    } catch (_) {}

    return res.status(200).json({
      message: 'Bukti pembayaran berhasil diunggah',
      purchase: buildPurchasePayload(req, updated),
    });
  } catch (error) {
    return next(error);
  }
}

async function updatePurchaseStatus(req, res, next) {
  try {
    await purchaseService.cancelOverduePendingPayments();
    const purchaseId = validatePurchaseId(req.params.id);
    const { status, rejectionReason } = validateStatusUpdateBody(req.body);

    const purchase = await purchaseService.findPurchaseById(purchaseId);
    if (!purchase) {
      throw createError('Data pemesanan tidak ditemukan', 404);
    }

    const actionableStatuses = new Set(['pending_payment', 'payment_uploaded', 'payment_review']);
    if (!actionableStatuses.has(purchase.status)) {
      throw createError(
        'Pemesanan ini tidak dalam status yang dapat diproses (sudah dikonfirmasi atau ditolak)',
        400,
      );
    }

    const processor = await authService.findUserById(req.user.sub);
    const processorName = processor ? processor.name : 'Staf';

    const updated = await purchaseService.updatePurchaseStatus({
      id: purchaseId,
      status,
      rejectionReason,
      processedByUserId: req.user.sub,
      processedByName: processorName,
    });

    const isConfirmed = status === 'confirmed';

    // Auto-generate invoice when purchase is confirmed
    if (isConfirmed) {
      await invoiceService.createInvoice({
        purchaseId: updated.id,
        buyerId: updated.buyer_user_id,
        propertyId: updated.property_id,
        propertyName: updated.property_title || 'Properti',
        propertyPrice: updated.property_price || 0,
        paymentMethod: updated.payment_method,
        paymentProofUrl: updated.payment_proof_path,
      });
    }

    try {
      await notificationService.createNotification({
        userId: updated.buyer_user_id,
        title: isConfirmed ? 'Pesanan Dikonfirmasi' : 'Pesanan Ditolak',
        message: isConfirmed 
          ? `Pesanan Anda untuk properti: ${updated.property_title || 'Properti'} telah dikonfirmasi.` 
          : `Pesanan Anda untuk properti: ${updated.property_title || 'Properti'} ditolak. Alasan: ${rejectionReason || '-'}`,
        type: 'purchase',
        actionUrl: '/purchase-status',
      });
    } catch (_) {}

    return res.status(200).json({
      message: isConfirmed
        ? 'Pemesanan berhasil dikonfirmasi'
        : 'Pemesanan berhasil ditolak',
      purchase: buildPurchasePayload(req, updated),
    });
  } catch (error) {
    return next(error);
  }
}

async function checkMidtransStatus(req, res, next) {
  try {
    const purchaseId = validatePurchaseId(req.params.id);
    const purchase = await purchaseService.findPurchaseById(purchaseId);
    if (!purchase) {
      throw createError('Data pemesanan tidak ditemukan', 404);
    }

    if (purchase.payment_method !== 'QRIS') {
      throw createError('Pemesanan ini tidak menggunakan metode QRIS', 400);
    }

    if (purchase.status === 'confirmed') {
      return res.status(200).json({
        message: 'Pembayaran sudah lunas dan dikonfirmasi',
        status: 'confirmed',
        midtransStatus: 'settlement',
        purchase: buildPurchasePayload(req, purchase),
      });
    }

    const midtransRes = await midtransService.checkTransactionStatus(purchase.midtrans_order_id);
    const txStatus = String(midtransRes.transactionStatus || '').toLowerCase();

    let updatedPurchase = purchase;
    if (txStatus) {
      updatedPurchase = await purchaseService.updateMidtransStatus({
        id: purchaseId,
        paymentStatus: txStatus,
        transactionId: midtransRes.transactionId,
      });
    }
    if (txStatus === 'settlement' || txStatus === 'capture') {
      updatedPurchase = await purchaseService.confirmPurchaseByMidtrans({
        id: purchaseId,
        transactionId: midtransRes.transactionId || purchase.midtrans_transaction_id,
      });

      await invoiceService.createInvoice({
        purchaseId: updatedPurchase.id,
        buyerId: updatedPurchase.buyer_user_id,
        propertyId: updatedPurchase.property_id,
        propertyName: updatedPurchase.property_title || 'Properti',
        propertyPrice: updatedPurchase.property_price || 0,
        paymentMethod: updatedPurchase.payment_method,
        paymentProofUrl: updatedPurchase.payment_proof_path,
      });

      try {
        await notificationService.createNotification({
          userId: updatedPurchase.buyer_user_id,
          title: 'Pembayaran QRIS Berhasil!',
          message: `Pembayaran QRIS untuk: ${updatedPurchase.property_title || 'Properti'} telah berhasil diverifikasi via Midtrans.`,
          type: 'purchase',
          actionUrl: '/purchase-status',
        });
      } catch (_) {}
    } else if (txStatus === 'expire' || txStatus === 'cancel') {
      updatedPurchase = await purchaseService.updatePurchaseStatus({
        id: purchaseId,
        status: 'cancelled',
        rejectionReason: 'Transaksi QRIS Midtrans telah kedaluwarsa atau dibatalkan',
        processedByUserId: null,
        processedByName: 'Midtrans Gateway',
      });
    }

    return res.status(200).json({
      message: (txStatus === 'settlement' || txStatus === 'capture')
        ? 'Pembayaran berhasil diverifikasi!'
        : 'Status pembayaran berhasil dicek',
      status: updatedPurchase.status,
      midtransStatus: txStatus || purchase.midtrans_payment_status || 'pending',
      purchase: buildPurchasePayload(req, updatedPurchase),
    });
  } catch (error) {
    return next(error);
  }
}

async function simulateMidtransPayment(req, res, next) {
  try {
    const purchaseId = validatePurchaseId(req.params.id);
    const purchase = await purchaseService.findPurchaseById(purchaseId);
    if (!purchase) {
      throw createError('Data pemesanan tidak ditemukan', 404);
    }
    if (purchase.payment_method !== 'QRIS') {
      throw createError('Simulasi ini khusus untuk metode QRIS', 400);
    }

    const updated = await purchaseService.confirmPurchaseByMidtrans({
      id: purchaseId,
      transactionId: `SIMULATED-TX-${Date.now()}`,
    });

    await invoiceService.createInvoice({
      purchaseId: updated.id,
      buyerId: updated.buyer_user_id,
      propertyId: updated.property_id,
      propertyName: updated.property_title || 'Properti',
      propertyPrice: updated.property_price || 0,
      paymentMethod: updated.payment_method,
      paymentProofUrl: updated.payment_proof_path,
    });

    try {
      await notificationService.createNotification({
        userId: updated.buyer_user_id,
        title: 'Pembayaran QRIS Dikonfirmasi (Sandbox)',
        message: `Simulasi pembayaran QRIS untuk ${updated.property_title || 'Properti'} berhasil diverifikasi.`,
        type: 'purchase',
        actionUrl: '/purchase-status',
      });
    } catch (_) {}

    return res.status(200).json({
      message: 'Simulasi pembayaran QRIS berhasil! Pesanan kini telah Lunas & Dikonfirmasi.',
      status: 'confirmed',
      midtransStatus: 'settlement',
      purchase: buildPurchasePayload(req, updated),
    });
  } catch (error) {
    return next(error);
  }
}

async function handleMidtransWebhook(req, res) {
  try {
    const body = req.body;
    console.log('[Midtrans Webhook Received]', body);

    if (!midtransService.verifyWebhookSignature(body)) {
      console.warn('[Midtrans Webhook] Invalid signature!');
      return res.status(403).json({ message: 'Invalid signature' });
    }

    const orderId = body.order_id;
    const txStatus = String(body.transaction_status || '').toLowerCase();
    const fraudStatus = String(body.fraud_status || '').toLowerCase();

    const purchase = await purchaseService.findPurchaseByMidtransOrderId(orderId);
    if (!purchase) {
      console.warn('[Midtrans Webhook] Purchase not found for orderId:', orderId);
      return res.status(200).json({ message: 'Order not found, acknowledged' });
    }

    await purchaseService.updateMidtransStatus({
      id: purchase.id,
      paymentStatus: txStatus || 'pending',
      transactionId: body.transaction_id,
    });

    if (txStatus === 'settlement' || (txStatus === 'capture' && fraudStatus === 'accept')) {
      if (purchase.status !== 'confirmed') {
        const updated = await purchaseService.confirmPurchaseByMidtrans({
          id: purchase.id,
          transactionId: body.transaction_id,
        });

        await invoiceService.createInvoice({
          purchaseId: updated.id,
          buyerId: updated.buyer_user_id,
          propertyId: updated.property_id,
          propertyName: updated.property_title || 'Properti',
          propertyPrice: updated.property_price || 0,
          paymentMethod: updated.payment_method,
          paymentProofUrl: updated.payment_proof_path,
        });

        try {
          await notificationService.createNotification({
            userId: updated.buyer_user_id,
            title: 'Pembayaran QRIS Berhasil!',
            message: `Pembayaran QRIS untuk: ${updated.property_title || 'Properti'} telah diterima via Midtrans.`,
            type: 'purchase',
            actionUrl: '/purchase-status',
          });
        } catch (_) {}
      }
    } else if (txStatus === 'expire' || txStatus === 'cancel') {
      if (purchase.status === 'pending_payment') {
        await purchaseService.updatePurchaseStatus({
          id: purchase.id,
          status: 'cancelled',
          rejectionReason: 'Transaksi QRIS Midtrans telah kedaluwarsa atau dibatalkan',
          processedByUserId: null,
          processedByName: 'Midtrans Gateway',
        });
      }
    }

    return res.status(200).json({ message: 'Webhook processed successfully' });
  } catch (error) {
    console.error('[Midtrans Webhook Error]', error);
    return res.status(500).json({ message: 'Webhook processing error', error: error.message });
  }
}

module.exports = {
  createPurchase,
  listMyOrders,
  listAllOrders,
  getPurchaseDetail,
  uploadPaymentProof,
  updatePurchaseStatus,
  checkMidtransStatus,
  simulateMidtransPayment,
  handleMidtransWebhook,
};
