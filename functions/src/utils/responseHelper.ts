import { Response } from 'express';

/**
 * Ortak yanıt formatı yardımcı fonksiyonları
 * Tüm API yanıtlarını standardize eder
 */

interface PaginationInfo {
  page?: number;
  limit?: number;
  total?: number;
  totalPages?: number;
  hasNext?: boolean;
  hasPrev?: boolean;
  nextCursor?: string;
  prevCursor?: string;
}

interface ValidationError {
  path?: string;
  param?: string;
  msg: string;
  value?: any;
}

/**
 * Başarılı yanıt formatı
 * @param res - Express response objesi
 * @param data - Döndürülecek veri
 * @param message - Başarı mesajı (opsiyonel)
 * @param statusCode - HTTP status kodu (varsayılan: 200)
 * @param meta - Ek meta bilgileri (opsiyonel)
 */
const successResponse = (res: Response, data: any, message?: string, statusCode: number = 200, meta?: any) => {
  const response: any = {
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
 * @param res - Express response objesi
 * @param error - Hata mesajı
 * @param statusCode - HTTP status kodu
 * @param details - Hata detayları (opsiyonel)
 */
const errorResponse = (res: Response, error: string, statusCode: number = 500, details?: any) => {
  const response: any = {
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
 * @param res - Express response objesi
 * @param validationErrors - Validation hataları array'i
 */
const validationErrorResponse = (res: Response, validationErrors: ValidationError[]) => {
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
 * @param res - Express response objesi
 * @param data - Döndürülecek veri array'i
 * @param pagination - Sayfalama bilgileri
 * @param message - Başarı mesajı (opsiyonel)
 */
const paginatedResponse = (res: Response, data: any[], pagination: PaginationInfo, message?: string) => {
  const response: any = {
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
 * @param res - Express response objesi
 * @param message - Hata mesajı (opsiyonel)
 */
const unauthorizedResponse = (res: Response, message: string = 'Yetkilendirme hatası') => {
  return errorResponse(res, message, 401);
};

/**
 * Erişim reddedildi yanıtı
 * @param res - Express response objesi
 * @param message - Hata mesajı (opsiyonel)
 */
const forbiddenResponse = (res: Response, message: string = 'Erişim reddedildi') => {
  return errorResponse(res, message, 403);
};

/**
 * Kaynak bulunamadı yanıtı
 * @param res - Express response objesi
 * @param message - Hata mesajı (opsiyonel)
 */
const notFoundResponse = (res: Response, message: string = 'Kaynak bulunamadı') => {
  return errorResponse(res, message, 404);
};

/**
 * Çakışma hatası yanıtı
 * @param res - Express response objesi
 * @param message - Hata mesajı (opsiyonel)
 */
const conflictResponse = (res: Response, message: string = 'Çakışma hatası') => {
  return errorResponse(res, message, 409);
};

/**
 * Sunucu hatası yanıtı
 * @param res - Express response objesi
 * @param message - Hata mesajı (opsiyonel)
 */
const serverErrorResponse = (res: Response, message: string = 'Sunucu hatası') => {
  return errorResponse(res, message, 500);
};

/**
 * Özel yanıt formatı
 * @param res - Express response objesi
 * @param statusCode - HTTP status kodu
 * @param success - Başarı durumu
 * @param data - Döndürülecek veri
 * @param error - Hata mesajı
 * @param extra - Ek bilgiler
 */
const customResponse = (res: Response, statusCode: number, success: boolean, data: any = null, error: string | null = null, extra: any = {}) => {
  const response = {
    success,
    data,
    error,
    timestamp: new Date().toISOString(),
    ...extra
  };

  return res.status(statusCode).json(response);
};

export {
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
