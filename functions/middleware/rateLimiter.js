const admin = require('firebase-admin');
const functions = require('firebase-functions/v1');

// Rate limit veritabanı
const rateLimitDb = new Map();

// Rate limit kuralları
const RATE_LIMITS = {
  // Genel API limitleri
  default: {
    windowMs: 60 * 1000, // 1 dakika
    maxRequests: 60, // Dakikada maksimum 60 istek
    message: 'Çok fazla istek gönderdiniz. Lütfen biraz bekleyin.'
  },
  
  // Ticket oluşturma için özel limit
  ticketCreation: {
    windowMs: 60 * 60 * 1000, // 1 saat
    maxRequests: 10, // Saatte maksimum 10 bilet
    message: 'Çok fazla bilet oluşturuyorsunuz. Lütfen 1 saat bekleyin.'
  },
  
  // Mesaj gönderme limiti
  messaging: {
    windowMs: 60 * 1000, // 1 dakika
    maxRequests: 30, // Dakikada maksimum 30 mesaj
    message: 'Çok hızlı mesaj gönderiyorsunuz. Lütfen yavaşlayın.'
  },
  
  // Payment işlemleri için limit
  payment: {
    windowMs: 60 * 60 * 1000, // 1 saat
    maxRequests: 20, // Saatte maksimum 20 ödeme denemesi
    message: 'Çok fazla ödeme denemesi yaptınız. Lütfen daha sonra tekrar deneyin.'
  },
  
  // Login denemesi limiti
  auth: {
    windowMs: 15 * 60 * 1000, // 15 dakika
    maxRequests: 5, // 15 dakikada maksimum 5 deneme
    message: 'Çok fazla giriş denemesi yaptınız. Lütfen 15 dakika bekleyin.'
  }
};

// IP bazlı rate limiting için Firestore kullanımı
const getRateLimitDocRef = (ip, endpoint) => {
  return admin.firestore()
    .collection('rateLimits')
    .doc(`${ip}_${endpoint}`);
};

// Rate limit kontrolü
const checkRateLimit = async (ip, endpoint, userId = null) => {
  const now = Date.now();
  const limit = RATE_LIMITS[endpoint] || RATE_LIMITS.default;
  
  // Kullanıcı bazlı rate limit key
  const key = userId ? `user_${userId}_${endpoint}` : `ip_${ip}_${endpoint}`;
  
  // Memory cache kontrolü
  if (rateLimitDb.has(key)) {
    const record = rateLimitDb.get(key);
    
    // Pencere süresi dolmuşsa sıfırla
    if (now - record.firstRequest > limit.windowMs) {
      record.firstRequest = now;
      record.requests = 1;
    } else {
      record.requests++;
    }
    
    if (record.requests > limit.maxRequests) {
      return {
        allowed: false,
        retryAfter: Math.ceil((record.firstRequest + limit.windowMs - now) / 1000),
        message: limit.message
      };
    }
  } else {
    // Yeni kayıt oluştur
    rateLimitDb.set(key, {
      firstRequest: now,
      requests: 1
    });
  }
  
  // Firestore'da kalıcı kayıt için (kritik endpoint'ler için)
  if (['ticketCreation', 'payment', 'auth'].includes(endpoint)) {
    try {
      const docRef = getRateLimitDocRef(ip, endpoint);
      const doc = await docRef.get();
      
      if (doc.exists) {
        const data = doc.data();
        const timePassed = now - data.timestamp;
        
        if (timePassed < limit.windowMs) {
          if (data.requests >= limit.maxRequests) {
            // Şüpheli aktivite logla
            functions.logger.warn('Rate limit exceeded', {
              ip,
              endpoint,
              userId,
              requests: data.requests,
              timestamp: new Date().toISOString()
            });
            
            return {
              allowed: false,
              retryAfter: Math.ceil((limit.windowMs - timePassed) / 1000),
              message: limit.message
            };
          }
          
          // Request sayısını artır
          await docRef.update({
            requests: admin.firestore.FieldValue.increment(1),
            lastRequest: now
          });
        } else {
          // Yeni pencere başlat
          await docRef.set({
            timestamp: now,
            requests: 1,
            lastRequest: now,
            ip,
            userId: userId || null
          });
        }
      } else {
        // İlk istek
        await docRef.set({
          timestamp: now,
          requests: 1,
          lastRequest: now,
          ip,
          userId: userId || null
        });
      }
    } catch (error) {
      functions.logger.error('Rate limit Firestore error:', error);
      // Hata durumunda güvenli tarafta kal
    }
  }
  
  return { allowed: true };
};

// Middleware fonksiyonu
const rateLimiter = (endpoint = 'default') => {
  return async (req, res, next) => {
    try {
      // IP adresini al
      const ip = req.headers['x-forwarded-for']?.split(',')[0]?.trim() || 
                 req.socket.remoteAddress || 
                 'unknown';
      
      // User ID'yi al (varsa)
      const userId = req.user?.uid || null;
      
      // Bot detection - basit user-agent kontrolü
      const userAgent = req.headers['user-agent'] || '';
      const suspiciousAgents = [
        'bot', 'crawler', 'spider', 'scraper', 'curl', 'wget',
        'python-requests', 'axios', 'node-fetch'
      ];
      
      if (suspiciousAgents.some(agent => userAgent.toLowerCase().includes(agent))) {
        functions.logger.warn('Suspicious user agent detected', {
          ip,
          userAgent,
          endpoint,
          timestamp: new Date().toISOString()
        });
        
        // Bot'lar için daha sıkı limit
        endpoint = 'bot';
        if (!RATE_LIMITS.bot) {
          RATE_LIMITS.bot = {
            windowMs: 60 * 60 * 1000, // 1 saat
            maxRequests: 10, // Saatte maksimum 10 istek
            message: 'Bot aktivitesi tespit edildi. Erişim sınırlandı.'
          };
        }
      }
      
      // Rate limit kontrolü
      const result = await checkRateLimit(ip, endpoint, userId);
      
      if (!result.allowed) {
        // Rate limit header'ları ekle
        res.set({
          'X-RateLimit-Limit': RATE_LIMITS[endpoint]?.maxRequests || RATE_LIMITS.default.maxRequests,
          'X-RateLimit-Remaining': 0,
          'X-RateLimit-Reset': new Date(Date.now() + (result.retryAfter * 1000)).toISOString(),
          'Retry-After': result.retryAfter
        });
        
        // 429 Too Many Requests
        return res.status(429).json({
          success: false,
          error: 'RATE_LIMIT_EXCEEDED',
          message: result.message,
          retryAfter: result.retryAfter,
          timestamp: new Date().toISOString()
        });
      }
      
      // İstek geçti, devam et
      next();
    } catch (error) {
      functions.logger.error('Rate limiter error:', error);
      // Hata durumunda isteği geçir ama logla
      next();
    }
  };
};

// Memory temizleme (her 5 dakikada bir)
setInterval(() => {
  const now = Date.now();
  const maxAge = 60 * 60 * 1000; // 1 saat
  
  for (const [key, record] of rateLimitDb.entries()) {
    if (now - record.firstRequest > maxAge) {
      rateLimitDb.delete(key);
    }
  }
}, 5 * 60 * 1000);

module.exports = { rateLimiter, checkRateLimit, RATE_LIMITS };

