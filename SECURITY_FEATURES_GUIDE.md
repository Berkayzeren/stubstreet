# 🔐 Güvenlik Özellikleri Kullanım Kılavuzu

Bu kılavuz, Bilet Sokağı uygulamasına eklenen yeni güvenlik özelliklerinin nasıl kullanılacağını açıklar.

## 📋 Eklenen Özellikler

### 1. 🕒 Session Timeout (30 Dakika İnaktivite)
### 2. 🚨 Fraud Detection (Anormal Satın Alma Pattern'leri)  
### 3. 🔐 İsteğe Bağlı 2FA (Two-Factor Authentication)

---

## 1. 🕒 Session Timeout Özelliği

### Nasıl Çalışır
- Kullanıcı 30 dakika boyunca hiçbir aktivite yapmadığında otomatik olarak çıkış yapar
- Her kullanıcı etkileşimi (dokunma, kaydırma, navigasyon) aktivite olarak kaydedilir
- Son 5 dakikada uyarı gösterilebilir (opsiyonel)

### Teknik Detaylar
```dart
// AuthStateManager'da inactivity timeout
static const Duration _inactivityTimeout = Duration(minutes: 30);

// Aktivite kaydetme
authStateManager.recordActivity();

// Kalan süreyi kontrol etme
Duration remaining = authStateManager.timeUntilInactivityTimeout;
bool isClose = authStateManager.isCloseToInactivityTimeout;
```

### Kullanım
```dart
// UserActivityTracker widget'ı ile otomatik aktivite takibi
UserActivityTracker(
  authStateManager: authStateManager,
  child: YourWidget(),
)

// Manuel aktivite kaydetme
authStateManager.recordActivity();
```

### Çıkış Mesajı
Kullanıcı inaktivite nedeniyle çıkış yaptığında login ekranında bilgilendirme mesajı görür:
> "Güvenlik nedeniyle 30 dakika inaktivite sonrası otomatik olarak çıkış yapıldı."

---

## 2. 🚨 Fraud Detection Sistemi

### Analiz Edilen Risk Faktörleri

#### 📊 Kullanıcı Geçmişi
- Son 24 saatte 5+ işlem → Yüksek risk
- Son 7 günde 15+ işlem → Orta risk
- Ortalamadan 5x fazla tutar → Yüksek risk
- Yeni kullanıcı + yüksek tutar → Risk

#### ⚡ Hız Pattern'leri
- 10 dakikada 3+ alım → Kritik risk
- 1 saatte 5+ alım → Yüksek risk
- 2 dakikadan az aralıklarla alım → Risk

#### 💰 Tutar Pattern'leri
- Platform %95'inin üzerinde tutar → Yüksek risk
- Yuvarlak sayılar (100, 500, 1000) → Test işlemi riski
- Şüpheli test tutarları (1, 5, 10 TL) → Risk

#### 🎫 Bilet Pattern'leri
- Kendi biletini satın alma → Engelleme
- Aynı satıcıdan 24 saatte 3+ alım → Risk
- Son 2 saatte etkinlik bileti → Risk
- Geçmiş etkinlik bileti → Risk

#### 💳 Ödeme Pattern'leri
- Ani ödeme yöntemi değişikliği → Risk
- Nakit ödeme → Düşük risk
- Bilinmeyen ödeme yöntemi → Risk

### Risk Seviyeleri

| Seviye | Skor | Açıklama | Aksiyon |
|--------|------|----------|---------|
| **Düşük** | 0.0-0.3 | Normal işlem | Devam et |
| **Orta** | 0.3-0.6 | Dikkat gerekli | Ek kontrol |
| **Yüksek** | 0.6-0.8 | Şüpheli işlem | Manuel inceleme |
| **Kritik** | 0.8-1.0 | Tehlikeli işlem | Engelle |

### Kullanım
```dart
// Checkout sırasında fraud analizi
final fraudResult = await fraudDetectionService.analyzePurchase(
  userId: buyer.id,
  ticketId: ticketId,
  amount: totalAmount,
  currency: 'TRY',
  paymentMethod: paymentMethod,
  deviceId: deviceId,
  ipAddress: ipAddress,
);

// Risk kontrolü
if (fraudResult.shouldBlock) {
  throw Exception('İşlem güvenlik nedeniyle engellenmiştir.');
}

// Uyarı gösterme
if (fraudResult.riskLevel == FraudRiskLevel.high) {
  await FraudWarningDialog.show(
    context: context,
    fraudResult: fraudResult,
  );
}
```

### Fraud Warning Dialog
```dart
// Risk seviyesine göre otomatik uyarı
await FraudWarningDialog.show(
  context: context,
  fraudResult: fraudResult,
);
```

---

## 3. 🔐 Two-Factor Authentication (2FA)

### Desteklenen Yöntemler

#### 📱 SMS Doğrulama
- Telefon numarasına 6 haneli kod gönderimi
- 5 dakika geçerlilik süresi
- Kod tekrar gönderme özelliği

#### 🔐 TOTP (Authenticator App)
- Google Authenticator, Authy uygulamaları
- QR kod ile kolay kurulum
- Manuel kod girişi desteği
- 30 saniye döngülü kodlar

#### 📧 E-posta Doğrulama (Opsiyonel)
- E-posta adresine kod gönderimi
- Yedek doğrulama yöntemi

### Kurulum

#### SMS 2FA Kurulumu
```dart
// SMS 2FA başlatma
final message = await twoFactorService.setupSMS2FA(
  userId: userId,
  phoneNumber: '+90 555 123 4567',
);

// SMS kodunu doğrulama
final config = await twoFactorService.verify2FASetup(
  userId: userId,
  verificationCode: smsCode,
  method: TwoFactorMethod.sms,
);
```

#### TOTP 2FA Kurulumu
```dart
// TOTP kurulum bilgileri al
final result = await twoFactorService.setupTOTP2FA(
  userId: userId,
  userEmail: userEmail,
);

// QR kod: result['qrCodeUri']
// Manuel kod: result['manualEntryKey']

// TOTP kodunu doğrula
final config = await twoFactorService.verify2FASetup(
  userId: userId,
  verificationCode: totpCode,
  method: TwoFactorMethod.totp,
);
```

### Login Sırasında 2FA

```dart
// 2FA gerekli mi kontrol et
final isEnabled = await twoFactorService.isTwoFactorEnabled(userId);

if (isEnabled) {
  // 2FA doğrulama ekranını göster
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => TwoFactorVerificationScreen(
        userId: userId,
        onVerificationSuccess: () {
          // Login tamamlandı
        },
      ),
    ),
  );
}

// 2FA kodunu doğrula
final isValid = await twoFactorService.verify2FACode(
  userId: userId,
  code: userEnteredCode,
);
```

### Yedek Kodlar

Her 2FA kurulumunda 10 adet 8 haneli yedek kod oluşturulur:

```dart
// Yedek kodları al
final backupCodes = await twoFactorService.getBackupCodes(userId);

// Yedek kodları yenile
final newCodes = await twoFactorService.regenerateBackupCodes(userId);

// Yedek kod ile doğrulama
final isValid = await twoFactorService.verify2FACode(
  userId: userId,
  code: backupCode, // 8 haneli yedek kod
);
```

### 2FA Yönetimi

```dart
// 2FA durumunu kontrol et
final config = await twoFactorService.getTwoFactorConfig(userId);

// 2FA'yı devre dışı bırak
await twoFactorService.disable2FA(userId);

// SMS kodu gönder (login sırasında)
await twoFactorService.send2FACode(
  userId: userId,
  method: TwoFactorMethod.sms,
);
```

---

## 🛠️ Entegrasyon Rehberi

### 1. AuthStateManager Entegrasyonu

```dart
// main.dart'ta
final authStateManager = AuthStateManager(authRepository);
await authStateManager.initialize();

// Widget'larda aktivite takibi
UserActivityTracker(
  authStateManager: authStateManager,
  child: MaterialApp(...),
)
```

### 2. Fraud Detection Entegrasyonu

```dart
// CheckoutService'te
class CheckoutService {
  final FraudDetectionService _fraudDetectionService;
  
  Future<CheckoutSession> initiateCheckout(...) async {
    // Fraud analizi
    final fraudResult = await _fraudDetectionService.analyzePurchase(...);
    
    if (fraudResult.shouldBlock) {
      throw Exception('İşlem güvenlik nedeniyle engellenmiştir.');
    }
    
    // Yüksek risk durumunda uyarı
    if (fraudResult.riskLevel == FraudRiskLevel.high) {
      // UI'da uyarı göster
    }
  }
}
```

### 3. 2FA Entegrasyonu

```dart
// Login akışında
class LoginScreen extends StatefulWidget {
  Future<void> _signIn() async {
    // Normal login
    final user = await authRepository.signIn(email, password);
    
    // 2FA kontrol
    final is2FAEnabled = await twoFactorService.isTwoFactorEnabled(user.id);
    
    if (is2FAEnabled) {
      // 2FA doğrulama ekranına git
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TwoFactorVerificationScreen(
            userId: user.id,
            onVerificationSuccess: () => _completeLogin(),
          ),
        ),
      );
    } else {
      _completeLogin();
    }
  }
}
```

---

## 🧪 Test Etme

### Unit Testler
```bash
flutter test test/security_features_test.dart
```

### Test Senaryoları

#### Session Timeout Testi
1. Uygulamayı açın
2. 30 dakika bekleyin (veya test için süreyi kısaltın)
3. Otomatik çıkış yapıldığını kontrol edin
4. Login ekranında inaktivite mesajını kontrol edin

#### Fraud Detection Testi
1. Hızlı ardışık alımlar yapın (5+ işlem)
2. Yüksek tutarlı işlem deneyin
3. Kendi biletinizi satın almaya çalışın
4. Risk uyarılarını kontrol edin

#### 2FA Testi
1. 2FA kurulum ekranını açın
2. SMS veya TOTP yöntemini seçin
3. Kurulum sürecini tamamlayın
4. Çıkış yapıp tekrar giriş yapmayı deneyin
5. 2FA doğrulama ekranını kontrol edin

---

## 📊 Monitoring ve Logging

### Firestore Collections

```javascript
// Fraud analiz sonuçları
fraudAnalysis: {
  userId: string,
  ticketId: string,
  result: {
    riskLevel: 'low' | 'medium' | 'high' | 'critical',
    riskScore: number,
    riskFactors: string[],
    shouldBlock: boolean
  },
  timestamp: Timestamp
}

// 2FA yapılandırmaları
twoFactorConfigs: {
  userId: string,
  status: 'disabled' | 'enabled' | 'pending_verification',
  enabledMethods: ('sms' | 'totp' | 'email')[],
  phoneNumber?: string,
  totpSecret?: string,
  backupCodes: string[],
  lastUsed?: Timestamp,
  createdAt: Timestamp,
  updatedAt: Timestamp
}

// SMS doğrulama kodları (geçici)
smsVerificationCodes: {
  code: string,
  phoneNumber: string,
  createdAt: Timestamp,
  expiresAt: Timestamp
}
```

### Log Kategorileri

```dart
// Session timeout logları
developer.log('User inactive for X minutes, signing out', name: 'AuthStateManager');

// Fraud detection logları  
developer.log('High-risk transaction detected', name: 'FraudDetectionService');

// 2FA logları
developer.log('2FA setup completed for user', name: 'TwoFactorAuthService');
```

---

## ⚙️ Yapılandırma

### Timeout Süreleri
```dart
// AuthStateManager.dart
static const Duration _inactivityTimeout = Duration(minutes: 30);
static const Duration _inactivityCheckInterval = Duration(minutes: 1);
```

### Fraud Detection Eşikleri
```dart
// FraudDetectionService.dart
// Yüksek frekanslı işlemler
if (last24HoursOrders >= 5) riskScore += 0.3;

// Yüksek tutarlar
if (currentAmount > avgAmount * 5) riskScore += 0.3;

// Risk seviyeleri
if (score >= 0.8) return FraudRiskLevel.critical;
if (score >= 0.6) return FraudRiskLevel.high;
if (score >= 0.3) return FraudRiskLevel.medium;
```

### 2FA Ayarları
```dart
// TwoFactorAuthService.dart
// TOTP zaman adımı
final timeStep = now ~/ 30; // 30 saniye

// Yedek kod sayısı
for (int i = 0; i < 10; i++) // 10 yedek kod

// SMS kod uzunluğu
return (100000 + random.nextInt(900000)).toString(); // 6 haneli
```

---

## 🚀 Production Notları

### SMS Servisi Entegrasyonu
```dart
// Production'da gerçek SMS servisi kullanın
// Örnek: Twilio, AWS SNS, Netgsm
await smsService.sendSMS(phoneNumber, code);
```

### TOTP Kütüphanesi
```yaml
# pubspec.yaml'a ekleyin
dependencies:
  otp: ^3.1.4
  qr_flutter: ^4.1.0
```

### Güvenlik Başlıkları
```dart
// HTTP isteklerinde güvenlik başlıkları
headers: {
  'X-Frame-Options': 'SAMEORIGIN',
  'X-Content-Type-Options': 'nosniff',
  'X-XSS-Protection': '1; mode=block',
}
```

### Rate Limiting
```javascript
// Cloud Functions'ta
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 dakika
  max: 5, // 5 deneme
  message: 'Çok fazla deneme yapıldı'
});
```

---

## 📞 Destek

Güvenlik özellikleri ile ilgili sorularınız için:
- **E-posta**: info@biletsokagi.com
- **Dokümantasyon**: /docs/security/
- **Acil Durum**: +90 530 826 66 98

---

**⚠️ Önemli**: Bu güvenlik özellikleri kullanıcı deneyimini etkileyebilir. Test sürecinde kullanıcı geri bildirimlerini dikkate alın ve gerekirse ayarlamaları yapın.
