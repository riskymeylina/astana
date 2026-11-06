const fs = require('fs');
const path = require('path');
const pool = require('../config/db');

function normalizeTextFilter(value) {
  const text = String(value || '').trim();
  return text.length > 0 ? text : null;
}

function normalizeNumberFilter(value) {
  const number = Number(value);
  return Number.isFinite(number) && number >= 0 ? number : null;
}

async function findAllAvailableProperties({
  q,
  category,
  brand,
  minPrice,
  maxPrice,
  status,
  sortBy,
} = {}) {
  const conditions = [];
  const params = [];

  // Status Filter
  const statusFilter = normalizeTextFilter(status);
  if (statusFilter && ['Tersedia', 'Sedang Dibooking', 'Terjual'].includes(statusFilter)) {
    conditions.push('status = ?');
    params.push(statusFilter);
  } else {
    conditions.push("status IN ('Tersedia', 'Sedang Dibooking', 'Terjual')");
  }

  const keyword = normalizeTextFilter(q);
  const categoryFilter = normalizeTextFilter(category || brand);
  const minPriceFilter = normalizeNumberFilter(minPrice);
  const maxPriceFilter = normalizeNumberFilter(maxPrice);

  if (keyword) {
    conditions.push(
      `(title LIKE ? OR category LIKE ? OR location LIKE ?)`,
    );
    const keywordParam = `%${keyword}%`;
    params.push(keywordParam, keywordParam, keywordParam);
  }

  if (categoryFilter) {
    const categories = categoryFilter
      .split(',')
      .map((item) => item.trim())
      .filter(Boolean);
    if (categories.length === 1) {
      conditions.push('category = ?');
      params.push(categories[0]);
    } else if (categories.length > 1) {
      conditions.push(`category IN (${categories.map(() => '?').join(', ')})`);
      params.push(...categories);
    }
  }

  if (minPriceFilter !== null) {
    conditions.push('price >= ?');
    params.push(minPriceFilter);
  }

  if (maxPriceFilter !== null) {
    conditions.push('price <= ?');
    params.push(maxPriceFilter);
  }

  let orderBy = 'id_property ASC';
  if (sortBy) {
    if (sortBy === 'latest') {
      orderBy = 'created_at DESC, id_property DESC';
    } else if (sortBy === 'price_low') {
      orderBy = 'price ASC, id_property ASC';
    } else if (sortBy === 'price_high') {
      orderBy = 'price DESC, id_property DESC';
    }
  }

  const [rows] = await pool.execute(
    `SELECT id_property AS id, title, category, location, status, price, created_at, updated_at,
            (SELECT image_url FROM property_gallery_images WHERE property_id = properties.id_property ORDER BY sort_order ASC, id_property_gallery_image ASC LIMIT 1) AS image_url
     FROM properties
     WHERE ${conditions.join(' AND ')}
     ORDER BY ${orderBy}`,
    params,
  );

  return rows;
}

async function findAvailablePropertyFilters() {
  const [categoryRows] = await pool.execute(
    `SELECT DISTINCT category
     FROM properties
     WHERE status IN ('Tersedia', 'Sedang Dibooking', 'Terjual') AND category IS NOT NULL AND category <> ''
     ORDER BY category ASC`,
  );

  return {
    brands: categoryRows.map((row) => row.category).filter(Boolean),
    sizes: [], // building_area is dropped
  };
}

async function findPropertyById(id) {
  const [rows] = await pool.execute(
    `SELECT id_property AS id, title, category, location, status, price, created_at, updated_at,
            (SELECT image_url FROM property_gallery_images WHERE property_id = properties.id_property ORDER BY sort_order ASC, id_property_gallery_image ASC LIMIT 1) AS image_url
     FROM properties
     WHERE id_property = ?
     LIMIT 1`,
    [id],
  );

  return rows[0] || null;
}

async function findAllProperties() {
  const [rows] = await pool.execute(
    `SELECT id_property AS id, title, category, location, status, price, created_at, updated_at,
            (SELECT image_url FROM property_gallery_images WHERE property_id = properties.id_property ORDER BY sort_order ASC, id_property_gallery_image ASC LIMIT 1) AS image_url
     FROM properties
     ORDER BY updated_at DESC, id_property DESC`,
  );

  return rows;
}

async function createProperty(data) {
  const [result] = await pool.execute(
    `INSERT INTO properties (
       title, category, location, status, price
     ) VALUES (?, ?, ?, ?, ?)`,
    [
      data.title,
      data.category,
      data.location,
      data.status || 'Tersedia',
      data.price,
    ],
  );

  return findPropertyById(result.insertId);
}

async function updateProperty(id, data) {
  await pool.execute(
    `UPDATE properties
     SET title = ?,
         category = ?,
         location = ?,
         status = ?,
         price = ?,
         updated_at = CURRENT_TIMESTAMP
     WHERE id_property = ?`,
    [
      data.title,
      data.category,
      data.location,
      data.status,
      data.price,
      id,
    ],
  );

  return findPropertyById(id);
}

async function updatePropertyStatus(id, status) {
  await pool.execute(
    `UPDATE properties
     SET status = ?,
         updated_at = CURRENT_TIMESTAMP
     WHERE id_property = ?`,
    [status, id],
  );

  return findPropertyById(id);
}

async function deleteProperty(id) {
  await pool.execute(
    `DELETE FROM properties
     WHERE id_property = ?`,
    [id],
  );

  return null;
}

async function findPropertyGalleryByPropertyId(id) {
  try {
    const [rows] = await pool.execute(
      `SELECT id_property_gallery_image AS id, property_id, image_url, title, subtitle, detail_primary, detail_secondary, sort_order
       FROM property_gallery_images
       WHERE property_id = ?
       ORDER BY sort_order ASC, id_property_gallery_image ASC`,
      [id],
    );

    return rows;
  } catch (error) {
    if (error && error.code === 'ER_NO_SUCH_TABLE') {
      console.warn('[property] gallery table missing, returning empty gallery', { propertyId: id });
      return [];
    }

    throw error;
  }
}

async function addImage(propertyId, imageUrl, displayOrder, isPrimary) {
  const [result] = await pool.execute(
    "INSERT INTO property_gallery_images (property_id, image_url, sort_order, title, subtitle, detail_primary, detail_secondary) VALUES (?, ?, ?, ?, ?, ?, ?)",
    [propertyId, imageUrl, displayOrder || 1, "Foto", "", "", ""]
  );
  return {
    id: result.insertId,
    propertyId,
    imageUrl,
    displayOrder
  };
}

async function findImageById(imageId) {
  const [rows] = await pool.execute(
    "SELECT id_property_gallery_image AS id, property_id, image_url, sort_order as display_order FROM property_gallery_images WHERE id_property_gallery_image = ?",
    [imageId]
  );
  return rows[0] || null;
}

async function deleteImage(imageId) {
  const [rows] = await pool.execute(
    "SELECT image_url FROM property_gallery_images WHERE id_property_gallery_image = ?",
    [imageId]
  );
  const imageUrl = rows[0] && rows[0].image_url;

  await pool.execute("DELETE FROM property_gallery_images WHERE id_property_gallery_image = ?", [imageId]);

  if (imageUrl && imageUrl.startsWith('/uploads/')) {
    const uploadsRoot = path.join(__dirname, '..', '..', 'uploads');
    const filePath = path.join(uploadsRoot, imageUrl.replace(/^\/uploads\//, ''));
    try {
      fs.unlinkSync(filePath);
    } catch (err) {
      if (err.code !== 'ENOENT') {
        console.warn('[property] gagal menghapus file gambar', { filePath, message: err.message });
      }
    }
  }
}

async function setPrimaryImage(imageId, propertyId) {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    await conn.execute("UPDATE property_gallery_images SET sort_order = sort_order + 1 WHERE property_id = ?", [propertyId]);
    await conn.execute("UPDATE property_gallery_images SET sort_order = 1 WHERE id_property_gallery_image = ?", [imageId]);
    await conn.commit();
  } catch (error) {
    await conn.rollback();
    throw error;
  } finally {
    conn.release();
  }
}

async function updatePropertyStatus(propertyId, status) {
  await pool.execute(
    'UPDATE properties SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id_property = ?',
    [status, propertyId]
  );
  return findPropertyById(propertyId);
}
module.exports = {
  updatePropertyStatus,
  findAllAvailableProperties,
  findAvailablePropertyFilters,
  findAllProperties,
  findPropertyById,
  findPropertyGalleryByPropertyId,
  createProperty,
  updateProperty,
  deleteProperty,
  addImage,
  findImageById,
  deleteImage,
  setPrimaryImage,
};
