# BİLET SOKAĞI - Güvenlik Hızlı Başlangıç Kılavuzu

## 🔒 Güvenlik Özellikleri Genel Bakış

### ✅ Implementasyon Tamamlanan Güvenlik Önlemleri

1. **DDoS Koruması**
   - Rate limiting (API ve Firestore seviyesi)
   - Bot detection
   - CAPTCHA entegrasyonu
   - IP blacklisting

2. **Authentication Güvenliği**
   - Secure token storage
   - Session management
   - Device fingerprinting
   - Login attempt tracking

3. **API Güvenliği**
   - Security headers
   - CORS kontrolü
   - API key rotation
   - Request validation

4. **Monitoring & Alerting**
   - Real-time security logs
   - Anomaly detection
   - Automated responses
   - Alert notifications

## 🚀 Hızlı Kurulum

### 1. Environment Variables (.env)
```bash
# Firebase
FIREBASE_PROJECT_ID=biletsokagi
FIREBASE_API_KEY=your-api-key
FIREBASE_AUTH_DOMAIN=biletsokagi.firebaseapp.com
FIREBASE_STORAGE_BUCKET=biletsokagi.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your-sender-id
FIREBASE_APP_ID=your-app-id

# reCAPTCHA
RECAPTCHA_SITE_KEY=your-site-key
RECAPTCHA_SECRET_KEY=your-secret-key

# Security
ENCRYPTION_KEY=your-32-char-encryption-key
SECURITY_WEBHOOK_URL=your-webhook-url

# PayTR
PAYTR_MERCHANT_ID=your-merchant-id
PAYTR_MERCHANT_KEY=your-merchant-key
PAYTR_MERCHANT_SALT=your-merchant-salt
```

### 2. Firebase Functions Deployment
```bash
cd functions
npm install
firebase functions:config:set \
  paytr.merchant_id="YOUR_MERCHANT_ID" \
  paytr.merchant_key="YOUR_MERCHANT_KEY" \
  paytr.merchant_salt="YOUR_MERCHANT_SALT" \
  recaptcha.site_key="YOUR_SITE_KEY" \
  recaptcha.secret_key="YOUR_SECRET_KEY"
firebase deploy --only functions
```

### 3. Firestore Security Rules Deployment
```bash
firebase deploy --only firestore:rules
```

### 4. Flutter App Configuration
```dart
// lib/config/security_config.dart
class SecurityConfig {
  static const String recaptchaSiteKey = 'YOUR_SITE_KEY';
  static const String apiBaseUrl = 'https://api.biletsokagi.com';
  static const bool enableFingerprinting = true;
  static const bool enableRateLimiting = true;
}
```

## 🛡️ Güvenlik Test Kontrol Listesi

### Rate Limiting Testleri
- [ ] API endpoint rate limiting (60 req/min)
- [ ] Ticket creation limiting (10/hour)
- [ ] Message sending limiting (30/min)
- [ ] Payment attempt limiting (20/hour)
- [ ] Login attempt limiting (5/15min)

### Bot Protection Testleri
- [ ] User-Agent filtering
- [ ] Request pattern analysis
- [ ] CAPTCHA challenges
- [ ] Honeypot fields

### Security Headers Testleri
- [ ] CORS validation
- [ ] CSP headers
- [ ] HSTS enabled
- [ ] X-Frame-Options set

### Firestore Rules Testleri
- [ ] Email verification required
- [ ] Rate limiting enforced
- [ ] Size restrictions (1MB max)
- [ ] Field count limits (50 max)
- [ ] Ban system working

## 📊 Monitoring Dashboard

### Security Metrics to Track
1. **Failed Login Attempts**
   - Threshold: 5 per 15 minutes
   - Action: Account lock

2. **Rate Limit Violations**
   - Threshold: 10 per 5 minutes
   - Action: IP blacklist

3. **Bot Detections**
   - Threshold: 5 per 15 minutes
   - Action: CAPTCHA challenge

4. **API Key Failures**
   - Threshold: 3 per 30 minutes
   - Action: Key revocation

## 🚨 Incident Response

### DDoS Attack Response
```bash
# 1. Enable Cloudflare Under Attack Mode
# 2. Tighten rate limits
firebase functions:config:set security.rate_limit_multiplier=0.5
# 3. Deploy emergency rules
firebase deploy --only functions,firestore:rules
```

### Suspicious Activity Response
```javascript
// Manually block an IP
await db.collection('blacklistedIPs').doc(suspiciousIP).set({
  ip: suspiciousIP,
  reason: 'Manual block - suspicious activity',
  blockedAt: new Date(),
  blockedUntil: new Date(Date.now() + 24*60*60*1000) // 24 hours
});

// Lock a user account
await auth.updateUser(userId, { disabled: true });
```

## 📱 Mobile App Security

### Flutter Security Checklist
- [ ] Secure storage initialized
- [ ] Device fingerprinting active
- [ ] Certificate pinning (optional)
- [ ] Obfuscation enabled for release
- [ ] ProGuard/R8 rules configured

### Build Commands
```bash
# Android release build with security
flutter build apk --release --obfuscate --split-debug-info=debug-info

# iOS release build with security
flutter build ios --release --obfuscate --split-debug-info=debug-info
```

## 🔗 Useful Links

- **Security Logs**: Firebase Console > Firestore > securityLogs
- **Rate Limits**: Firebase Console > Firestore > rateLimits
- **Blocked IPs**: Firebase Console > Firestore > blacklistedIPs
- **Bot Activity**: Firebase Console > Firestore > botActivity

## 📞 Emergency Contacts

- **Security Team**: security@biletsokagi.com
- **DevOps**: devops@biletsokagi.com
- **On-Call**: +90 XXX XXX XX XX

---

**Domain**: biletsokagi.com  
**App ID**: com.biletsokagi.app  
**Last Updated**: 2025-09-25  
**Version**: 1.0.0
