const { validationResult } = require('express-validator');
const functions = require('firebase-functions');
const admin = require('firebase-admin');

/**
 * Global error handler middleware
 * Tüm hataları yakalar ve standart format ile döndürür
 * İki sağlayıcı da başarısızsa kullanıcıya alternatif öner
 */
const errorHandler = (err, req, res, next) => {
  // Detaylı logging - Firebase Functions Logger kullan
  functions.logger.error('Error caught by global handler:', {
    error: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
    userAgent: req.get('User-Agent'),
    ip: req.ip,
    userId: req.user?.uid || 'anonymous',
    timestamp: new Date().toISOString()
  });

  console.error('Error caught by global handler:', err);

  // Validation hatalarını kontrol et
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({
      success: false,
      error: 'Validation hatası',
      details: errors.array().map(error => ({
        field: error.path,
        message: error.msg,
        value: error.value
      })),
      timestamp: new Date().toISOString()
    });
  }

  // Payment provider hatalarını kontrol et ve fallback öner
  if (err.code && err.code.includes('payment')) {
    functions.logger.error('Payment provider error detected:', {
      error: err.message,
      code: err.code,
      provider: err.provider,
      userId: req.user?.uid,
      timestamp: new Date().toISOString()
    });

    // Ödeme sağlayıcısı hata yönetimi
    return res.status(503).json({
      success: false,
      error: 'Ödeme sağlayıcısı geçici olarak kullanılamıyor',
      details: err.message,
      suggestion: {
        message: 'Alternatif ödeme yöntemi ile deneyiniz',
        alternativeProvider: alternativeProvider,
        retryAfter: 300 // 5 dakika
      },
      timestamp: new Date().toISOString()
    });
  }

  // Özel hata türlerini kontrol et
  if (err.name === 'ValidationError') {
    functions.logger.info('Validation error occurred:', {
      errors: Object.values(err.errors).map(error => ({
        field: error.path,
        message: error.message,
        value: error.value
      })),
      url: req.url,
      method: req.method,
      userId: req.user?.uid || 'anonymous'
    });

    return res.status(422).json({
      success: false,
      error: 'Validation hatası',
      details: Object.values(err.errors).map(error => ({
        field: error.path,
        message: error.message,
        value: error.value
      })),
      timestamp: new Date().toISOString()
    });
  }

  // Firebase Auth hatalarını kontrol et
  if (err.code && err.code.startsWith('auth/')) {
    functions.logger.warn('Firebase Auth error:', {
      code: err.code,
      message: err.message,
      url: req.url,
      method: req.method,
      userAgent: req.get('User-Agent'),
      ip: req.ip,
      timestamp: new Date().toISOString()
    });

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
    
    functions.logger.error('Firestore error:', {
      code: err.code,
      message: err.message,
      url: req.url,
      method: req.method,
      userId: req.user?.uid,
      timestamp: new Date().toISOString()
    });

    return res.status(statusCode).json({
      success: false,
      error: 'Veritabanı hatası',
      details: err.message,
      timestamp: new Date().toISOString()
    });
  }

  // Socket.IO hatalarını kontrol et
  if (err.message && err.message.includes('Socket')) {
    functions.logger.error('Socket.IO error:', {
      message: err.message,
      stack: err.stack,
      url: req.url,
      method: req.method,
      userId: req.user?.uid,
      timestamp: new Date().toISOString()
    });

    return res.status(500).json({
      success: false,
      error: 'WebSocket hatası',
      details: err.message,
      timestamp: new Date().toISOString()
    });
  }

  // Rate limiting hatalarını kontrol et
  if (err.code === 'RATE_LIMIT_EXCEEDED') {
    functions.logger.warn('Rate limit exceeded:', {
      ip: req.ip,
      url: req.url,
      method: req.method,
      userAgent: req.get('User-Agent'),
      userId: req.user?.uid,
      timestamp: new Date().toISOString()
    });

    return res.status(429).json({
      success: false,
      error: 'Çok fazla istek',
      details: 'Lütfen biraz bekleyip tekrar deneyin',
      retryAfter: 60,
      timestamp: new Date().toISOString()
    });
  }

  // Network timeout hatalarını kontrol et
  if (err.code === 'ECONNRESET' || err.code === 'ETIMEDOUT' || err.code === 'ENOTFOUND') {
    functions.logger.error('Network error:', {
      code: err.code,
      message: err.message,
      url: req.url,
      method: req.method,
      userId: req.user?.uid,
      timestamp: new Date().toISOString()
    });

    return res.status(503).json({
      success: false,
      error: 'Ağ bağlantısı hatası',
      details: 'Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin',
      suggestion: {
        message: 'Birkaç dakika sonra tekrar deneyin',
        retryAfter: 180
      },
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
  functions.logger.error('Unhandled error:', {
    statusCode,
    error: errorMessage,
    details: errorDetails,
    stack: err.stack,
    url: req.url,
    method: req.method,
    userId: req.user?.uid,
    timestamp: new Date().toISOString()
  });

  res.status(statusCode).json({
    success: false,
    error: errorMessage,
    details: errorDetails,
    timestamp: new Date().toISOString(),
    // Development ortamında stack trace ekle
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
};

/**
 * Validation middleware - express-validator hatalarını yakalar
 */
const validationHandler = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const err = new Error('Validation hatası');
    err.status = 422;
    err.validationErrors = errors.array();
    return next(err);
  }
  next();
};

/**
 * 404 handler - Route bulunamadığında
 */
const notFoundHandler = (req, res, next) => {
  const err = new Error(`Route bulunamadı: ${req.method} ${req.path}`);
  err.status = 404;
  next(err);
};

/**
 * Async error wrapper - async fonksiyonlardaki hataları yakalar
 */
const asyncHandler = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

module.exports = {
  errorHandler,
  validationHandler,
  notFoundHandler,
  asyncHandler
};
