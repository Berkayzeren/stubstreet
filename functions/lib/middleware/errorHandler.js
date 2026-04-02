"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.asyncHandler = exports.notFoundHandler = exports.validationHandler = exports.errorHandler = void 0;
const express_validator_1 = require("express-validator");
/**
 * Global error handler middleware
 * Tüm hataları yakalar ve standart format ile döndürür
 */
const errorHandler = (err, req, res, next) => {
    console.error('Error caught by global handler:', err);
    // Validation hatalarını kontrol et
    const errors = (0, express_validator_1.validationResult)(req);
    if (!errors.isEmpty()) {
        return res.status(422).json({
            success: false,
            error: 'Validation hatası',
            details: errors.array().map(error => ({
                field: error.path || error.param,
                message: error.msg,
                value: error.value
            })),
            timestamp: new Date().toISOString()
        });
    }
    // Özel hata türlerini kontrol et
    if (err.name === 'ValidationError' && err.validationErrors) {
        return res.status(422).json({
            success: false,
            error: 'Validation hatası',
            details: err.validationErrors.map((error) => ({
                field: error.path || error.param,
                message: error.msg || error.message,
                value: error.value
            })),
            timestamp: new Date().toISOString()
        });
    }
    // Firebase Auth hatalarını kontrol et
    if (err.code && err.code.startsWith('auth/')) {
        return res.status(401).json({
            success: false,
            error: 'Yetkilendirme hatası',
            details: err.message,
            timestamp: new Date().toISOString()
        });
    }
    // Firestore hatalarını kontrol et
    if (err.code && (err.code.startsWith('firestore/') || err.code === 'not-found')) {
        const statusCode = err.code === 'not-found' ? 404 : 500;
        return res.status(statusCode).json({
            success: false,
            error: 'Veritabanı hatası',
            details: err.message,
            timestamp: new Date().toISOString()
        });
    }
    // Socket.IO hatalarını kontrol et
    if (err.message && err.message.includes('Socket')) {
        return res.status(500).json({
            success: false,
            error: 'WebSocket hatası',
            details: err.message,
            timestamp: new Date().toISOString()
        });
    }
    // HTTP status koduna göre hatalar
    const statusCode = err.status || err.statusCode || 500;
    let errorMessage = 'Sunucu hatası';
    let errorDetails = process.env.NODE_ENV === 'development' ? err.message : 'Bir hata oluştu';
    // Bilinen HTTP hata kodları
    switch (statusCode) {
        case 400:
            errorMessage = 'Hatalı istek';
            break;
        case 401:
            errorMessage = 'Yetkilendirme hatası';
            break;
        case 403:
            errorMessage = 'Erişim reddedildi';
            break;
        case 404:
            errorMessage = 'Kaynak bulunamadı';
            break;
        case 409:
            errorMessage = 'Çakışma hatası';
            break;
        case 422:
            errorMessage = 'Validation hatası';
            break;
        case 429:
            errorMessage = 'Çok fazla istek';
            break;
        case 500:
            errorMessage = 'Sunucu hatası';
            break;
        default:
            errorMessage = 'Bilinmeyen hata';
    }
    // Standart hata yanıtı
    res.status(statusCode).json(Object.assign({ success: false, error: errorMessage, details: errorDetails, timestamp: new Date().toISOString() }, (process.env.NODE_ENV === 'development' && { stack: err.stack })));
};
exports.errorHandler = errorHandler;
/**
 * Validation middleware - express-validator hatalarını yakalar
 */
const validationHandler = (req, res, next) => {
    const errors = (0, express_validator_1.validationResult)(req);
    if (!errors.isEmpty()) {
        const err = new Error('Validation hatası');
        err.status = 422;
        err.validationErrors = errors.array();
        return next(err);
    }
    next();
};
exports.validationHandler = validationHandler;
/**
 * 404 handler - Route bulunamadığında
 */
const notFoundHandler = (req, res, next) => {
    const err = new Error(`Route bulunamadı: ${req.method} ${req.path}`);
    err.status = 404;
    next(err);
};
exports.notFoundHandler = notFoundHandler;
/**
 * Async error wrapper - async fonksiyonlardaki hataları yakalar
 */
const asyncHandler = (fn) => {
    return (req, res, next) => {
        Promise.resolve(fn(req, res, next)).catch(next);
    };
};
exports.asyncHandler = asyncHandler;
//# sourceMappingURL=errorHandler.js.map