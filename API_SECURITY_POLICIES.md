# API Güvenlik Politikaları ve Key Rotation Rehberi

## 1. API Key Yönetimi

### 1.1 API Key Türleri

#### Public API Keys (Frontend)
- Firebase Config keys
- reCAPTCHA site key
- Google Maps API key (domain restricted)

#### Private API Keys (Backend)
- Firebase Admin SDK service account
- PayTR merchant credentials
- SMTP credentials
- Database connection strings

### 1.2 API Key Güvenlik Seviyeleri

```javascript
// Güvenlik seviyeleri
const SecurityLevels = {
  PUBLIC: 'public',       // Frontend'de görünebilir
  RESTRICTED: 'restricted', // Domain/IP kısıtlamalı
  SECRET: 'secret',       // Sadece backend'de
  CRITICAL: 'critical'    // Çok hassas, şifreli saklanmalı
};
```

## 2. API Key Rotation Stratejisi

### 2.1 Rotation Periyotları

| Key Tipi | Rotation Periyodu | Kritiklik |
|----------|------------------|-----------|
| Firebase Admin SDK | 90 gün | CRITICAL |
| PayTR Credentials | 180 gün | CRITICAL |
| API Access Keys | 30 gün | SECRET |
| JWT Signing Keys | 30 gün | CRITICAL |
| Webhook Secrets | 60 gün | SECRET |

### 2.2 Otomatik Rotation Sistemi

```javascript
// functions/src/services/keyRotationService.js
const admin = require('firebase-admin');
const crypto = require('crypto');

class KeyRotationService {
  constructor() {
    this.db = admin.firestore();
  }

  async rotateApiKey(keyType) {
    const newKey = this.generateSecureKey();
    const timestamp = new Date();
    
    // Yeni key'i kaydet
    await this.db.collection('apiKeys').add({
      type: keyType,
      key: await this.encryptKey(newKey),
      createdAt: timestamp,
      expiresAt: this.getExpirationDate(keyType),
      status: 'pending', // active, pending, expired
      version: await this.getNextVersion(keyType)
    });
    
    // Eski key'i deprecate et (grace period ile)
    await this.deprecateOldKeys(keyType);
    
    return newKey;
  }

  generateSecureKey(length = 32) {
    return crypto.randomBytes(length).toString('base64url');
  }

  async encryptKey(key) {
    // KMS veya benzeri bir servis kullanarak şifrele
    const algorithm = 'aes-256-gcm';
    const password = process.env.ENCRYPTION_KEY;
    const salt = crypto.randomBytes(32);
    const iv = crypto.randomBytes(16);
    
    const derivedKey = crypto.pbkdf2Sync(password, salt, 100000, 32, 'sha256');
    const cipher = crypto.createCipheriv(algorithm, derivedKey, iv);
    
    let encrypted = cipher.update(key, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    
    const authTag = cipher.getAuthTag();
    
    return {
      encrypted,
      salt: salt.toString('hex'),
      iv: iv.toString('hex'),
      authTag: authTag.toString('hex')
    };
  }

  getExpirationDate(keyType) {
    const rotationPeriods = {
      'firebase-admin': 90,
      'paytr': 180,
      'api-access': 30,
      'jwt-signing': 30,
      'webhook': 60
    };
    
    const days = rotationPeriods[keyType] || 30;
    const date = new Date();
    date.setDate(date.getDate() + days);
    return date;
  }
}

module.exports = KeyRotationService;
```

### 2.3 Grace Period Yönetimi

```javascript
// Eski key'lerin belirli bir süre daha çalışması
const GRACE_PERIODS = {
  'firebase-admin': 7, // 7 gün
  'paytr': 14,        // 14 gün
  'api-access': 3,    // 3 gün
  'jwt-signing': 1,   // 1 gün
  'webhook': 7        // 7 gün
};
```

## 3. Güvenlik Politikaları

### 3.1 Authentication Politikaları

```javascript
// Güçlü şifre politikası
const passwordPolicy = {
  minLength: 12,
  requireUppercase: true,
  requireLowercase: true,
  requireNumbers: true,
  requireSpecialChars: true,
  preventCommonPasswords: true,
  preventUserInfo: true,
  maxAge: 90, // gün
  historyCount: 5 // Son 5 şifre tekrar kullanılamaz
};

// Multi-factor authentication
const mfaPolicy = {
  required: true,
  methods: ['totp', 'sms', 'email'],
  gracePeriod: 7, // gün
  rememberDevice: 30 // gün
};
```

### 3.2 Session Yönetimi

```javascript
// Session politikaları
const sessionPolicy = {
  // Token süreleri
  accessTokenTTL: 15 * 60, // 15 dakika
  refreshTokenTTL: 7 * 24 * 60 * 60, // 7 gün
  
  // Concurrent session limiti
  maxConcurrentSessions: 3,
  
  // Idle timeout
  idleTimeout: 30 * 60, // 30 dakika
  
  // Device binding
  bindToDevice: true,
  bindToIP: false, // Mobil kullanıcılar için false
  
  // Session invalidation
  invalidateOnPasswordChange: true,
  invalidateOnPermissionChange: true
};
```

### 3.3 API Access Kontrolü

```javascript
// API erişim politikaları
const apiAccessPolicy = {
  // Rate limiting (per endpoint)
  rateLimits: {
    'public': { requests: 100, window: '1h' },
    'authenticated': { requests: 1000, window: '1h' },
    'premium': { requests: 10000, window: '1h' }
  },
  
  // IP allowlisting
  ipWhitelist: {
    enabled: false,
    ranges: ['10.0.0.0/8', '172.16.0.0/12']
  },
  
  // Geo-blocking
  geoBlocking: {
    enabled: false,
    blockedCountries: [],
    allowedCountries: ['TR', 'US', 'GB', 'DE']
  },
  
  // API versioning
  versioning: {
    strategy: 'header', // header, url, accept
    supported: ['v1', 'v2'],
    deprecation: {
      'v1': '2024-12-31'
    }
  }
};
```

## 4. Güvenlik Monitoring

### 4.1 Audit Logging

```javascript
// Audit log yapısı
const auditLog = {
  timestamp: new Date(),
  eventType: 'API_KEY_ROTATION',
  userId: 'system',
  ipAddress: req.ip,
  userAgent: req.headers['user-agent'],
  action: 'CREATE',
  resource: 'apiKeys/xyz123',
  result: 'SUCCESS',
  metadata: {
    keyType: 'api-access',
    version: 3,
    expiresAt: '2024-03-25'
  }
};

// Kritik olaylar
const criticalEvents = [
  'API_KEY_ROTATION',
  'API_KEY_DELETION',
  'PERMISSION_CHANGE',
  'ADMIN_ACCESS',
  'BULK_DATA_EXPORT',
  'SECURITY_RULE_CHANGE'
];
```

### 4.2 Anomaly Detection

```javascript
// Anormal davranış tespiti
const anomalyRules = {
  // Fazla başarısız giriş denemesi
  failedLogins: {
    threshold: 5,
    window: '10m',
    action: 'LOCK_ACCOUNT'
  },
  
  // Anormal API kullanımı
  apiUsage: {
    threshold: '10x_average',
    window: '1h',
    action: 'RATE_LIMIT'
  },
  
  // Şüpheli coğrafi konum
  geoAnomaly: {
    rapidLocationChange: true,
    impossibleTravel: true,
    action: 'REQUIRE_MFA'
  }
};
```

## 5. Implementation Checklist

### 5.1 Başlangıç Kurulumu
- [ ] Tüm API key'leri environment variable'lara taşı
- [ ] Firebase Functions config'e hassas bilgileri ekle
- [ ] Key encryption sistemi kur
- [ ] Audit logging altyapısı oluştur

### 5.2 Rotation Sistemi
- [ ] Otomatik rotation scheduler'ı kur
- [ ] Grace period yönetimi ekle
- [ ] Key versioning sistemi implementle
- [ ] Rollback mekanizması hazırla

### 5.3 Monitoring
- [ ] Security dashboard oluştur
- [ ] Alert sistemi kur
- [ ] Anomaly detection kuralları tanımla
- [ ] Incident response plan hazırla

## 6. Emergency Procedures

### 6.1 Key Compromise Durumu
```bash
# 1. Etkilenen key'i hemen devre dışı bırak
firebase functions:config:unset compromised.key

# 2. Yeni key oluştur
node scripts/rotate-key.js --type=api-access --emergency

# 3. Tüm sistemleri yeni key ile güncelle
./deploy-new-keys.sh

# 4. Audit log'ları incele
firebase functions:log --severity=WARNING --filter="API_KEY"
```

### 6.2 Rollback Prosedürü
```javascript
// Emergency rollback
async function rollbackApiKey(keyType, version) {
  const previousKey = await db.collection('apiKeys')
    .where('type', '==', keyType)
    .where('version', '==', version - 1)
    .where('status', '==', 'deprecated')
    .get();
    
  if (!previousKey.empty) {
    await previousKey.docs[0].ref.update({
      status: 'active',
      reactivatedAt: new Date(),
      reason: 'emergency_rollback'
    });
  }
}
```

## 7. Compliance ve Standartlar

### 7.1 Uyumluluk Gereksinimleri
- PCI DSS (ödeme işlemleri için)
- GDPR (kişisel veri koruması)
- SOC 2 Type II (güvenlik kontrolleri)
- ISO 27001 (bilgi güvenliği)

### 7.2 Best Practices
- OWASP API Security Top 10
- NIST Cybersecurity Framework
- CIS Controls
- Zero Trust Architecture

## 8. Araçlar ve Servisler

### 8.1 Key Management Services
- Google Cloud KMS
- AWS Secrets Manager
- HashiCorp Vault
- Azure Key Vault

### 8.2 Monitoring Tools
- Google Cloud Security Command Center
- Datadog Security Monitoring
- Splunk Enterprise Security
- ELK Stack (Elasticsearch, Logstash, Kibana)

## Özet

Bu güvenlik politikaları ile:
- ✅ Otomatik API key rotation
- ✅ Çok katmanlı güvenlik kontrolleri
- ✅ Gerçek zamanlı anomaly detection
- ✅ Compliance uyumluluğu
- ✅ Emergency response hazırlığı

Sistem artık enterprise-grade güvenlik standartlarına sahip.

