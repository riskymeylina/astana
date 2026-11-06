const authService = require('../services/authService');
const notificationService = require('../services/notificationService');
const { sendPasswordResetCode } = require('../services/mailService');
const {
  generateToken,
  generateResetCode,
  generateResetSessionToken,
  hashResetValue,
} = require('../utils/token');
const { buildAuthResponse, buildUserResponse } = require('../utils/response');
const { deleteFileIfExists, toPublicProfilePhotoPath } = require('../utils/file');

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const RESET_CODE_LENGTH = 6;
const RESET_CODE_TTL_MINUTES = 15;
const RESET_SESSION_TTL_MINUTES = 10;
const RESET_RESEND_COOLDOWN_SECONDS = 60;
const RESET_MAX_ATTEMPTS = 5;

function createError(message, statusCode) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

function normalizeEmail(email) {
  return (email || '').trim().toLowerCase();
}

function isValidEmail(email) {
  return EMAIL_REGEX.test(email);
}

function validateRegisterBody(body) {
  if (!body.name?.trim() || !body.email?.trim() || !body.phone?.trim() || !body.password) {
    throw createError('Semua field wajib diisi', 400);
  }

  if (!isValidEmail(normalizeEmail(body.email))) {
    throw createError('Format email tidak valid', 400);
  }
}

function validateLoginBody(body) {
  if (!body.email?.trim() || !body.password) {
    throw createError('Email dan kata sandi wajib diisi', 400);
  }

  if (!isValidEmail(normalizeEmail(body.email))) {
    throw createError('Format email tidak valid', 400);
  }
}

function validateSocialLoginBody(body) {
  const provider = String(body.provider || '').toLowerCase().trim();
  if (!['google', 'facebook'].includes(provider)) {
    throw createError('Provider harus berupa google atau facebook', 400);
  }

  const email = normalizeEmail(body.email);
  if (!email || !isValidEmail(email)) {
    throw createError('Format email tidak valid', 400);
  }

  const name = String(body.name || '').trim();
  if (!name) {
    throw createError('Nama wajib diisi', 400);
  }

  const providerId = body.providerId ? String(body.providerId).trim() : null;
  const photoUrl = body.photoUrl ? String(body.photoUrl).trim() : null;

  return {
    provider,
    email,
    name,
    providerId,
    photoUrl,
  };
}

function validateForgotPasswordBody(body) {
  const email = normalizeEmail(body.email);
  if (!email) {
    throw createError('Email wajib diisi', 400);
  }

  if (!isValidEmail(email)) {
    throw createError('Format email tidak valid', 400);
  }

  return email;
}

function validateVerifyResetCodeBody(body) {
  const email = validateForgotPasswordBody(body);
  const code = String(body.code || '').trim();

  if (!/^\d{6}$/.test(code)) {
    throw createError('Kode verifikasi harus 6 digit', 400);
  }

  return { email, code };
}

function validateResetPasswordBody(body) {
  const email = validateForgotPasswordBody(body);
  const resetToken = String(body.resetToken || '').trim();
  const newPassword = String(body.newPassword || '');

  if (!resetToken) {
    throw createError('Token reset tidak valid', 400);
  }

  if (newPassword.length < 8) {
    throw createError('Kata sandi baru minimal 8 karakter', 400);
  }

  return { email, resetToken, newPassword };
}

function createFutureDate(minutes) {
  return new Date(Date.now() + minutes * 60 * 1000);
}

function normalizeOptionalString(value) {
  return value == null ? '' : String(value).trim();
}

function normalizeOptionalNumber(value, fieldLabel) {
  if (value == null || value == '') {
    return null;
  }

  const number = Number(value);
  if (!Number.isFinite(number) || number <= 0) {
    throw createError(`${fieldLabel} harus lebih dari 0`, 400);
  }

  return Math.trunc(number);
}

function validatePropertyPreferencesBody(body) {
  const rawCategories = Array.isArray(body.preferredCategories) ? body.preferredCategories : [];
  const preferredCategories = rawCategories
    .map((item) => String(item || '').trim())
    .filter((item) => item.length > 0);

  if (preferredCategories.length === 0) {
    throw createError('Minimal satu kategori properti harus dipilih', 400);
  }

  const preferredLocation = normalizeOptionalString(body.preferredLocation);
  if (!preferredLocation) {
    throw createError('Lokasi diminati wajib diisi', 400);
  }

  const minPrice = normalizeOptionalNumber(body.minPrice, 'Harga minimum');
  const maxPrice = normalizeOptionalNumber(body.maxPrice, 'Harga maksimum');
  if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
    throw createError('Harga minimum tidak boleh lebih besar dari harga maksimum', 400);
  }

  return {
    preferredCategories,
    preferredLocation,
    minPrice,
    maxPrice,
    minBedrooms: normalizeOptionalNumber(body.minBedrooms, 'Minimal kamar tidur'),
    minBathrooms: normalizeOptionalNumber(body.minBathrooms, 'Minimal kamar mandi'),
    minBuildingArea: normalizeOptionalNumber(body.minBuildingArea, 'Luas bangunan minimum'),
    minLandArea: normalizeOptionalNumber(body.minLandArea, 'Luas tanah minimum'),
    notes: normalizeOptionalString(body.notes),
  };
}

function buildPropertyPreferencesResponse(message, preferences) {
  return {
    message,
    preferences: {
      preferredCategories: preferences.preferred_categories,
      preferredLocation: preferences.preferred_location,
      minPrice: preferences.min_price,
      maxPrice: preferences.max_price,
      minBedrooms: preferences.min_bedrooms,
      minBathrooms: preferences.min_bathrooms,
      minBuildingArea: preferences.min_building_area,
      minLandArea: preferences.min_land_area,
      notes: preferences.notes,
    },
  };
}

function normalizePhoneLike(value, fieldLabel) {
  const normalized = normalizeOptionalString(value);
  if (!normalized) {
    return '';
  }

  if (!/^[0-9+\-()\s]{8,20}$/.test(normalized)) {
    throw createError(`${fieldLabel} tidak valid`, 400);
  }

  return normalized;
}

function assertMaxLength(value, max, fieldLabel) {
  if (value.length > max) {
    throw createError(`${fieldLabel} maksimal ${max} karakter`, 400);
  }
}

function validateBuyerContactBody(body) {
  const email = normalizeEmail(body.email);
  if (!email) {
    throw createError('Email wajib diisi', 400);
  }

  if (!isValidEmail(email)) {
    throw createError('Format email tidak valid', 400);
  }

  const phone = normalizePhoneLike(body.phone, 'Nomor HP');
  if (!phone) {
    throw createError('Nomor HP wajib diisi', 400);
  }

  const whatsapp = normalizePhoneLike(body.whatsapp, 'Nomor WhatsApp');
  const contactNote = normalizeOptionalString(body.contactNote);
  assertMaxLength(contactNote, 255, 'Catatan kontak');

  return {
    email,
    phone,
    whatsapp,
    contactNote,
  };
}

function validateBuyerAddressBody(body) {
  const recipientName = normalizeOptionalString(body.recipientName);
  if (!recipientName) {
    throw createError('Nama penerima wajib diisi', 400);
  }

  const addressLine = normalizeOptionalString(body.addressLine);
  if (!addressLine) {
    throw createError('Alamat lengkap wajib diisi', 400);
  }

  const province = normalizeOptionalString(body.province);
  if (!province) {
    throw createError('Provinsi wajib diisi', 400);
  }

  const city = normalizeOptionalString(body.city);
  if (!city) {
    throw createError('Kota / kabupaten wajib diisi', 400);
  }

  const district = normalizeOptionalString(body.district);
  if (!district) {
    throw createError('Kecamatan wajib diisi', 400);
  }

  const subdistrict = normalizeOptionalString(body.subdistrict);
  if (!subdistrict) {
    throw createError('Kelurahan / desa wajib diisi', 400);
  }

  const postalCode = normalizeOptionalString(body.postalCode);
  if (postalCode && !/^\d{5}$/.test(postalCode)) {
    throw createError('Kode pos harus 5 digit', 400);
  }

  const landmark = normalizeOptionalString(body.landmark);

  assertMaxLength(recipientName, 100, 'Nama penerima');
  assertMaxLength(addressLine, 255, 'Alamat lengkap');
  assertMaxLength(province, 100, 'Provinsi');
  assertMaxLength(city, 100, 'Kota / kabupaten');
  assertMaxLength(district, 100, 'Kecamatan');
  assertMaxLength(subdistrict, 100, 'Kelurahan / desa');
  assertMaxLength(postalCode, 10, 'Kode pos');
  assertMaxLength(landmark, 255, 'Patokan');

  return {
    recipientName,
    addressLine,
    province,
    city,
    district,
    subdistrict,
    postalCode,
    landmark,
  };
}

function validateBuyerProfileBody(body) {
  return {
    ...validateBuyerContactBody(body),
    ...validateBuyerAddressBody(body),
  };
}

function buildBuyerProfileResponse(message, profile, user) {
  return {
    message,
    user: user ? buildUserResponse('', user).user : undefined,
    profile: {
      email: profile.email,
      phone: profile.phone,
      whatsapp: profile.whatsapp,
      contactNote: profile.contact_note,
      recipientName: profile.recipient_name,
      addressLine: profile.address_line,
      province: profile.province,
      city: profile.city,
      district: profile.district,
      subdistrict: profile.subdistrict,
      postalCode: profile.postal_code,
      landmark: profile.landmark,
    },
  };
}

function hasResendCooldown(lastSentAt) {
  if (!lastSentAt) {
    return false;
  }

  const elapsed = Date.now() - new Date(lastSentAt).getTime();
  return elapsed < RESET_RESEND_COOLDOWN_SECONDS * 1000;
}

function isExpired(value) {
  return !value || new Date(value).getTime() <= Date.now();
}

async function register(req, res, next) {
  try {
    validateRegisterBody(req.body);

    const user = await authService.registerUser({
      name: req.body.name.trim(),
      email: normalizeEmail(req.body.email),
      phone: req.body.phone.trim(),
      password: req.body.password,
      role: ['pembeli', 'staf', 'admin'].includes((req.body.role || '').toLowerCase().trim()) ? (req.body.role || '').toLowerCase().trim() : 'pembeli',
    });

    try {
      await notificationService.notifyStaffAndAdmins({
        title: 'Pengguna Baru Terdaftar',
        message: `Calon pembeli baru telah terdaftar: ${user.name} (${user.email}).`,
        type: 'user',
        actionUrl: '/home',
      });
    } catch (_) {}

    const token = generateToken(user);
    return res.status(201).json(buildAuthResponse('Registrasi berhasil', token, user));
  } catch (error) {
    return next(error);
  }
}

async function login(req, res, next) {
  try {
    validateLoginBody(req.body);

    const user = await authService.loginUser({
      email: normalizeEmail(req.body.email),
      password: req.body.password,
    });

    const token = generateToken(user);
    return res.status(200).json(buildAuthResponse('Login berhasil', token, user));
  } catch (error) {
    return next(error);
  }
}

async function socialLogin(req, res, next) {
  try {
    const payload = validateSocialLoginBody(req.body);

    const user = await authService.socialLogin(payload);

    try {
      if (user.created_at && Date.now() - new Date(user.created_at).getTime() < 10000) {
        await notificationService.notifyStaffAndAdmins({
          title: 'Pengguna Baru Terdaftar via Social Login',
          message: `Calon pembeli baru telah terdaftar melalui ${payload.provider}: ${user.name} (${user.email}).`,
          type: 'user',
          actionUrl: '/home',
        });
      }
    } catch (_) {}

    const token = generateToken(user);
    const providerLabel = payload.provider === 'google' ? 'Google' : 'Facebook';
    return res.status(200).json(buildAuthResponse(`Login ${providerLabel} berhasil`, token, user));
  } catch (error) {
    return next(error);
  }
}

async function forgotPassword(req, res, next) {
  const genericResponse = {
    message: 'Jika email terdaftar, kode verifikasi telah dikirim.',
  };

  try {
    const email = validateForgotPasswordBody(req.body);
    const user = await authService.findUserByEmail(email);

    if (!user) {
      return res.status(200).json(genericResponse);
    }

    const latestRequest = await authService.findLatestPasswordResetRequestByUserId(user.id);
    if (latestRequest && !isExpired(latestRequest.expires_at) && hasResendCooldown(latestRequest.last_sent_at)) {
      return res.status(200).json(genericResponse);
    }

    const resetCode = generateResetCode(RESET_CODE_LENGTH);
    await authService.createPasswordResetRequest({
      userId: user.id,
      codeHash: hashResetValue(resetCode),
      expiresAt: createFutureDate(RESET_CODE_TTL_MINUTES),
    });

    await sendPasswordResetCode({
      toEmail: user.email,
      code: resetCode,
      expiresInMinutes: RESET_CODE_TTL_MINUTES,
    });

    return res.status(200).json(genericResponse);
  } catch (error) {
    return next(error);
  }
}

async function verifyResetCode(req, res, next) {
  try {
    const { email, code } = validateVerifyResetCodeBody(req.body);
    const user = await authService.findUserByEmail(email);

    if (!user) {
      throw createError('Kode verifikasi tidak valid atau sudah kedaluwarsa', 400);
    }

    const latestRequest = await authService.findLatestPasswordResetRequestByUserId(user.id);
    if (!latestRequest || isExpired(latestRequest.expires_at)) {
      throw createError('Kode verifikasi tidak valid atau sudah kedaluwarsa', 400);
    }

    if (latestRequest.attempt_count >= RESET_MAX_ATTEMPTS) {
      await authService.consumePasswordResetRequest(latestRequest.id);
      throw createError('Kode verifikasi sudah tidak dapat digunakan', 400);
    }

    if (latestRequest.code_hash !== hashResetValue(code)) {
      const updatedRequest = await authService.incrementPasswordResetAttempt(latestRequest.id);
      if (updatedRequest.attempt_count >= RESET_MAX_ATTEMPTS) {
        await authService.consumePasswordResetRequest(latestRequest.id);
      }
      throw createError('Kode verifikasi tidak valid atau sudah kedaluwarsa', 400);
    }

    const resetToken = generateResetSessionToken();
    await authService.markPasswordResetVerified(
      latestRequest.id,
      hashResetValue(resetToken),
      createFutureDate(RESET_SESSION_TTL_MINUTES),
    );

    return res.status(200).json({
      message: 'Kode verifikasi berhasil',
      resetToken,
    });
  } catch (error) {
    return next(error);
  }
}

async function resetPassword(req, res, next) {
  try {
    const { email, resetToken, newPassword } = validateResetPasswordBody(req.body);
    const user = await authService.findUserByEmail(email);

    if (!user) {
      throw createError('Permintaan reset password tidak valid', 400);
    }

    const resetRequest = await authService.findValidPasswordResetSession(
      user.id,
      hashResetValue(resetToken),
    );

    if (!resetRequest) {
      throw createError('Permintaan reset password tidak valid atau sudah kedaluwarsa', 400);
    }

    await authService.updateUserPassword(user.id, newPassword);
    await authService.consumePasswordResetRequest(resetRequest.id);
    await authService.invalidatePasswordResetRequests(user.id);

    return res.status(200).json({
      message: 'Kata sandi berhasil diperbarui',
    });
  } catch (error) {
    return next(error);
  }
}

async function me(req, res, next) {
  try {
    const user = await authService.findUserById(req.user.sub);

    if (!user) {
      return res.status(401).json({ message: 'User tidak ditemukan' });
    }

    return res.status(200).json(buildUserResponse('Data user berhasil diambil', user));
  } catch (error) {
    return next(error);
  }
}

async function getPropertyPreferences(req, res, next) {
  try {
    const currentUser = await authService.findUserById(req.user.sub);
    if (!currentUser) {
      throw createError('User tidak ditemukan', 401);
    }

    const preferences = await authService.findUserPropertyPreferencesByUserId(req.user.sub);
    return res.status(200).json(buildPropertyPreferencesResponse('Preferensi properti berhasil diambil', preferences));
  } catch (error) {
    return next(error);
  }
}

async function updatePropertyPreferences(req, res, next) {
  try {
    const currentUser = await authService.findUserById(req.user.sub);
    if (!currentUser) {
      throw createError('User tidak ditemukan', 401);
    }

    const payload = validatePropertyPreferencesBody(req.body);
    const preferences = await authService.upsertUserPropertyPreferences(req.user.sub, payload);
    return res.status(200).json(buildPropertyPreferencesResponse('Preferensi properti berhasil disimpan', preferences));
  } catch (error) {
    return next(error);
  }
}

async function getBuyerProfile(req, res, next) {
  try {
    const currentUser = await authService.findUserById(req.user.sub);
    if (!currentUser) {
      throw createError('User tidak ditemukan', 401);
    }

    const profile = await authService.findBuyerProfileByUserId(req.user.sub);
    return res.status(200).json(buildBuyerProfileResponse('Profil buyer berhasil diambil', profile, currentUser));
  } catch (error) {
    return next(error);
  }
}

async function updateBuyerProfile(req, res, next) {
  try {
    const currentUser = await authService.findUserById(req.user.sub);
    if (!currentUser) {
      throw createError('User tidak ditemukan', 401);
    }

    const payload = validateBuyerProfileBody(req.body);
    const emailOwner = await authService.findUserByEmail(payload.email);
    if (emailOwner && Number(emailOwner.id) !== Number(req.user.sub)) {
      throw createError('Email sudah digunakan', 409);
    }

    const profile = await authService.upsertBuyerProfile(req.user.sub, payload);
    const updatedUser = await authService.findUserById(req.user.sub);
    return res.status(200).json(buildBuyerProfileResponse('Profil buyer berhasil disimpan', profile, updatedUser));
  } catch (error) {
    return next(error);
  }
}

async function updateBuyerContact(req, res, next) {
  try {
    const currentUser = await authService.findUserById(req.user.sub);
    if (!currentUser) {
      throw createError('User tidak ditemukan', 401);
    }

    const payload = validateBuyerContactBody(req.body);
    const emailOwner = await authService.findUserByEmail(payload.email);
    if (emailOwner && Number(emailOwner.id) !== Number(req.user.sub)) {
      throw createError('Email sudah digunakan', 409);
    }

    const profile = await authService.updateBuyerContact(req.user.sub, payload);
    const updatedUser = await authService.findUserById(req.user.sub);
    return res.status(200).json(buildBuyerProfileResponse('Kontak buyer berhasil disimpan', profile, updatedUser));
  } catch (error) {
    return next(error);
  }
}

async function updateBuyerAddress(req, res, next) {
  try {
    const currentUser = await authService.findUserById(req.user.sub);
    if (!currentUser) {
      throw createError('User tidak ditemukan', 401);
    }

    const payload = validateBuyerAddressBody(req.body);
    const profile = await authService.updateBuyerAddress(req.user.sub, payload);
    const updatedUser = await authService.findUserById(req.user.sub);
    return res.status(200).json(buildBuyerProfileResponse('Alamat buyer berhasil disimpan', profile, updatedUser));
  } catch (error) {
    return next(error);
  }
}

async function uploadProfilePhoto(req, res, next) {
  const newPublicPath = req.file ? toPublicProfilePhotoPath(req.file.filename) : null;

  try {
    if (!req.file) {
      throw createError('File foto profil wajib diunggah', 400);
    }

    const currentUser = await authService.findUserById(req.user.sub);
    if (!currentUser) {
      throw createError('User tidak ditemukan', 401);
    }

    const previousPhotoPath = currentUser.profile_photo_path;
    const updatedUser = await authService.updateProfilePhotoPath(req.user.sub, newPublicPath);

    await deleteFileIfExists(previousPhotoPath);

    return res.status(200).json(buildUserResponse('Foto profil berhasil diperbarui', updatedUser));
  } catch (error) {
    if (newPublicPath) {
      await deleteFileIfExists(newPublicPath).catch(() => {});
    }
    return next(error);
  }
}

module.exports = {
  register,
  login,
  socialLogin,
  forgotPassword,
  verifyResetCode,
  resetPassword,
  me,
  getBuyerProfile,
  updateBuyerProfile,
  updateBuyerContact,
  updateBuyerAddress,
  getPropertyPreferences,
  updatePropertyPreferences,
  uploadProfilePhoto,
};
