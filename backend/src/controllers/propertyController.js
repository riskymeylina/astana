const propertyService = require('../services/propertyService');
const notificationService = require('../services/notificationService');

function createError(message, statusCode) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

function parsePropertyListQuery(query) {
  return {
    q: query.q,
    category: query.category,
    brand: query.brand,
    minPrice: query.minPrice,
    maxPrice: query.maxPrice,
    status: query.status,
    sortBy: query.sortBy,
  };
}

function validatePropertyId(value) {
  const id = Number.parseInt(String(value || ''), 10);

  if (!Number.isInteger(id) || id <= 0) {
    throw createError('ID properti tidak valid', 400);
  }

  return id;
}

function requiredString(value, fieldName) {
  const text = String(value ?? '').trim();
  if (!text) {
    throw createError(`${fieldName} wajib diisi`, 400);
  }
  return text;
}

function validatePropertyBody(body) {
  const price = Number(body.price);
  if (!Number.isFinite(price) || price < 0) {
    throw createError('Harga properti tidak valid', 400);
  }

  const status = String(body.status || 'Tersedia').trim();
  const validStatuses = new Set(['Tersedia', 'Sedang Dibooking', 'Terjual']);
  if (!validStatuses.has(status)) {
    throw createError('Status properti tidak valid', 400);
  }

  return {
    title: requiredString(body.title, 'Judul properti'),
    category: requiredString(body.category, 'Kategori'),
    location: requiredString(body.location, 'Lokasi'),
    price,
    status,
  };
}

function validatePropertyStatusBody(body) {
  const status = String(body.status || '').trim();
  const validStatuses = new Set(['Tersedia', 'Sedang Dibooking', 'Terjual']);
  if (!validStatuses.has(status)) {
    throw createError('Status properti tidak valid. Pilih: Tersedia, Sedang Dibooking, atau Terjual', 400);
  }
  return { status };
}

async function updatePropertyStatus(req, res, next) {
  try {
    const propertyId = validatePropertyId(req.params.id);
    const existing = await propertyService.findPropertyById(propertyId);
    if (!existing) {
      throw createError('Properti tidak ditemukan', 404);
    }

    const { status } = validatePropertyStatusBody(req.body);
    const property = await propertyService.updatePropertyStatus(propertyId, status);

    return res.status(200).json({
      message: 'Status properti berhasil diperbarui',
      property: buildPropertyPayload(req, property),
    });
  } catch (error) {
    return next(error);
  }
}

function buildPropertyPayload(req, property) {
  const imageUrl = property.image_url;
  const gallery = imageUrl ? [
    {
      id: 0,
      imageUrl: imageUrl.startsWith('http') ? imageUrl : `${req.protocol}://${req.get('host')}${imageUrl}`,
      title: '',
      subtitle: '',
      details: []
    }
  ] : [];

  return {
    id: property.id,
    title: property.title,
    category: property.category,
    location: property.location,
    price: property.price,
    status: property.status,
    statusLabel: property.status,
    gallery,
    createdAt: property.created_at ? new Date(property.created_at).toISOString() : null,
    updatedAt: property.updated_at ? new Date(property.updated_at).toISOString() : null,
  };
}

function buildGalleryPayload(req, item) {
  return {
    id: item.id,
    imageUrl: item.image_url ? (item.image_url.startsWith('http') ? item.image_url : `${req.protocol}://${req.get('host')}${item.image_url}`) : null,
    title: item.title,
    subtitle: item.subtitle,
    details: [item.detail_primary, item.detail_secondary].filter(
      (detail) => typeof detail === 'string' && detail.trim().length > 0,
    ),
  };
}

async function listProperties(req, res, next) {
  try {
    const filters = parsePropertyListQuery(req.query);
    console.info('[property] list request started', filters);
    const properties = await propertyService.findAllAvailableProperties(filters);

    console.info('[property] list request completed', {
      count: properties.length,
    });

    return res.status(200).json({
      message: 'Data properti berhasil diambil',
      properties: properties.map((property) => buildPropertyPayload(req, property)),
    });
  } catch (error) {
    return next(error);
  }
}

async function listPropertyFilters(req, res, next) {
  try {
    const filters = await propertyService.findAvailablePropertyFilters();
    return res.status(200).json({
      message: 'Filter properti berhasil diambil',
      filters,
    });
  } catch (error) {
    return next(error);
  }
}

async function listAdminProperties(req, res, next) {
  try {
    const properties = await propertyService.findAllProperties();
    return res.status(200).json({
      message: 'Data properti admin berhasil diambil',
      properties: properties.map((property) => buildPropertyPayload(req, property)),
    });
  } catch (error) {
    return next(error);
  }
}

async function createAdminProperty(req, res, next) {
  try {
    const payload = validatePropertyBody(req.body);
    const property = await propertyService.createProperty(payload);

    try {
      await notificationService.notifyAllBuyers({
        title: 'Properti Baru Dirilis!',
        message: `Properti baru tersedia untuk Anda: ${property.title} di lokasi ${property.location}.`,
        type: 'property',
        actionUrl: '/home',
      });
    } catch (_) {}

    return res.status(201).json({
      message: 'Properti berhasil ditambahkan',
      property: buildPropertyPayload(req, property),
    });
  } catch (error) {
    return next(error);
  }
}

async function updateAdminProperty(req, res, next) {
  try {
    const propertyId = validatePropertyId(req.params.id);
    const existing = await propertyService.findPropertyById(propertyId);
    if (!existing) {
      throw createError('Properti tidak ditemukan', 404);
    }

    const payload = validatePropertyBody(req.body);
    const property = await propertyService.updateProperty(propertyId, payload);

    return res.status(200).json({
      message: 'Properti berhasil diperbarui',
      property: buildPropertyPayload(req, property),
    });
  } catch (error) {
    return next(error);
  }
}

async function deleteAdminProperty(req, res, next) {
  try {
    const propertyId = validatePropertyId(req.params.id);
    const existing = await propertyService.findPropertyById(propertyId);
    if (!existing) {
      throw createError('Properti tidak ditemukan', 404);
    }

    await propertyService.deleteProperty(propertyId);

    return res.status(200).json({
      message: 'Properti berhasil dihapus',
      property: buildPropertyPayload(req, existing),
    });
  } catch (error) {
    return next(error);
  }
}

async function updatePropertyStatus(req, res, next) {
  try {
    const propertyId = validatePropertyId(req.params.id);
    const existing = await propertyService.findPropertyById(propertyId);
    if (!existing) {
      throw createError('Properti tidak ditemukan', 404);
    }

    const { status } = req.body;
    if (!status || !['Tersedia', 'Sedang Dibooking', 'Terjual'].includes(status)) {
      throw createError('Status tidak valid. Pilih: Tersedia, Sedang Dibooking, Terjual', 400);
    }

    const updated = await propertyService.updatePropertyStatus(propertyId, status);

    return res.status(200).json({
      message: 'Status properti berhasil diperbarui',
      property: buildPropertyPayload(req, updated || { ...existing, status }),
    });
  } catch (error) {
    return next(error);
  }
}

async function getPropertyDetail(req, res, next) {
  try {
    const propertyId = validatePropertyId(req.params.id);
    console.info('[property] detail request started', { propertyId });
    const property = await propertyService.findPropertyById(propertyId);

    if (!property) {
      console.info('[property] detail request not found', { propertyId });
      throw createError('Properti tidak ditemukan', 404);
    }

    const galleryItems = await propertyService.findPropertyGalleryByPropertyId(propertyId);

    console.info('[property] detail request completed', {
      propertyId,
      galleryCount: galleryItems.length,
    });

    return res.status(200).json({
      message: 'Detail properti berhasil diambil',
      property: {
        ...buildPropertyPayload(req, property),
        gallery: galleryItems.map((item) => buildGalleryPayload(req, item)),
      },
    });
  } catch (error) {
    return next(error);
  }
}

async function uploadImagesTemp(req, res, next) {
  try {
    if (!req.files || req.files.length === 0) {
      throw createError('Tidak ada file yang diunggah', 400);
    }
    const uploadedImages = req.files.map(file => ({
      imageUrl: `/uploads/properties/${file.filename}`,
      originalName: file.originalname,
    }));
    return res.status(200).json({
      message: 'Gambar berhasil diunggah sementara',
      images: uploadedImages
    });
  } catch (error) {
    return next(error);
  }
}

async function uploadImagesToProperty(req, res, next) {
  try {
    const propertyId = validatePropertyId(req.params.id);
    const existing = await propertyService.findPropertyById(propertyId);
    if (!existing) {
      throw createError('Properti tidak ditemukan', 404);
    }
    if (!req.files || req.files.length === 0) {
      throw createError('Tidak ada file yang diunggah', 400);
    }

    const savedImages = [];
    for (let i = 0; i < req.files.length; i++) {
      const file = req.files[i];
      const imageUrl = `/uploads/properties/property-${propertyId}/${file.filename}`;
      const image = await propertyService.addImage(propertyId, imageUrl, i + 1, false);
      savedImages.push(image);
    }

    return res.status(200).json({
      message: 'Gambar berhasil ditambahkan ke properti',
      images: savedImages
    });
  } catch (error) {
    return next(error);
  }
}

async function deleteImage(req, res, next) {
  try {
    const imageId = validatePropertyId(req.params.imageId);
    const image = await propertyService.findImageById(imageId);
    if (!image) {
      throw createError('Gambar tidak ditemukan', 404);
    }
    
    await propertyService.deleteImage(imageId);
    
    return res.status(200).json({
      message: 'Gambar berhasil dihapus'
    });
  } catch (error) {
    return next(error);
  }
}

async function setPrimaryImage(req, res, next) {
  try {
    const imageId = validatePropertyId(req.params.imageId);
    const image = await propertyService.findImageById(imageId);
    if (!image) {
      throw createError('Gambar tidak ditemukan', 404);
    }
    
    await propertyService.setPrimaryImage(imageId, image.property_id);
    
    return res.status(200).json({
      message: 'Gambar utama berhasil diatur'
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  listProperties,
  listPropertyFilters,
  listAdminProperties,
  createAdminProperty,
  updateAdminProperty,
  deleteAdminProperty,
  getPropertyDetail,
  updatePropertyStatus,
  uploadImagesTemp,
  uploadImagesToProperty,
  deleteImage,
  setPrimaryImage,
};
