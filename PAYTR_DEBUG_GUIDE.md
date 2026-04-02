# 🔍 PayTR Debug Kılavuzu - "Zorunlu Alan Değerleri" Hatası

## 🚨 Hata: "Zorunlu alan değerleri geçersiz veya gönderilemedi"

Bu hata PayTR'ye gönderilen parametrelerde eksiklik veya format hatası olduğunu gösterir.

## 🔧 Hemen Kontrol Edilecekler

### 1. **Debug Loglarını Kontrol Et**

Checkout screen'de ödeme yaparken debug loglarına bakın:

```
🔍 PayTR Payload Debug:
Email: admin@biletsokagi.com
Amount: 12600
OrderId: checkout_session_id
UserName: admin
UserAddress: Türkiye  
UserPhone: 05555555555
Basket: [[Bilet, 12000, 1], [Hizmet Bedeli, 600, 1]]
```

### 2. **Kritik Alan Kontrolleri**

#### ✅ Email
- **Gerekli**: Geçerli email formatı
- **Örnek**: `admin@biletsokagi.com`

#### ✅ Amount 
- **Gerekli**: Kuruş cinsinden (100 = 1 TL)
- **Format**: String olarak gönderilmeli
- **Örnek**: `"12600"` (126 TL için)

#### ✅ UserName
- **Gerekli**: Minimum 2 karakter
- **Format**: Türkçe karakter olmadan
- **Örnek**: `"admin"` veya `"kullanici"`

#### ✅ UserAddress
- **Gerekli**: Minimum 5 karakter
- **Format**: Adres bilgisi
- **Örnek**: `"Türkiye"` veya `"İstanbul, Türkiye"`

#### ✅ UserPhone
- **Gerekli**: Türkiye telefon formatı
- **Format**: `05XXXXXXXXX` veya `+905XXXXXXXXX`
- **Örnek**: `"05555555555"`

#### ✅ Basket
- **Gerekli**: JSON array formatı
- **Format**: `[["ürün_adı", "fiyat_kuruş", "adet"], ...]`
- **Örnek**: `[["Bilet", "12000", "1"]]`

### 3. **Yaygın Hatalar ve Çözümleri**

#### ❌ Boş UserName
```dart
// HATALI
'userName': '', 

// DOĞRU  
'userName': widget.buyer.displayName.isNotEmpty 
    ? widget.buyer.displayName 
    : widget.buyer.email.split('@')[0],
```

#### ❌ Geçersiz UserPhone
```dart
// HATALI
'userPhone': null,
'userPhone': '555 123',

// DOĞRU
'userPhone': '05555555555',
```

#### ❌ Yanlış Amount Formatı
```dart
// HATALI
'amount': 126.0,        // Number
'amount': '126',        // TL cinsinden

// DOĞRU
'amount': '12600',      // Kuruş cinsinden string
```

#### ❌ Basket Format Hatası
```dart
// HATALI
'basket': "Bilet,12000,1",

// DOĞRU
'basket': [
  ["Bilet", "12000", "1"],
  ["Hizmet Bedeli", "600", "1"]
],
```

## 🛠️ Hızlı Test Adımları

### 1. **Flutter Debug Console'u İzle**

```bash
flutter run --debug
# Ödeme yaparken console'da bu logları arayın:
# 🔍 PayTR Payload Debug:
# 🌐 PayTR Page started:
# ❌ PayTR WebView Error:
```

### 2. **Firebase Functions Logları**

```bash
firebase functions:log --only api | grep "PayTR"
```

### 3. **Manuel Test**

```bash
# Test payload'ı hazırla
curl -X POST https://us-central1-device-streaming-70d2d53c.cloudfunctions.net/api/v1/paytr/initialize \
  -H "Authorization: Bearer YOUR_FIREBASE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "amount": "10000",
    "currency": "TL", 
    "orderId": "test123",
    "userName": "Test User",
    "userAddress": "Test Address, Türkiye",
    "userPhone": "05555555555",
    "okUrl": "https://example.com/ok",
    "failUrl": "https://example.com/fail",
    "basket": [["Test Bilet", "10000", "1"]]
  }'
```

## 🔍 Detaylı Debug Checklist

### Frontend (Flutter)
- [ ] **Email**: `widget.buyer.email` boş değil mi?
- [ ] **Amount**: Kuruş cinsinden hesaplandı mı?
- [ ] **UserName**: En az 2 karakter mi?
- [ ] **UserAddress**: En az 5 karakter mi? 
- [ ] **UserPhone**: Geçerli format mı?
- [ ] **Basket**: Doğru array formatında mı?

### Backend (Functions)
- [ ] **Token**: Firebase ID token geçerli mi?
- [ ] **Credentials**: PAYTR_MERCHANT_ID/KEY/SALT set mi?
- [ ] **Validation**: Tüm zorunlu alanlar var mı?
- [ ] **Hash**: Token hash'i doğru hesaplandı mı?

### PayTR Panel
- [ ] **Test Mode**: Test modunda mı?
- [ ] **Callback URL**: Doğru set edilmiş mi?
- [ ] **Hash Check**: Aktif mi?
- [ ] **Merchant Status**: Aktif mi?

## 🚀 Hızlı Çözüm Adımları

### 1. **Anında Çözüm**
```dart
// Checkout screen'de sabit değerler kullan
final payload = {
  'email': 'admin@biletsokagi.com',
  'amount': '10000', // 100 TL
  'userName': 'Test Kullanici',
  'userAddress': 'Istanbul, Turkiye', 
  'userPhone': '05555555555',
  // ... diğer alanlar
};
```

### 2. **Validation Debug**
```dart
// PayTR service'te validation'ı bypass et
void _validatePayload(Map<String, dynamic> payload) {
  debugPrint('🔍 Validating payload: $payload');
  // Validation'ı geçici olarak devre dışı bırak
  return;
}
```

### 3. **Functions Log İzleme**
```bash
# Real-time log izleme
firebase functions:log --only api --follow
```

## 📞 Acil Destek

Sorun devam ederse:
- **Telefon**: +90 530 826 66 98
- **E-posta**: info@biletsokagi.com
- **PayTR Destek**: PayTR merchant panel üzerinden

---

**🎯 En Yaygın Çözüm**: UserName, UserAddress ve UserPhone alanlarının boş olmaması ve doğru formatta olması. Bu 3 alan PayTR'nin en sık hata verdiği alanlar.
