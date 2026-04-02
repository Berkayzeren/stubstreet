"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.customResponse = exports.serverErrorResponse = exports.conflictResponse = exports.notFoundResponse = exports.forbiddenResponse = exports.unauthorizedResponse = exports.paginatedResponse = exports.validationErrorResponse = exports.errorResponse = exports.successResponse = void 0;
/**
 * Başarılı yanıt formatı
 * @param res - Express response objesi
 * @param data - Döndürülecek veri
 * @param message - Başarı mesajı (opsiyonel)
 * @param statusCode - HTTP status kodu (varsayılan: 200)
 * @param meta - Ek meta bilgileri (opsiyonel)
 */
const successResponse = (res, data, message, statusCode = 200, meta) => {
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
exports.successResponse = successResponse;
/**
 * Hata yanıtı formatı
 * @param res - Express response objesi
 * @param error - Hata mesajı
 * @param statusCode - HTTP status kodu
 * @param details - Hata detayları (opsiyonel)
 */
const errorResponse = (res, error, statusCode = 500, details) => {
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
exports.errorResponse = errorResponse;
/**
 * Validation hatası yanıtı
 * @param res - Express response objesi
 * @param validationErrors - Validation hataları array'i
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
exports.validationErrorResponse = validationErrorResponse;
/**
 * Sayfalama ile başarılı yanıt
 * @param res - Express response objesi
 * @param data - Döndürülecek veri array'i
 * @param pagination - Sayfalama bilgileri
 * @param message - Başarı mesajı (opsiyonel)
 */
const paginatedResponse = (res, data, pagination, message) => {
    const response = {
        success: true,
        data,
        error: null,
        pagination: Object.assign(Object.assign({ page: pagination.page || 1, limit: pagination.limit || 10, total: pagination.total || data.length, totalPages: pagination.totalPages || Math.ceil((pagination.total || data.length) / (pagination.limit || 10)), hasNext: pagination.hasNext || false, hasPrev: pagination.hasPrev || false }, (pagination.nextCursor && { nextCursor: pagination.nextCursor })), (pagination.prevCursor && { prevCursor: pagination.prevCursor })),
        timestamp: new Date().toISOString()
    };
    if (message) {
        response.message = message;
    }
    return res.status(200).json(response);
};
exports.paginatedResponse = paginatedResponse;
/**
 * Yetkilendirme hatası yanıtı
 * @param res - Express response objesi
 * @param message - Hata mesajı (opsiyonel)
 */
const unauthorizedResponse = (res, message = 'Yetkilendirme hatası') => {
    return errorResponse(res, message, 401);
};
exports.unauthorizedResponse = unauthorizedResponse;
/**
 * Erişim reddedildi yanıtı
 * @param res - Express response objesi
 * @param message - Hata mesajı (opsiyonel)
 */
const forbiddenResponse = (res, message = 'Erişim reddedildi') => {
    return errorResponse(res, message, 403);
};
exports.forbiddenResponse = forbiddenResponse;
/**
 * Kaynak bulunamadı yanıtı
 * @param res - Express response objesi
 * @param message - Hata mesajı (opsiyonel)
 */
const notFoundResponse = (res, message = 'Kaynak bulunamadı') => {
    return errorResponse(res, message, 404);
};
exports.notFoundResponse = notFoundResponse;
/**
 * Çakışma hatası yanıtı
 * @param res - Express response objesi
 * @param message - Hata mesajı (opsiyonel)
 */
const conflictResponse = (res, message = 'Çakışma hatası') => {
    return errorResponse(res, message, 409);
};
exports.conflictResponse = conflictResponse;
/**
 * Sunucu hatası yanıtı
 * @param res - Express response objesi
 * @param message - Hata mesajı (opsiyonel)
 */
const serverErrorResponse = (res, message = 'Sunucu hatası') => {
    return errorResponse(res, message, 500);
};
exports.serverErrorResponse = serverErrorResponse;
/**
 * Özel yanıt formatı
 * @param res - Express response objesi
 * @param statusCode - HTTP status kodu
 * @param success - Başarı durumu
 * @param data - Döndürülecek veri
 * @param error - Hata mesajı
 * @param extra - Ek bilgiler
 */
const customResponse = (res, statusCode, success, data = null, error = null, extra = {}) => {
    const response = Object.assign({ success,
        data,
        error, timestamp: new Date().toISOString() }, extra);
    return res.status(statusCode).json(response);
};
exports.customResponse = customResponse;
//# sourceMappingURL=responseHelper.js.map