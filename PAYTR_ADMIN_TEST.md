# 🧪 PayTR Admin Test Rehberi

## 👤 Test Kullanıcısı
- **Kullanıcı Adı**: `admin`
- **Şifre**: `123456`
- **Email**: `admin@biletsokagi.com`

## 🚀 Test Adımları

### 1. **Uygulamayı Çalıştır**
```bash
cd /home/admin/StudioProjects/stubstreet
flutter run --debug
```

### 2. **Admin Giriş Yap**
- Kullanıcı adı: `admin`
- Şifre: `123456`

### 3. **Bilet Satın Al**
- Herhangi bir bilet seç
- "Satın Al" butonuna bas
- PayTR'yi seç

### 4. **Debug Loglarını İzle**

#### Beklenen Loglar:
```
🔍 Getting user data for PayTR...
📍 User Address: "İstanbul, Türkiye" (length: 17)
📞 User Phone: "05555555555" (length: 11)  
👤 User Name: "Admin Kullanici" (length: 14)

🔍 PayTR Validation başlıyor...
📦 Payload: {email: admin@biletsokagi.com, amount: 12600, ...}
👤 UserName: "Admin Kullanici" (14 karakter)
📍 UserAddress: "Istanbul, Turkiye" (17 karakter)
📞 UserPhone: "05555555555" (11 karakter)
✅ PayTR Validation tamamlandı
```

#### Firebase Functions Logları:
```bash
# Başka terminalde
firebase functions:log --only api --follow
```

Beklenen log:
```
🔍 PayTR Request Data: {
  merchant_id: 'XXXXXX',
  email: 'admin@biletsokagi.com',
  payment_amount: '12600',
  user_name: 'Admin Kullanici',
  user_address: 'Istanbul, Turkiye',
  user_phone: '05555555555',
  validation: {
    hasEmail: true,
    hasAmount: true,
    hasUserName: true,
    hasUserAddress: true,
    hasUserPhone: true
  }
}
```

## 🚨 Hata Durumunda

### Eğer Hala "Zorunlu Alan" Hatası Alıyorsanız:

#### 1. **Debug Loglarını Kontrol Edin**
```
❌ Eksik alan: [hangi alan] = [değer]
❌ Geçersiz email: [email]
❌ Amount string değil: [amount] ([tip])
🚨 PayTR Zorunlu Alan Hatası: [detay]
```

#### 2. **Firebase Functions Response'u Kontrol Edin**
```
❌ PayTR Network Error:
   Status Code: 400
   Response: {error: "Missing required fields", details: {...}}
```

#### 3. **PayTR WebView Hatası**
```
⚠️ PayTR Error URL: https://www.paytr.com/odeme/...error...
❌ PayTR WebView Error: [hata açıklaması]
```

## 🔧 Acil Çözümler

### Çözüm 1: Validation'ı Bypass Et
```dart
// paytr_service.dart'ta
void _validatePayload(Map<String, dynamic> payload) {
  debugPrint('⚠️ Validation bypass edildi - test için');
  return; // Tüm validation'ı atla
}
```

### Çözüm 2: Minimal Payload
```dart
// checkout_screen.dart'ta
final payload = {
  'email': 'admin@biletsokagi.com',
  'amount': '10000', // 100 TL
  'orderId': 'test_${DateTime.now().millisecondsSinceEpoch}',
  'okUrl': 'https://device-streaming-70d2d53c.firebaseapp.com/ok',
  'failUrl': 'https://device-streaming-70d2d53c.firebaseapp.com/fail',
  'userName': 'Admin Test',
  'userAddress': 'Istanbul Turkiye',
  'userPhone': '05555555555',
  'currency': 'TL',
  'testMode': '1',
};
```

### Çözüm 3: PayTR Credentials Kontrol
```bash
# Firebase Functions config kontrol
firebase functions:config:get

# .env dosyası kontrol
cat functions/.env
```

## 📞 Acil Destek

**Hemen Ara**: +90 530 826 66 98  
**E-posta**: info@biletsokagi.com

---

**🎯 Bu test adımlarını takip edin ve hangi adımda hata aldığınızı bildirin. Debug logları ile tam olarak neyin eksik olduğunu görebiliriz!**
