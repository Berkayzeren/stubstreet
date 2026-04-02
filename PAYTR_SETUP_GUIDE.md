# PayTR Ödeme Sistemi Kurulum Rehberi

Bu dokümanda, StubStreet projesinde PayTR ödeme sisteminin nasıl kurulacağı ve yapılandırılacağı açıklanmaktadır.

## 🔧 Gerekli Ayarlar

### 1. PayTR Merchant Hesabı

PayTR ile ödeme alabilmek için öncelikle merchant hesabınızı oluşturmalısınız:

1. [PayTR Merchant Paneli](https://merchant.paytr.com)'ne kayıt olun
2. Hesabınızı aktifleştirin ve gerekli belgeleri tamamlayın
3. Test modunda işlemler yapabilmek için sandbox credentials alın

### 2. Firebase Functions Environment Variables

PayTR credentials'larını Firebase Functions environment variables olarak set etmelisiniz:

#### Geliştirme Ortamı için (.env dosyası)

```bash
# functions/.env dosyası oluşturun
PAYTR_MERCHANT_ID=your_merchant_id
PAYTR_MERCHANT_KEY=your_merchant_key
PAYTR_MERCHANT_SALT=your_merchant_salt
```

#### Production Ortamı için (Firebase CLI)

```bash
# Firebase Functions environment variables set edin:
firebase functions:config:set paytr.merchant_id="YOUR_MERCHANT_ID"
firebase functions:config:set paytr.merchant_key="YOUR_MERCHANT_KEY"
firebase functions:config:set paytr.merchant_salt="YOUR_MERCHANT_SALT"
```

### 3. PayTR Merchant Panel Ayarları

PayTR Merchant Panel'inizde aşağıdaki ayarları yapmanız gerekir:

#### Callback URL
```
https://your-domain.firebaseapp.com/v1/paytr/callback
```

#### Success URL
```
https://your-domain.com/payment-success
```

#### Fail URL
```
https://your-domain.com/payment-failed
```

#### Hash Check
- Hash kontrolü: **Aktif**
- Hash Type: **SHA256**

## 🚀 Kurulum Adımları

### 1. Backend Deployment

```bash
# Functions klasörüne gidin
cd functions

# Dependencies install edin
npm install

# TypeScript compile edin
npm run build

# Firebase Functions'ı deploy edin
firebase deploy --only functions
```

### 2. Flutter App Konfigürasyonu

`lib/features/checkout/presentation/screens/checkout_screen.dart` dosyasında callback URL'leri güncelleyin:

```dart
// PayTR callback URL'lerini oluştur
final baseUrl = 'https://YOUR_DOMAIN.com'; // Gerçek domain'inizi yazın
final okUrl = '$baseUrl/payment-success?session_id=${session.id}';
final failUrl = '$baseUrl/payment-failed?session_id=${session.id}';
```

### 3. Test Işlemleri

#### Test Kartları

PayTR test modunda kullanabileceğiniz kart bilgileri:

**Başarılı Test Kartı:**
- Kart No: `4508 0345 0803 4509`
- CVV: `000`
- Son Kullanma: `12/2030`
- İsim: `Test User`

**Başarısız Test Kartı:**
- Kart No: `4508 0345 0803 4508`
- CVV: `000`
- Son Kullanma: `12/2030`
- İsim: `Test User`

#### Test Ortamı Kontrolü

```bash
# Local functions test edin
cd functions
npm run serve

# Test endpoint'ini çağırın
curl -X POST http://localhost:5001/your-project/us-central1/api/v1/paytr/initialize \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "amount": "100.00",
    "orderId": "TEST123",
    "okUrl": "https://example.com/success",
    "failUrl": "https://example.com/fail"
  }'
```

## 🔒 Güvenlik

### 1. Environment Variables

```bash
# Production ortamında testMode'u 0 yapın
# functions/src/index.ts dosyasında:
testMode = process.env.NODE_ENV === 'production' ? '0' : '1'
```

### 2. IP Whitelisting

PayTR Merchant Panel'de callback URL'nizin IP adresini whitelist'e ekleyin.

### 3. SSL Certificate

Callback URL'nizin HTTPS kullandığından emin olun.

## 📊 Monitoring ve Logging

### 1. Firebase Console

- Firebase Console > Functions > Logs bölümünden PayTR işlemlerini takip edin
- Error rate ve performance metrikleri kontrol edin

### 2. PayTR Merchant Panel

- İşlem raporlarını takip edin
- Failed transaction'ları analiz edin

## 🛠️ Troubleshooting

### Sık Karşılaşılan Sorunlar

#### 1. "PAYTR credentials missing" hatası
- Environment variables doğru set edilmemiş
- `firebase functions:config:get` ile kontrol edin

#### 2. "Invalid callback hash" hatası
- Merchant Key yanlış
- Hash hesaplama algoritması hatalı
- PayTR dokümantasyonunu kontrol edin

#### 3. WebView açılmıyor
- Dio HTTP client timeout ayarlarını kontrol edin
- Network connectivity problemlerini kontrol edin

### Debug İpuçları

```typescript
// functions/src/index.ts dosyasına debug log ekleyin
console.log('PayTR init params:', {
  merchant_id: PAYTR_MERCHANT_ID,
  hash_string: hashStr,
  calculated_token: token
});
```

## 📞 Destek

- PayTR Technical Support: [support@paytr.com]
- PayTR Dokümantasyon: [https://dev.paytr.com]
- StubStreet Internal Issues: Firebase Console Logs

---

**Not:** Production ortamına geçmeden önce test modunda tüm senaryoları test ettiğinizden emin olun.

**Tarih:** 21 Eylül 2025  
**Version:** 1.0.0

