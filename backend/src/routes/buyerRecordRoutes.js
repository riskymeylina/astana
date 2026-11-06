const express = require('express');
const buyerRecordController = require('../controllers/buyerRecordController');
const { requireAuth, requireRole } = require('../middleware/authMiddleware');

const router = express.Router();

// Semua endpoint memerlukan autentikasi
router.use(requireAuth);

// ─── Historical Sales (harus sebelum /:id agar tidak konflik) ──────────────────
router.get(
  '/historical-sales/list',
  requireRole('admin', 'staf'),
  buyerRecordController.listHistoricalSales,
);

router.get(
  '/historical-sales/:id',
  requireRole('admin', 'staf'),
  buyerRecordController.getHistoricalSale,
);

router.post(
  '/historical-sales',
  requireRole('admin'),
  buyerRecordController.createHistoricalSale,
);

router.patch(
  '/historical-sales/:id',
  requireRole('admin'),
  buyerRecordController.updateHistoricalSale,
);

router.delete(
  '/historical-sales/:id',
  requireRole('admin'),
  buyerRecordController.deleteHistoricalSale,
);

// ─── Buyer Records ─────────────────────────────────────────────────────────────
// Admin dan Staf boleh melihat daftar & detail
router.get(
  '/',
  requireRole('admin', 'staf'),
  buyerRecordController.listBuyerRecords,
);

router.get(
  '/:id/activity',
  requireRole('admin', 'staf'),
  buyerRecordController.getBuyerRecordActivity,
);

router.get(
  '/:id',
  requireRole('admin', 'staf'),
  buyerRecordController.getBuyerRecord,
);

// Hanya Admin yang boleh membuat / mengubah / menghapus
router.post(
  '/',
  requireRole('admin'),
  buyerRecordController.createBuyerRecord,
);

router.patch(
  '/:id/verify',
  requireRole('admin'),
  buyerRecordController.verifyBuyerRecord,
);

router.patch(
  '/:id',
  requireRole('admin'),
  buyerRecordController.updateBuyerRecord,
);

router.delete(
  '/:id',
  requireRole('admin'),
  buyerRecordController.deleteBuyerRecord,
);

module.exports = router;
