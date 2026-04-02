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
declare const successResponse: (res: Response, data: any, message?: string, statusCode?: number, meta?: any) => Response<any, Record<string, any>>;
/**
 * Hata yanıtı formatı
 * @param res - Express response objesi
 * @param error - Hata mesajı
 * @param statusCode - HTTP status kodu
 * @param details - Hata detayları (opsiyonel)
 */
declare const errorResponse: (res: Response, error: string, statusCode?: number, details?: any) => Response<any, Record<string, any>>;
/**
 * Validation hatası yanıtı
 * @param res - Express response objesi
 * @param validationErrors - Validation hataları array'i
 */
declare const validationErrorResponse: (res: Response, validationErrors: ValidationError[]) => Response<any, Record<string, any>>;
/**
 * Sayfalama ile başarılı yanıt
 * @param res - Express response objesi
 * @param data - Döndürülecek veri array'i
 * @param pagination - Sayfalama bilgileri
 * @param message - Başarı mesajı (opsiyonel)
 */
declare const paginatedResponse: (res: Response, data: any[], pagination: PaginationInfo, message?: string) => Response<any, Record<string, any>>;
/**
 * Yetkilendirme hatası yanıtı
 * @param res - Express response objesi
 * @param message - Hata mesajı (opsiyonel)
 */
declare const unauthorizedResponse: (res: Response, message?: string) => Response<any, Record<string, any>>;
/**
 * Erişim reddedildi yanıtı
 * @param res - Express response objesi
 * @param message - Hata mesajı (opsiyonel)
 */
declare const forbiddenResponse: (res: Response, message?: string) => Response<any, Record<string, any>>;
/**
 * Kaynak bulunamadı yanıtı
 * @param res - Express response objesi
 * @param message - Hata mesajı (opsiyonel)
 */
declare const notFoundResponse: (res: Response, message?: string) => Response<any, Record<string, any>>;
/**
 * Çakışma hatası yanıtı
 * @param res - Express response objesi
 * @param message - Hata mesajı (opsiyonel)
 */
declare const conflictResponse: (res: Response, message?: string) => Response<any, Record<string, any>>;
/**
 * Sunucu hatası yanıtı
 * @param res - Express response objesi
 * @param message - Hata mesajı (opsiyonel)
 */
declare const serverErrorResponse: (res: Response, message?: string) => Response<any, Record<string, any>>;
/**
 * Özel yanıt formatı
 * @param res - Express response objesi
 * @param statusCode - HTTP status kodu
 * @param success - Başarı durumu
 * @param data - Döndürülecek veri
 * @param error - Hata mesajı
 * @param extra - Ek bilgiler
 */
declare const customResponse: (res: Response, statusCode: number, success: boolean, data?: any, error?: string | null, extra?: any) => Response<any, Record<string, any>>;
export { successResponse, errorResponse, validationErrorResponse, paginatedResponse, unauthorizedResponse, forbiddenResponse, notFoundResponse, conflictResponse, serverErrorResponse, customResponse };
