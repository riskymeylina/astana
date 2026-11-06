const pool = require('../config/db');

async function createSurveyRequest({ buyerUserId, propertyId, requestedDate, requestedTime, notes }) {
  const [result] = await pool.execute(
    `INSERT INTO survey_requests (
      buyer_user_id,
      property_id,
      requested_date,
      requested_time,
      notes,
      status
    ) VALUES (?, ?, ?, ?, ?, 'pending')`,
    [buyerUserId, propertyId, requestedDate, requestedTime, notes],
  );

  return findSurveyRequestById(result.insertId);
}

async function findSurveyRequestsByBuyerId(buyerUserId) {
  const [rows] = await pool.execute(
     `SELECT sr.id_survey, sr.buyer_user_id, sr.property_id,
            DATE_FORMAT(sr.requested_date, '%Y-%m-%d') AS requested_date,
            TIME_FORMAT(sr.requested_time, '%H:%i') AS requested_time,
            sr.notes, sr.status,
            DATE_FORMAT(sr.approved_schedule_date, '%Y-%m-%d') AS approved_schedule_date,
            TIME_FORMAT(sr.approved_schedule_time, '%H:%i') AS approved_schedule_time,
            sr.rejection_reason, sr.processed_by_user_id, sr.processed_at,
            sr.created_at, sr.updated_at,
            p.title AS property_title, p.location AS property_location,
            (SELECT image_url FROM property_gallery_images WHERE property_id = p.id_property ORDER BY sort_order ASC, id_property_gallery_image ASC LIMIT 1) AS property_image_url,
            buyer.name AS buyer_name,
            buyer.phone AS buyer_phone,
            buyer.email AS buyer_email,
            processor.name AS processed_by_name,
            processor.phone AS processed_by_phone
     FROM survey_requests sr
     INNER JOIN properties p ON p.id_property = sr.property_id
     INNER JOIN users buyer ON buyer.id_user = sr.buyer_user_id
     LEFT JOIN users processor ON processor.id_user = sr.processed_by_user_id
     WHERE sr.buyer_user_id = ?
     ORDER BY FIELD(sr.status, 'pending', 'approved', 'completed', 'rejected'), sr.requested_date ASC, sr.id_survey DESC`,
    [buyerUserId],
  );

  return rows;
}

async function findSurveyRequestsForMarketing({ status } = {}) {
  const params = [];
  const conditions = [];

  if (status) {
    conditions.push('sr.status = ?');
    params.push(status);
  }

  const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
  const [rows] = await pool.execute(
     `SELECT sr.id_survey, sr.buyer_user_id, sr.property_id,
            DATE_FORMAT(sr.requested_date, '%Y-%m-%d') AS requested_date,
            TIME_FORMAT(sr.requested_time, '%H:%i') AS requested_time,
            sr.notes, sr.status,
            DATE_FORMAT(sr.approved_schedule_date, '%Y-%m-%d') AS approved_schedule_date,
            TIME_FORMAT(sr.approved_schedule_time, '%H:%i') AS approved_schedule_time,
            sr.rejection_reason, sr.processed_by_user_id, sr.processed_at,
            sr.created_at, sr.updated_at,
            p.title AS property_title, p.location AS property_location,
            (SELECT image_url FROM property_gallery_images WHERE property_id = p.id_property ORDER BY sort_order ASC, id_property_gallery_image ASC LIMIT 1) AS property_image_url,
            buyer.name AS buyer_name,
            buyer.phone AS buyer_phone,
            buyer.email AS buyer_email,
            processor.name AS processed_by_name,
            processor.phone AS processed_by_phone
     FROM survey_requests sr
     INNER JOIN properties p ON p.id_property = sr.property_id
     INNER JOIN users buyer ON buyer.id_user = sr.buyer_user_id
     LEFT JOIN users processor ON processor.id_user = sr.processed_by_user_id
     ${whereClause}
     ORDER BY COALESCE(sr.approved_schedule_date, sr.requested_date) ASC,
              FIELD(sr.status, 'pending', 'approved', 'completed', 'rejected'),
              sr.id_survey DESC`,
    params,
  );

  return rows;
}

async function findSurveyRequestById(id) {
  const [rows] = await pool.execute(
     `SELECT sr.id_survey, sr.buyer_user_id, sr.property_id,
            DATE_FORMAT(sr.requested_date, '%Y-%m-%d') AS requested_date,
            TIME_FORMAT(sr.requested_time, '%H:%i') AS requested_time,
            sr.notes, sr.status,
            DATE_FORMAT(sr.approved_schedule_date, '%Y-%m-%d') AS approved_schedule_date,
            TIME_FORMAT(sr.approved_schedule_time, '%H:%i') AS approved_schedule_time,
            sr.rejection_reason, sr.processed_by_user_id, sr.processed_at,
            sr.created_at, sr.updated_at,
            p.title AS property_title, p.location AS property_location,
            (SELECT image_url FROM property_gallery_images WHERE property_id = p.id_property ORDER BY sort_order ASC, id_property_gallery_image ASC LIMIT 1) AS property_image_url,
            buyer.name AS buyer_name,
            buyer.phone AS buyer_phone,
            buyer.email AS buyer_email,
            processor.name AS processed_by_name,
            processor.phone AS processed_by_phone
     FROM survey_requests sr
     INNER JOIN properties p ON p.id_property = sr.property_id
     INNER JOIN users buyer ON buyer.id_user = sr.buyer_user_id
     LEFT JOIN users processor ON processor.id_user = sr.processed_by_user_id
     WHERE sr.id_survey = ?
     LIMIT 1`,
    [id],
  );

  return rows[0] || null;
}

async function findPropertyById(propertyId) {
  const [rows] = await pool.execute(
    `SELECT id_property AS id, title, location, status
     FROM properties
     WHERE id_property = ?
     LIMIT 1`,
    [propertyId],
  );

  return rows[0] || null;
}

async function updateSurveyRequestStatus({
  id,
  status,
  approvedScheduleDate,
  approvedScheduleTime,
  rejectionReason,
  processedByUserId,
}) {
  if (status === 'approved') {
    await pool.execute(
      `UPDATE survey_requests
       SET status = 'approved',
           approved_schedule_date = ?,
           approved_schedule_time = ?,
           rejection_reason = NULL,
           processed_by_user_id = ?,
           processed_at = NOW()
       WHERE id_survey = ?`,
      [approvedScheduleDate, approvedScheduleTime, processedByUserId, id],
    );
  } else if (status === 'completed') {
    await pool.execute(
      `UPDATE survey_requests
       SET status = 'completed',
           rejection_reason = NULL,
           processed_by_user_id = ?,
           processed_at = NOW()
       WHERE id_survey = ?`,
      [processedByUserId, id],
    );
  } else {
    await pool.execute(
      `UPDATE survey_requests
       SET status = 'rejected',
           approved_schedule_date = NULL,
           approved_schedule_time = NULL,
           rejection_reason = ?,
           processed_by_user_id = ?,
           processed_at = NOW()
       WHERE id_survey = ?`,
      [rejectionReason, processedByUserId, id],
    );
  }

  return findSurveyRequestById(id);
}

async function cancelSurveyRequest({ id, cancelledByUserId }) {
  await pool.execute(
    `UPDATE survey_requests
     SET status = 'cancelled',
         rejection_reason = NULL,
         processed_by_user_id = ?,
         processed_at = NOW()
     WHERE id_survey = ?`,
    [cancelledByUserId, id],
  );

  return findSurveyRequestById(id);
}

async function updateSurveyRequest({ id, requestedDate, requestedTime, notes }) {
  await pool.execute(
    `UPDATE survey_requests
     SET requested_date = ?,
         requested_time = ?,
         notes = ?,
         status = 'pending',
         rejection_reason = NULL,
         approved_schedule_date = NULL,
         approved_schedule_time = NULL
     WHERE id_survey = ?`,
    [requestedDate, requestedTime, notes, id],
  );

  return findSurveyRequestById(id);
}

module.exports = {
  createSurveyRequest,
  findSurveyRequestsByBuyerId,
  findSurveyRequestsForMarketing,
  findSurveyRequestById,
  findPropertyById,
  updateSurveyRequestStatus,
  cancelSurveyRequest,
  updateSurveyRequest,
};
