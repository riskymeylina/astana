const surveyService = require('../services/surveyService');
const notificationService = require('../services/notificationService');

const VALID_STATUSES = new Set(['pending', 'approved', 'rejected', 'cancelled', 'completed']);

function createError(message, statusCode) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

function normalizeStatus(value) {
  return String(value || '').trim().toLowerCase();
}

function validateSurveyRequestId(value) {
  const id = Number.parseInt(String(value || ''), 10);

  if (!Number.isInteger(id) || id <= 0) {
    throw createError('ID permintaan survei tidak valid', 400);
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

function validateDate(value, fieldLabel) {
  const normalized = String(value || '').trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(normalized)) {
    throw createError(`${fieldLabel} tidak valid`, 400);
  }

  const [year, month, day] = normalized.split('-').map(Number);
  const date = new Date(year, month - 1, day);
  if (
    date.getFullYear() !== year ||
    date.getMonth() !== month - 1 ||
    date.getDate() !== day
  ) {
    throw createError(`${fieldLabel} tidak valid`, 400);
  }

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  if (date < today) {
    throw createError(`${fieldLabel} tidak boleh sebelum hari ini`, 400);
  }

  const lastDayOfMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0);
  if (date > lastDayOfMonth) {
    throw createError(`${fieldLabel} tidak boleh melewati bulan berjalan`, 400);
  }

  return normalized;
}

function validateOptionalTime(value, fieldLabel) {
  const normalized = String(value || '').trim();
  if (!normalized) {
    return null;
  }

  if (!/^\d{2}:\d{2}(:\d{2})?$/.test(normalized)) {
    throw createError(`${fieldLabel} tidak valid`, 400);
  }

  const [hours, minutes, seconds = '00'] = normalized.split(':').map(Number);
  if (hours > 23 || minutes > 59 || seconds > 59) {
    throw createError(`${fieldLabel} tidak valid`, 400);
  }

  return normalized.length == 5 ? `${normalized}:00` : normalized;
}

function validateCreateBody(body) {
  const propertyId = validatePropertyId(body.propertyId);
  const requestedDate = validateDate(body.requestedDate, 'Tanggal survei');
  const requestedTime = validateOptionalTime(body.requestedTime, 'Jam survei');
  const notes = String(body.notes || '').trim();

  return {
    propertyId,
    requestedDate,
    requestedTime,
    notes: notes || null,
  };
}

function validateStatusUpdateBody(body) {
  const status = normalizeStatus(body.status);

  if (status !== 'approved' && status !== 'rejected' && status !== 'completed') {
    throw createError('Status survei tidak valid. Gunakan \'approved\', \'rejected\', atau \'completed\'', 400);
  }

  if (status === 'approved') {
    return {
      status,
      approvedScheduleDate: validateDate(body.approvedScheduleDate, 'Tanggal jadwal final'),
      approvedScheduleTime: validateOptionalTime(body.approvedScheduleTime, 'Jam jadwal final'),
      rejectionReason: null,
    };
  }

  if (status === 'completed') {
    return {
      status,
      approvedScheduleDate: null,
      approvedScheduleTime: null,
      rejectionReason: null,
    };
  }

  // status === 'rejected'
  const rejectionReason = String(body.rejectionReason || '').trim();
  if (!rejectionReason) {
    throw createError('Alasan penolakan wajib diisi', 400);
  }
  if (rejectionReason.length > 500) {
    throw createError('Alasan penolakan maksimal 500 karakter', 400);
  }

  return {
    status,
    approvedScheduleDate: null,
    approvedScheduleTime: null,
    rejectionReason,
  };
}

function buildSurveyPayload(item) {
  return {
    id: item.id_survey,
    id_survey: item.id_survey,
    buyerUserId: item.buyer_user_id,
    buyerName: item.buyer_name,
    buyerPhone: item.buyer_phone,
    buyerEmail: item.buyer_email,
    propertyId: item.property_id,
    propertyTitle: item.property_title,
    propertyLocation: item.property_location,
    propertyImageUrl: item.property_image_url,
    requestedDate: item.requested_date,
    requestedTime: item.requested_time,
    notes: item.notes,
    status: item.status,
    approvedScheduleDate: item.approved_schedule_date,
    approvedScheduleTime: item.approved_schedule_time,
    rejectionReason: item.rejection_reason,
    processedByUserId: item.processed_by_user_id,
    processedByName: item.processed_by_name,
    processedByPhone: item.processed_by_phone,
    processedAt: item.processed_at,
    createdAt: item.created_at,
    updatedAt: item.updated_at,
  };
}

async function createSurveyRequest(req, res, next) {
  try {
    const { propertyId, requestedDate, requestedTime, notes } = validateCreateBody(req.body);
    const property = await surveyService.findPropertyById(propertyId);

    if (!property || property.status === 'Terjual') {
      throw createError('Properti tidak ditemukan atau tidak tersedia untuk survei', 404);
    }

    const survey = await surveyService.createSurveyRequest({
      buyerUserId: req.user.sub,
      propertyId,
      requestedDate,
      requestedTime,
      notes,
    });

    try {
      await notificationService.notifyStaffAndAdmins({
        title: 'Permintaan Survei Baru',
        message: `Pembeli telah mengajukan permintaan survei baru untuk properti: ${property.title}.`,
        type: 'survey',
        actionUrl: '/buyer-survey-requests',
      });
    } catch (_) {}

    return res.status(201).json({
      message: 'Permintaan survei berhasil diajukan',
      survey: buildSurveyPayload(survey),
    });
  } catch (error) {
    return next(error);
  }
}

async function listMySurveyRequests(req, res, next) {
  try {
    const surveys = await surveyService.findSurveyRequestsByBuyerId(req.user.sub);
    return res.status(200).json({
      message: 'Data permintaan survei berhasil diambil',
      surveys: surveys.map((item) => buildSurveyPayload(item)),
    });
  } catch (error) {
    return next(error);
  }
}

async function listSurveyRequestsForMarketing(req, res, next) {
  try {
    const rawStatus = normalizeStatus(req.query.status);
    const status = rawStatus && VALID_STATUSES.has(rawStatus) ? rawStatus : null;
    const surveys = await surveyService.findSurveyRequestsForMarketing({ status });

    return res.status(200).json({
      message: 'Data pengajuan survei berhasil diambil',
      surveys: surveys.map((item) => buildSurveyPayload(item)),
    });
  } catch (error) {
    return next(error);
  }
}

async function updateSurveyRequestStatus(req, res, next) {
  try {
    const surveyId = validateSurveyRequestId(req.params.id);
    const payload = validateStatusUpdateBody(req.body);
    const survey = await surveyService.findSurveyRequestById(surveyId);

    if (!survey) {
      throw createError('Permintaan survei tidak ditemukan', 404);
    }

    // State transition validations
    if (payload.status === 'approved' || payload.status === 'rejected') {
      if (survey.status !== 'pending') {
        throw createError('Hanya permintaan survei yang masih menunggu yang dapat disetujui atau ditolak', 400);
      }
    } else if (payload.status === 'completed') {
      if (survey.status !== 'approved') {
        throw createError('Hanya permintaan survei yang sudah disetujui yang dapat diselesaikan', 400);
      }
    }

    const updatedSurvey = await surveyService.updateSurveyRequestStatus({
      id: surveyId,
      status: payload.status,
      approvedScheduleDate: payload.approvedScheduleDate,
      approvedScheduleTime: payload.approvedScheduleTime,
      rejectionReason: payload.rejectionReason,
      processedByUserId: req.user.sub,
    });

    // send notification to buyer
    await _notifySurveyStatusChange(updatedSurvey);

    return res.status(200).json({
      message: payload.status === 'approved'
        ? 'Permintaan survei berhasil disetujui'
        : (payload.status === 'completed'
           ? 'Permintaan survei berhasil diselesaikan'
           : 'Permintaan survei berhasil ditolak'),
      survey: buildSurveyPayload(updatedSurvey),
    });
  } catch (error) {
    return next(error);
  }
}

// Notify buyer about status change
async function _notifySurveyStatusChange(updatedSurvey) {
  try {
    if (!updatedSurvey) return;
    const userId = updatedSurvey.buyer_user_id;
    const status = String(updatedSurvey.status || '').toLowerCase();
    let title = 'Status survei diperbarui';
    let message = 'Status permintaan survei Anda telah diperbarui. Cek detail untuk informasi lebih lanjut.';

    if (status === 'approved') {
      title = 'Survei Disetujui';
      message = 'Permintaan survei Anda telah disetujui oleh staf.';
    } else if (status === 'completed') {
      title = 'Survei Selesai';
      message = 'Survei properti Anda telah selesai dilaksanakan.';
    } else if (status === 'rejected') {
      title = 'Survei Ditolak';
      message = 'Permintaan survei Anda ditolak. Silakan ajukan ulang jika diperlukan.';
    } else if (status === 'cancelled') {
      title = 'Survei Dibatalkan';
      message = 'Permintaan survei Anda telah dibatalkan.';
    }

    await notificationService.createNotification({
      userId,
      title,
      message,
      type: 'survey',
      actionUrl: '/buyer-survey-requests',
    });
  } catch (_) {}
}

async function cancelSurveyRequest(req, res, next) {
  try {
    const surveyId = validateSurveyRequestId(req.params.id);
    const survey = await surveyService.findSurveyRequestById(surveyId);

    if (!survey) {
      throw createError('Permintaan survei tidak ditemukan', 404);
    }

    if (survey.buyer_user_id !== req.user.sub) {
      throw createError('Tidak dapat membatalkan permintaan survei ini', 403);
    }

    if (survey.status === 'cancelled' || survey.status === 'rejected') {
      throw createError('Survei ini sudah dibatalkan atau ditolak', 400);
    }

    const cancelledSurvey = await surveyService.cancelSurveyRequest({
      id: surveyId,
      cancelledByUserId: req.user.sub,
    });

    await _notifySurveyStatusChange(cancelledSurvey);

    return res.status(200).json({
      message: 'Permintaan survei berhasil dibatalkan',
      survey: buildSurveyPayload(cancelledSurvey),
    });
  } catch (error) {
    return next(error);
  }
}

async function updateSurveyRequest(req, res, next) {
  try {
    const surveyId = validateSurveyRequestId(req.params.id);
    const { requestedDate, requestedTime, notes } = validateCreateBody({
      ...req.body,
      propertyId: 1 // dummy to bypass propertyId validation, we don't update propertyId
    });

    const survey = await surveyService.findSurveyRequestById(surveyId);

    if (!survey) {
      throw createError('Permintaan survei tidak ditemukan', 404);
    }

    if (survey.buyer_user_id !== req.user.sub) {
      throw createError('Tidak dapat mengubah permintaan survei ini', 403);
    }

    if (survey.status === 'approved') {
      throw createError('Survei yang sudah disetujui tidak dapat diubah', 400);
    }

    if (survey.status === 'cancelled') {
      throw createError('Survei yang sudah dibatalkan tidak dapat diubah', 400);
    }

    const updatedSurvey = await surveyService.updateSurveyRequest({
      id: surveyId,
      requestedDate,
      requestedTime,
      notes,
    });

    // notify staff that buyer updated a request
    try {
      await notificationService.createNotification({
        userId: req.user.sub,
        title: 'Jadwal survei diperbarui',
        message: 'Pengajuan jadwal survei telah diperbarui.',
        type: 'survey',
        actionUrl: '/marketing-survey-requests',
      });
    } catch (_) {}

    return res.status(200).json({
      message: 'Permintaan survei berhasil diubah',
      survey: buildSurveyPayload(updatedSurvey),
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  createSurveyRequest,
  listMySurveyRequests,
  listSurveyRequestsForMarketing,
  updateSurveyRequestStatus,
  cancelSurveyRequest,
  updateSurveyRequest,
};
