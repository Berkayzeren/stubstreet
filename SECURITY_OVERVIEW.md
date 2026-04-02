# 🔒 BİLET SOKAĞI - Güvenlik Genel Bakış

## Platform Bilgileri
- **Domain**: biletsokagi.com
- **App Package**: com.biletsokagi.app
- **Firebase Project**: biletsokagi

## Implementasyon Özeti

### ✅ Tamamlanan Güvenlik Önlemleri

#### 1. **DDoS ve Bot Koruması**
```javascript
// Rate Limiting Yapılandırması
- Genel API: 60 istek/dakika
- Bilet Oluşturma: 10 bilet/saat
- Mesajlaşma: 30 mesaj/dakika
- Ödeme İşlemleri: 20 deneme/saat
- Giriş Denemeleri: 5 deneme/15 dakika
```

#### 2. **Bot Detection**
- User-Agent analizi
- Request pattern tespiti
- CAPTCHA entegrasyonu
- Honeypot field'lar
- IP blacklisting

#### 3. **Security Headers**
```nginx
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000
Content-Security-Policy: [configured]
```

#### 4. **Firestore Security Rules**
- Email doğrulama zorunlu
- Rate limiting kontrolleri
- Max 1MB request size
- Max 50 field per document
- Spam önleme mekanizmaları

#### 5. **Monitoring & Alerting**
- Real-time security logs
- Anomaly detection
- Automated responses
- Alert notifications

## Kritik Dosyalar

### Backend (Functions)
- `functions/middleware/rateLimiter.js` - Rate limiting
- `functions/middleware/securityHeaders.js` - Security headers
- `functions/middleware/botProtection.js` - Bot detection
- `functions/middleware/authMiddleware.js` - Authentication
- `functions/src/services/securityMonitoringService.js` - Monitoring

### Frontend (Flutter)
- `lib/core/services/security_service.dart` - Security service
- Device fingerprinting
- Client-side rate limiting
- Secure storage implementation

### Configuration
- `firestore.rules` - Database security rules
- `DDOS_PROTECTION_GUIDE.md` - Cloudflare setup
- `API_SECURITY_POLICIES.md` - API security policies

## Quick Actions

### 🚨 Acil Durumlarda

#### DDoS Saldırısı
```bash
# 1. Cloudflare Under Attack Mode
# 2. Rate limit'leri sıkılaştır
firebase functions:config:set security.strict_mode=true
firebase deploy --only functions
```

#### Suspicious Activity
```javascript
// IP blacklist
db.collection('blacklistedIPs').doc(ip).set({
  ip: suspiciousIP,
  reason: 'Manual block',
  blockedUntil: new Date(Date.now() + 24*60*60*1000)
});
```

#### API Key Compromise
```bash
# Rotate keys immediately
node scripts/rotate-keys.js --emergency
```

## Monitoring Endpoints

### Security Logs
- **Collection**: `firestore/securityLogs`
- **Types**: FAILED_LOGIN, RATE_LIMIT_EXCEEDED, BOT_DETECTED, etc.

### Rate Limits
- **Collection**: `firestore/rateLimits`
- **Format**: `{userId}_{action}_writes`

### Blacklisted IPs
- **Collection**: `firestore/blacklistedIPs`
- **Auto-removal**: Configurable

## Test Commands

```bash
# Run security tests
./scripts/test_security.sh

# Check rate limiting
for i in {1..70}; do curl -H "Authorization: Bearer $TOKEN" https://api.biletsokagi.com/health; done

# Test bot detection
curl -H "User-Agent: bot" https://api.biletsokagi.com/health
```

## Production Checklist

- [ ] Cloudflare DNS configured
- [ ] SSL certificates active
- [ ] reCAPTCHA keys set
- [ ] Email alerts configured
- [ ] Monitoring dashboard active
- [ ] Backup strategy in place
- [ ] Incident response plan ready

## Support

- **Security Issues**: security@biletsokagi.com
- **Emergency**: +90 XXX XXX XX XX
- **Documentation**: /docs/security/

---

**Güvenlik Seviyesi**: Enterprise Grade 🛡️  
**Son Güncelleme**: 2025-09-25  
**Versiyon**: 1.0.0
