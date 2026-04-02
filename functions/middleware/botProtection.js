const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const axios = require('axios');

// Bot detection patterns
const BOT_PATTERNS = {
  userAgent: [
    // Kötü niyetli botlar
    /bot/i, /crawler/i, /spider/i, /scraper/i, /headless/i,
    /phantomjs/i, /selenium/i, /puppeteer/i, /playwright/i,
    
    // Otomatik araçlar
    /curl/i, /wget/i, /python-requests/i, /axios/i, /node-fetch/i,
    /postman/i, /insomnia/i, /httpie/i,
    
    // Bilinen kötü botlar
    /ahrefsbot/i, /semrushbot/i, /dotbot/i, /mj12bot/i,
    /blexbot/i, /yandexbot/i, /bingbot/i, /slurp/i
  ],
  
  // Şüpheli davranış patternleri
  suspiciousBehavior: {
    rapidRequests: 10, // 1 saniyede 10'dan fazla istek
    identicalRequests: 5, // Aynı endpoint'e 5 ardışık istek
    noReferer: true, // Referer header'ı yok
    invalidHeaders: true, // Eksik veya geçersiz header'lar
  }
};

// Google reCAPTCHA doğrulama
const verifyRecaptcha = async (token, action = 'submit') => {
  const secretKey = process.env.RECAPTCHA_SECRET_KEY || functions.config().recaptcha?.secret_key;
  
  if (!secretKey) {
    functions.logger.warn('reCAPTCHA secret key not configured');
    return { success: false, error: 'reCAPTCHA not configured' };
  }
  
  try {
    const response = await axios.post(
      'https://www.google.com/recaptcha/api/siteverify',
      null,
      {
        params: {
          secret: secretKey,
          response: token
        }
      }
    );
    
    const data = response.data;
    
    // reCAPTCHA v3 için score kontrolü
    if (data.success && data.score) {
      if (data.score < 0.5) {
        functions.logger.warn('Low reCAPTCHA score', {
          score: data.score,
          action: data.action,
          hostname: data.hostname
        });
        return { success: false, score: data.score, error: 'Low trust score' };
      }
    }
    
    return { success: data.success, score: data.score };
  } catch (error) {
    functions.logger.error('reCAPTCHA verification error:', error);
    return { success: false, error: error.message };
  }
};

// Request pattern analizi için memory store
const requestPatterns = new Map();

// Bot detection middleware
const botProtection = (options = {}) => {
  const {
    enableCaptcha = false,
    captchaThreshold = 0.5,
    blockKnownBots = true,
    logSuspiciousActivity = true,
    customBotPatterns = []
  } = options;
  
  return async (req, res, next) => {
    try {
      const userAgent = req.headers['user-agent'] || '';
      const ip = req.headers['x-forwarded-for']?.split(',')[0]?.trim() || 
                 req.socket.remoteAddress || 
                 'unknown';
      const referer = req.headers['referer'] || '';
      const requestTime = Date.now();
      
      // 1. User-Agent kontrolü
      const allBotPatterns = [...BOT_PATTERNS.userAgent, ...customBotPatterns];
      const isBot = allBotPatterns.some(pattern => pattern.test(userAgent));
      
      if (isBot && blockKnownBots) {
        if (logSuspiciousActivity) {
          functions.logger.warn('Bot detected via User-Agent', {
            ip,
            userAgent,
            path: req.path,
            method: req.method,
            timestamp: new Date().toISOString()
          });
        }
        
        return res.status(403).json({
          success: false,
          error: 'BOT_DETECTED',
          message: 'Automated access detected',
          timestamp: new Date().toISOString()
        });
      }
      
      // 2. Request pattern analizi
      const patternKey = `${ip}_${req.path}`;
      const patterns = requestPatterns.get(patternKey) || [];
      patterns.push(requestTime);
      
      // Son 1 dakikadaki istekleri filtrele
      const recentPatterns = patterns.filter(time => requestTime - time < 60000);
      requestPatterns.set(patternKey, recentPatterns);
      
      // Hızlı istek kontrolü (1 saniyede 10'dan fazla)
      const oneSecondAgo = requestTime - 1000;
      const rapidRequests = recentPatterns.filter(time => time > oneSecondAgo).length;
      
      if (rapidRequests > BOT_PATTERNS.suspiciousBehavior.rapidRequests) {
        if (logSuspiciousActivity) {
          functions.logger.warn('Rapid requests detected', {
            ip,
            path: req.path,
            requestCount: rapidRequests,
            timestamp: new Date().toISOString()
          });
        }
        
        // CAPTCHA challenge
        if (enableCaptcha && !req.headers['x-recaptcha-token']) {
          return res.status(429).json({
            success: false,
            error: 'CAPTCHA_REQUIRED',
            message: 'Please complete the CAPTCHA challenge',
            challenge: {
              type: 'recaptcha_v3',
              siteKey: process.env.RECAPTCHA_SITE_KEY || functions.config().recaptcha?.site_key
            },
            timestamp: new Date().toISOString()
          });
        }
      }
      
      // 3. Header analizi
      const hasValidHeaders = 
        req.headers['accept'] &&
        req.headers['accept-language'] &&
        (req.headers['referer'] || req.headers['origin']);
      
      if (!hasValidHeaders && !isBot) {
        if (logSuspiciousActivity) {
          functions.logger.warn('Missing standard headers', {
            ip,
            headers: Object.keys(req.headers),
            path: req.path,
            timestamp: new Date().toISOString()
          });
        }
      }
      
      // 4. CAPTCHA doğrulama (eğer token varsa)
      if (enableCaptcha && req.headers['x-recaptcha-token']) {
        const captchaResult = await verifyRecaptcha(
          req.headers['x-recaptcha-token'],
          req.path
        );
        
        if (!captchaResult.success || (captchaResult.score && captchaResult.score < captchaThreshold)) {
          return res.status(403).json({
            success: false,
            error: 'CAPTCHA_FAILED',
            message: 'CAPTCHA verification failed',
            timestamp: new Date().toISOString()
          });
        }
        
        // CAPTCHA başarılı, güven skorunu kaydet
        req.trustScore = captchaResult.score;
      }
      
      // 5. Honeypot field kontrolü (form submission'lar için)
      if (req.body && req.body._honeypot) {
        if (logSuspiciousActivity) {
          functions.logger.warn('Honeypot triggered', {
            ip,
            path: req.path,
            honeypotValue: req.body._honeypot,
            timestamp: new Date().toISOString()
          });
        }
        
        // Honeypot doldurulmuş, bu bir bot
        return res.status(403).json({
          success: false,
          error: 'BOT_DETECTED',
          message: 'Automated submission detected',
          timestamp: new Date().toISOString()
        });
      }
      
      // Request metadata ekle
      req.botProtection = {
        isBot,
        trustScore: req.trustScore || (isBot ? 0 : 1),
        rapidRequests,
        hasValidHeaders,
        timestamp: requestTime
      };
      
      next();
    } catch (error) {
      functions.logger.error('Bot protection error:', error);
      // Hata durumunda isteği geçir
      next();
    }
  };
};

// Memory temizleme (her 10 dakikada bir)
setInterval(() => {
  const now = Date.now();
  const maxAge = 60 * 60 * 1000; // 1 saat
  
  for (const [key, patterns] of requestPatterns.entries()) {
    const validPatterns = patterns.filter(time => now - time < maxAge);
    if (validPatterns.length === 0) {
      requestPatterns.delete(key);
    } else {
      requestPatterns.set(key, validPatterns);
    }
  }
}, 10 * 60 * 1000);

// Firestore'da bot aktivitesi loglama
const logBotActivity = async (req, type, details) => {
  try {
    await admin.firestore().collection('botActivity').add({
      type,
      ip: req.headers['x-forwarded-for']?.split(',')[0]?.trim() || req.socket.remoteAddress,
      userAgent: req.headers['user-agent'],
      path: req.path,
      method: req.method,
      details,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
  } catch (error) {
    functions.logger.error('Failed to log bot activity:', error);
  }
};

module.exports = {
  botProtection,
  verifyRecaptcha,
  logBotActivity,
  BOT_PATTERNS
};

