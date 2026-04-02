/**
 * Ortak yanıt formatı yardımcı fonksiyonları
 * Tüm API yanıtlarını standardize eder
 */

/**
 * Başarılı yanıt formatı
 * @param {Object} res - Express response objesi
 * @param {*} data - Döndürülecek veri
 * @param {string} message - Başarı mesajı (opsiyonel)
 * @param {number} statusCode - HTTP status kodu (varsayılan: 200)
 * @param {Object} meta - Ek meta bilgileri (opsiyonel)
 */
const successResponse = (res, data, message = null, statusCode = 200, meta = null) => {
  const response = {
    success: true,
    data,
    error: null,
    timestamp: new Date().toISOString()
  };

  if (message) {
    response.message = message;
  }

  if (meta) {
    response.meta = meta;
  }

  return res.status(statusCode).json(response);
};

/**
 * Hata yanıtı formatı
 * @param {Object} res - Express response objesi
 * @param {string} error - Hata mesajı
 * @param {number} statusCode - HTTP status kodu
 * @param {*} details - Hata detayları (opsiyonel)
 */
const errorResponse = (res, error, statusCode = 500, details = null) => {
  const response = {
    success: false,
    data: null,
    error,
    timestamp: new Date().toISOString()
  };

  if (details) {
    response.details = details;
  }

  return res.status(statusCode).json(response);
};

/**
 * Validation hatası yanıtı
 * @param {Object} res - Express response objesi
 * @param {Array} validationErrors - Validation hataları array'i
 */
const validationErrorResponse = (res, validationErrors) => {
  return res.status(422).json({
    success: false,
    data: null,
    error: 'Validation hatası',
    details: validationErrors.map(error => ({
      field: error.path || error.param,
      message: error.msg,
      value: error.value
    })),
    timestamp: new Date().toISOString()
  });
};

/**
 * Sayfalama ile başarılı yanıt
 * @param {Object} res - Express response objesi
 * @param {Array} data - Döndürülecek veri array'i
 * @param {Object} pagination - Sayfalama bilgileri
 * @param {string} message - Başarı mesajı (opsiyonel)
 */
const paginatedResponse = (res, data, pagination, message = null) => {
  const response = {
    success: true,
    data,
    error: null,
    pagination: {
      page: pagination.page || 1,
      limit: pagination.limit || 10,
      total: pagination.total || data.length,
      totalPages: pagination.totalPages || Math.ceil((pagination.total || data.length) / (pagination.limit || 10)),
      hasNext: pagination.hasNext || false,
      hasPrev: pagination.hasPrev || false,
      ...(pagination.nextCursor && { nextCursor: pagination.nextCursor }),
      ...(pagination.prevCursor && { prevCursor: pagination.prevCursor })
    },
    timestamp: new Date().toISOString()
  };

  if (message) {
    response.message = message;
  }

  return res.status(200).json(response);
};

/**
 * Yetkilendirme hatası yanıtı
 * @param {Object} res - Express response objesi
 * @param {string} message - Hata mesajı (opsiyonel)
 */
const unauthorizedResponse = (res, message = 'Yetkilendirme hatası') => {
  return errorResponse(res, message, 401);
};

/**
 * Erişim reddedildi yanıtı
 * @param {Object} res - Express response objesi
 * @param {string} message - Hata mesajı (opsiyonel)
 */
const forbiddenResponse = (res, message = 'Erişim reddedildi') => {
  return errorResponse(res, message, 403);
};

/**
 * Kaynak bulunamadı yanıtı
 * @param {Object} res - Express response objesi
 * @param {string} message - Hata mesajı (opsiyonel)
 */
const notFoundResponse = (res, message = 'Kaynak bulunamadı') => {
  return errorResponse(res, message, 404);
};

/**
 * Çakışma hatası yanıtı
 * @param {Object} res - Express response objesi
 * @param {string} message - Hata mesajı (opsiyonel)
 */
const conflictResponse = (res, message = 'Çakışma hatası') => {
  return errorResponse(res, message, 409);
};

/**
 * Sunucu hatası yanıtı
 * @param {Object} res - Express response objesi
 * @param {string} message - Hata mesajı (opsiyonel)
 */
const serverErrorResponse = (res, message = 'Sunucu hatası') => {
  return errorResponse(res, message, 500);
};

/**
 * Özel yanıt formatı
 * @param {Object} res - Express response objesi
 * @param {number} statusCode - HTTP status kodu
 * @param {boolean} success - Başarı durumu
 * @param {*} data - Döndürülecek veri
 * @param {string} error - Hata mesajı
 * @param {Object} extra - Ek bilgiler
 */
const customResponse = (res, statusCode, success, data = null, error = null, extra = {}) => {
  const response = {
    success,
    data,
    error,
    timestamp: new Date().toISOString(),
    ...extra
  };

  return res.status(statusCode).json(response);
};

module.exports = {
  successResponse,
  errorResponse,
  validationErrorResponse,
  paginatedResponse,
  unauthorizedResponse,
  forbiddenResponse,
  notFoundResponse,
  conflictResponse,
  serverErrorResponse,
  customResponse
};
