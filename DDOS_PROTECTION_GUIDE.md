# DDoS Koruması ve Cloudflare Entegrasyonu Rehberi

## Genel Bakış

Bu dokümantasyon, Bilet Sokağı platformunu DDoS (Distributed Denial of Service) saldırılarına karşı korumak için Cloudflare entegrasyonu ve diğer güvenlik önlemlerini açıklar.

## 1. Cloudflare Kurulumu

### 1.1 Cloudflare Hesabı Oluşturma
1. [Cloudflare.com](https://www.cloudflare.com) adresine gidin
2. Ücretsiz veya Pro plan seçin (Pro plan daha iyi DDoS koruması sağlar)
3. Domain'inizi (biletsokagi.com) Cloudflare'e ekleyin

### 1.2 DNS Ayarları
```bash
# Cloudflare DNS sunucularını kullanın
ns1.cloudflare.com
ns2.cloudflare.com
```

### 1.3 SSL/TLS Ayarları
- SSL mode: Full (strict)
- Always Use HTTPS: ON
- Minimum TLS Version: 1.2
- Automatic HTTPS Rewrites: ON

## 2. DDoS Koruması Katmanları

### 2.1 Cloudflare DDoS Protection (Otomatik)
- Layer 3/4 DDoS koruması (tüm planlarda)
- Layer 7 DDoS koruması (HTTP flood)
- Otomatik trafik analizi ve filtreleme

### 2.2 Rate Limiting Rules
```javascript
// Cloudflare Dashboard > Security > Rate Limiting
{
  "rule": {
    "expression": "(http.request.uri.path contains \"/api/\")",
    "action": "challenge",
    "threshold": 50,
    "period": 60,
    "characteristics": ["ip.src"]
  }
}
```

### 2.3 Firewall Rules
```javascript
// Kötü bot trafiğini engelle
(cf.client.bot) or 
(http.user_agent contains "bot" and not cf.verified_bot_category in {"good_bot"})

// Belirli ülkelerden gelen trafiği engelle (isteğe bağlı)
(ip.geoip.country in {"XX" "YY"})

// Şüpheli user agent'ları engelle
(http.user_agent contains "curl") or 
(http.user_agent contains "wget") or
(http.user_agent contains "python")
```

## 3. Firebase Integration

### 3.1 Firebase App Check
```javascript
// Firebase App Check ile Cloudflare entegrasyonu
import { initializeAppCheck, ReCaptchaV3Provider } from "firebase/app-check";

const appCheck = initializeAppCheck(app, {
  provider: new ReCaptchaV3Provider('YOUR_RECAPTCHA_SITE_KEY'),
  isTokenAutoRefreshEnabled: true
});
```

### 3.2 Cloud Functions Güvenliği
```javascript
// functions/src/middleware/cloudflareVerify.js
const verifyCloudflareHeaders = (req, res, next) => {
  // Cloudflare IP kontrolü
  const cfConnectingIP = req.headers['cf-connecting-ip'];
  const cfRay = req.headers['cf-ray'];
  
  if (!cfRay) {
    // İstek Cloudflare üzerinden gelmemiş
    return res.status(403).json({ error: 'Direct access not allowed' });
  }
  
  req.realIP = cfConnectingIP || req.ip;
  next();
};
```

## 4. Uygulama Seviyesi Korumalar

### 4.1 Rate Limiting (Implementasyonumuz)
```javascript
// Ticket oluşturma limiti
ticketCreation: {
  windowMs: 60 * 60 * 1000, // 1 saat
  maxRequests: 10, // Saatte maksimum 10 bilet
}

// Mesaj gönderme limiti
messaging: {
  windowMs: 60 * 1000, // 1 dakika
  maxRequests: 30, // Dakikada maksimum 30 mesaj
}

// Payment işlemleri limiti
payment: {
  windowMs: 60 * 60 * 1000, // 1 saat
  maxRequests: 20, // Saatte maksimum 20 ödeme denemesi
}
```

### 4.2 CAPTCHA Entegrasyonu
```javascript
// Frontend implementasyonu
import { ReCAPTCHA } from "react-google-recaptcha-v3";

const handleSubmit = async () => {
  const token = await executeRecaptcha("submit_form");
  
  const response = await fetch('/api/endpoint', {
    headers: {
      'X-ReCaptcha-Token': token
    }
  });
};
```

## 5. Cloudflare Page Rules

### 5.1 API Endpoint Koruması
```
URL: api.biletsokagi.com/*
Settings:
- Security Level: High
- Browser Integrity Check: ON
- Challenge Passage: 30 minutes
```

### 5.2 Static Asset Caching
```
URL: *.biletsokagi.com/assets/*
Settings:
- Cache Level: Cache Everything
- Edge Cache TTL: 1 month
- Browser Cache TTL: 1 week
```

## 6. Monitoring ve Alerting

### 6.1 Cloudflare Analytics
- Traffic Analytics
- Security Events
- Rate Limiting Analytics
- Bot Analytics

### 6.2 Alert Kurulumu
```javascript
// Cloudflare Notifications
{
  "alert_type": "ddos_attack_l7_alert",
  "enabled": true,
  "notification_email": "security@biletsokagi.com"
}
```

### 6.3 Firebase Monitoring
```javascript
// Cloud Functions için monitoring
exports.logSecurityEvent = functions.https.onCall(async (data, context) => {
  await admin.firestore().collection('securityLogs').add({
    type: data.type,
    ip: context.rawRequest.ip,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    details: data.details
  });
});
```

## 7. Incident Response Plan

### 7.1 DDoS Saldırısı Tespiti
1. Cloudflare dashboard'dan anormal trafik kontrolü
2. Firebase Performance Monitoring kontrolleri
3. Error rate ve response time analizi

### 7.2 Müdahale Adımları
1. **Under Attack Mode** aktifleştirme
2. Rate limiting kurallarını sıkılaştırma
3. Geçici IP blacklist oluşturma
4. CAPTCHA challenge seviyesini artırma

### 7.3 Post-Incident
1. Saldırı pattern analizi
2. Firewall kurallarını güncelleme
3. Güvenlik dokümantasyonunu güncelleme

## 8. Best Practices

### 8.1 Güvenlik Headers
```nginx
# Cloudflare Transform Rules ile eklenebilir
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

### 8.2 API Security
- Her API endpoint'i için rate limiting
- JWT token timeout (15 dakika)
- Refresh token rotation
- API versioning

### 8.3 Database Security
- Firestore Security Rules ile field-level koruma
- Read/Write rate limiting
- Backup stratejisi

## 9. Test ve Doğrulama

### 9.1 Load Testing
```bash
# Apache Bench ile test
ab -n 1000 -c 100 https://api.biletsokagi.com/health

# Beklenen: Cloudflare rate limiting devreye girmeli
```

### 9.2 Security Scanning
- OWASP ZAP scanning
- Cloudflare Security Insights
- Firebase Security Rules Simulator

## 10. Maliyet Optimizasyonu

### 10.1 Cloudflare Plans
- Free Plan: Temel DDoS koruması
- Pro Plan ($20/ay): Gelişmiş DDoS koruması + WAF
- Business Plan ($200/ay): Enterprise-level koruma

### 10.2 Firebase Quotas
- Firestore: 50K reads/day (free tier)
- Cloud Functions: 2M invocations/month (free tier)
- Hosting: 10GB transfer/month (free tier)

## Özet

Bu güvenlik yapısı ile:
- ✅ Layer 3/4/7 DDoS koruması
- ✅ Bot detection ve blocking
- ✅ Rate limiting (hem Cloudflare hem uygulama seviyesi)
- ✅ CAPTCHA koruması
- ✅ Real-time monitoring
- ✅ Automatic threat mitigation

Sistemimiz artık DDoS saldırılarına karşı çok katmanlı korumaya sahip.

