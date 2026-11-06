const express = require('express');
const purchaseController = require('../controllers/purchaseController');
const { requireAuth, requireRole } = require('../middleware/authMiddleware');
const { uploadPaymentProof } = require('../middleware/paymentProofUploadMiddleware');

const router = express.Router();

// Webhook dari Midtrans tidak memerlukan Bearer token pengguna, diverifikasi via signature SHA-512
router.post('/midtrans-webhook', purchaseController.handleMidtransWebhook);

router.use(requireAuth);

router.post('/', requireRole('pembeli'), purchaseController.createPurchase);
router.get('/my-orders', requireRole('pembeli'), purchaseController.listMyOrders);
router.post('/:id/payment-proof', requireRole('pembeli'), uploadPaymentProof, purchaseController.uploadPaymentProof);
router.get('/orders', requireRole('staf', 'admin'), purchaseController.listAllOrders);
router.get('/:id/midtrans-status', requireRole('pembeli', 'staf', 'admin'), purchaseController.checkMidtransStatus);
router.post('/:id/simulate-payment', requireRole('pembeli', 'staf', 'admin'), purchaseController.simulateMidtransPayment);
router.patch('/:id/status', requireRole('staf', 'admin'), purchaseController.updatePurchaseStatus);
router.get('/:id', requireRole('pembeli', 'staf', 'admin'), purchaseController.getPurchaseDetail);

module.exports = router;
