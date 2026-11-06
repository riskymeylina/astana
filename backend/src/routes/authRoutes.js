const express = require('express');
const authController = require('../controllers/authController');
const { requireAuth, requireRole } = require('../middleware/authMiddleware');
const { uploadProfilePhoto } = require('../middleware/uploadMiddleware');
const {
  registerRateLimiter,
  loginRateLimiter,
  forgotPasswordRateLimiter,
  verifyResetCodeRateLimiter,
  resetPasswordRateLimiter,
} = require('../middleware/rateLimitMiddleware');

const router = express.Router();

router.post('/register', registerRateLimiter, authController.register);
router.post('/login', loginRateLimiter, authController.login);
router.post('/social-login', loginRateLimiter, authController.socialLogin);
router.post('/forgot-password', forgotPasswordRateLimiter, authController.forgotPassword);
router.post('/verify-reset-code', verifyResetCodeRateLimiter, authController.verifyResetCode);
router.post('/reset-password', resetPasswordRateLimiter, authController.resetPassword);
router.get('/me', requireAuth, authController.me);
router.get('/buyer-profile', requireAuth, requireRole('pembeli'), authController.getBuyerProfile);
router.patch('/buyer-profile', requireAuth, requireRole('pembeli'), authController.updateBuyerProfile);
router.patch('/buyer-profile/contact', requireAuth, requireRole('pembeli'), authController.updateBuyerContact);
router.patch('/buyer-profile/address', requireAuth, requireRole('pembeli'), authController.updateBuyerAddress);
router.get('/property-preferences', requireAuth, authController.getPropertyPreferences);
router.patch('/property-preferences', requireAuth, authController.updatePropertyPreferences);
router.post('/profile-photo', requireAuth, uploadProfilePhoto, authController.uploadProfilePhoto);

module.exports = router;
