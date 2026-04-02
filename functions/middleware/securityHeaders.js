const helmet = require('helmet');
const functions = require('firebase-functions/v1');

// Güvenlik header'ları middleware'i
const securityHeaders = (req, res, next) => {
  // CORS güvenliği
  const allowedOrigins = [
    'https://biletsokagi.com',
    'https://www.biletsokagi.com',
    'https://biletsokagi.web.app',
    'https://biletsokagi.firebaseapp.com'
  ];
  
  // Development ortamında localhost'a izin ver
  if (process.env.NODE_ENV === 'development') {
    allowedOrigins.push('http://localhost:3000', 'http://localhost:8080');
  }
  
  const origin = req.headers.origin;
  if (allowedOrigins.includes(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
  }
  
  // Temel güvenlik header'ları
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'SAMEORIGIN');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  res.setHeader('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
  
  // Content Security Policy
  const cspDirectives = {
    defaultSrc: ["'self'"],
    scriptSrc: ["'self'", "'unsafe-inline'", 'https://apis.google.com', 'https://www.gstatic.com'],
    styleSrc: ["'self'", "'unsafe-inline'", 'https://fonts.googleapis.com'],
    fontSrc: ["'self'", 'https://fonts.gstatic.com'],
    imgSrc: ["'self'", 'data:', 'https:', 'blob:'],
    connectSrc: ["'self'", 'https://*.googleapis.com', 'https://*.firebaseio.com', 'wss://*.firebaseio.com'],
    objectSrc: ["'none'"],
    mediaSrc: ["'self'"],
    frameSrc: ["'self'", 'https://www.paytr.com'],
    upgradeInsecureRequests: []
  };
  
  const csp = Object.entries(cspDirectives)
    .map(([key, values]) => {
      const directive = key.replace(/([A-Z])/g, '-$1').toLowerCase();
      return values.length > 0 ? `${directive} ${values.join(' ')}` : directive;
    })
    .join('; ');
  
  res.setHeader('Content-Security-Policy', csp);
  
  // HSTS (HTTP Strict Transport Security)
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains; preload');
  
  // API güvenlik header'ları
  res.setHeader('X-API-Version', '1.0.0');
  res.setHeader('X-RateLimit-Policy', 'https://biletsokagi.com/api/rate-limits');
  
  // Request ID ekleme (debugging ve loglama için)
  const requestId = req.headers['x-request-id'] || generateRequestId();
  req.requestId = requestId;
  res.setHeader('X-Request-ID', requestId);
  
  next();
};

// Advanced security middleware with Helmet
const advancedSecurityHeaders = () => {
  return helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'", "'unsafe-inline'", 'https://apis.google.com', 'https://www.gstatic.com'],
        styleSrc: ["'self'", "'unsafe-inline'", 'https://fonts.googleapis.com'],
        fontSrc: ["'self'", 'https://fonts.gstatic.com'],
        imgSrc: ["'self'", 'data:', 'https:', 'blob:'],
        connectSrc: ["'self'", 'https://*.googleapis.com', 'https://*.firebaseio.com', 'wss://*.firebaseio.com'],
        objectSrc: ["'none'"],
        mediaSrc: ["'self'"],
        frameSrc: ["'self'", 'https://www.paytr.com'],
        upgradeInsecureRequests: [],
      },
    },
    hsts: {
      maxAge: 31536000,
      includeSubDomains: true,
      preload: true,
    },
    referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
    permissionsPolicy: {
      features: {
        camera: ["'none'"],
        microphone: ["'none'"],
        geolocation: ["'none'"],
        payment: ["'self'"],
        usb: ["'none'"],
      },
    },
  });
};

// Request ID generator
function generateRequestId() {
  return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
}

// IP filtering middleware
const ipFilter = (allowedIPs = [], blockedIPs = []) => {
  return (req, res, next) => {
    const clientIP = req.headers['x-forwarded-for']?.split(',')[0]?.trim() || 
                     req.socket.remoteAddress || 
                     'unknown';
    
    // Blocked IP kontrolü
    if (blockedIPs.length > 0 && blockedIPs.includes(clientIP)) {
      functions.logger.warn('Blocked IP attempted access', {
        ip: clientIP,
        path: req.path,
        method: req.method,
        timestamp: new Date().toISOString()
      });
      
      return res.status(403).json({
        success: false,
        error: 'ACCESS_DENIED',
        message: 'Access denied from your IP address',
        timestamp: new Date().toISOString()
      });
    }
    
    // Allowed IP kontrolü (eğer liste varsa)
    if (allowedIPs.length > 0 && !allowedIPs.includes(clientIP)) {
      functions.logger.warn('Non-whitelisted IP attempted access', {
        ip: clientIP,
        path: req.path,
        method: req.method,
        timestamp: new Date().toISOString()
      });
      
      return res.status(403).json({
        success: false,
        error: 'ACCESS_DENIED',
        message: 'Access restricted to whitelisted IPs only',
        timestamp: new Date().toISOString()
      });
    }
    
    next();
  };
};

// API key validation middleware
const apiKeyAuth = (validKeys = []) => {
  return (req, res, next) => {
    const apiKey = req.headers['x-api-key'] || req.query.apiKey;
    
    if (!apiKey) {
      return res.status(401).json({
        success: false,
        error: 'API_KEY_MISSING',
        message: 'API key is required',
        timestamp: new Date().toISOString()
      });
    }
    
    if (!validKeys.includes(apiKey)) {
      functions.logger.warn('Invalid API key attempt', {
        apiKey: apiKey.substring(0, 8) + '...',
        ip: req.headers['x-forwarded-for'] || req.socket.remoteAddress,
        path: req.path,
        timestamp: new Date().toISOString()
      });
      
      return res.status(401).json({
        success: false,
        error: 'API_KEY_INVALID',
        message: 'Invalid API key',
        timestamp: new Date().toISOString()
      });
    }
    
    // API key'i request'e ekle
    req.apiKey = apiKey;
    next();
  };
};

module.exports = {
  securityHeaders,
  advancedSecurityHeaders,
  ipFilter,
  apiKeyAuth,
  generateRequestId
};

