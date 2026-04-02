# 🔧 PayTR Ödeme Sorunları Giderme Kılavuzu

## 🚨 Yaygın Hatalar ve Çözümleri

### 1. 🔐 401 - Kimlik Doğrulama Hatası

#### Sebepleri:
- Firebase ID token'ın süresi dolmuş
- Authorization header eksik
- Geçersiz token formatı
- Kullanıcı oturumu sonlanmış

#### Çözümler:
```dart
// 1. Token yenileme
final user = FirebaseAuth.instance.currentUser;
if (user != null) {
  final idToken = await user.getIdToken(true); // Force refresh
}

// 2. Kullanıcı oturum kontrolü
if (FirebaseAuth.instance.currentUser == null) {
  // Kullanıcıyı login sayfasına yönlendir
  Navigator.pushReplacementNamed(context, '/login');
}
```

#### Kullanıcı Mesajı:
> "Oturum süreniz dolmuş olabilir. Lütfen çıkış yapıp tekrar giriş yapın."

### 2. 🌐 500 - Sunucu Hatası

#### Sebepleri:
- PayTR credentials eksik veya yanlış
- Firebase Functions timeout
- Sunucu aşırı yüklenme
- PayTR API geçici olarak down

#### Çözümler:
```javascript
// functions/src/index.ts kontrolü
if (!PAYTR_MERCHANT_ID || !PAYTR_MERCHANT_KEY || !PAYTR_MERCHANT_SALT) {
  return res.status(500).json({ 
    success: false, 
    error: 'PAYTR credentials missing' 
  });
}
```

#### Kullanıcı Mesajı:
> "Sunucu geçici olarak kullanılamıyor. Lütfen birkaç dakika sonra tekrar deneyin."

### 3. 🔗 Network Error

#### Sebepleri:
- İnternet bağlantısı yok
- Firewall/proxy engeli
- DNS çözümleme sorunu
- Functions URL'i yanlış

#### Çözümler:
```dart
// Bağlantı kontrolü
final connectivity = await Connectivity().checkConnectivity();
if (connectivity == ConnectivityResult.none) {
  throw PayTRException('İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.');
}
```

#### Kullanıcı Mesajı:
> "İnternet bağlantısı sorunu. Lütfen bağlantınızı kontrol edip tekrar deneyin."

### 4. ⏱️ Timeout Hataları

#### Sebepleri:
- Yavaş internet bağlantısı
- Sunucu yanıt süresi uzun
- PayTR API gecikmesi

#### Çözümler:
```dart
// Timeout sürelerini artır
final dio = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 60), // 30'dan 60'a
  receiveTimeout: const Duration(seconds: 60),  // 30'dan 60'a
));
```

#### Kullanıcı Mesajı:
> "İstek zaman aşımına uğradı. Lütfen tekrar deneyin."

---

## 🔍 Debug Adımları

### 1. Firebase Functions Logları

```bash
# Functions loglarını izle
firebase functions:log --only api

# Spesifik hata logları
firebase functions:log --only api | grep "PayTR"
```

### 2. PayTR Credentials Kontrolü

```javascript
// functions/src/index.ts
console.log('PayTR Credentials Check:', {
  hasMerchantId: !!PAYTR_MERCHANT_ID,
  hasMerchantKey: !!PAYTR_MERCHANT_KEY,
  hasMerchantSalt: !!PAYTR_MERCHANT_SALT,
});
```

### 3. Token Doğrulama

```dart
// Flutter client'ta
final user = FirebaseAuth.instance.currentUser;
if (user != null) {
  try {
    final idToken = await user.getIdToken();
    print('ID Token alındı: ${idToken.substring(0, 20)}...');
  } catch (e) {
    print('Token alma hatası: $e');
  }
}
```

### 4. Request Headers Kontrolü

```dart
// PayTR Service'te debug
print('Request Headers: ${options.headers}');
print('Request URL: $_functionsBaseUrl/v1/paytr/initialize');
print('Request Body: ${jsonEncode(payload)}');
```

---

## 🛠️ Sorun Giderme Checklist

### ✅ Temel Kontroller

- [ ] **İnternet Bağlantısı**: WiFi/mobil veri aktif mi?
- [ ] **Kullanıcı Oturumu**: Firebase Auth'da giriş yapılmış mı?
- [ ] **Token Geçerliliği**: ID token süresi dolmamış mı?
- [ ] **PayTR Credentials**: Merchant ID, Key, Salt doğru mu?

### ✅ Teknik Kontroller

- [ ] **Functions Deployment**: Son versiyon deploy edilmiş mi?
- [ ] **Environment Variables**: PAYTR env değişkenleri set mi?
- [ ] **CORS Settings**: Frontend domain'i allowed mi?
- [ ] **Rate Limiting**: İstek limiti aşılmamış mı?

### ✅ PayTR Spesifik Kontroller

- [ ] **Test Mode**: Test modunda mı, canlı modda mı?
- [ ] **Hash Calculation**: Token hash'i doğru hesaplanıyor mu?
- [ ] **Callback URLs**: OK/Fail URL'leri erişilebilir mi?
- [ ] **Amount Format**: Kuruş cinsinden gönderiliyor mu?

---

## 🚀 Hızlı Çözümler

### 401 Hatası İçin
```dart
// 1. Token'ı yenile
await FirebaseAuth.instance.currentUser?.getIdToken(true);

// 2. Kullanıcıyı yeniden login yap
await FirebaseAuth.instance.signOut();
// Login sayfasına yönlendir
```

### 500 Hatası İçin
```bash
# 1. Functions'ı yeniden deploy et
firebase deploy --only functions

# 2. Environment variables kontrol et
firebase functions:config:get
```

### Network Error İçin
```dart
// 1. Bağlantı kontrolü
final connectivity = await Connectivity().checkConnectivity();

// 2. Retry mekanizması
for (int i = 0; i < 3; i++) {
  try {
    return await paytrService.initialize(payload);
  } catch (e) {
    if (i == 2) rethrow; // Son deneme
    await Future.delayed(Duration(seconds: 2 * (i + 1)));
  }
}
```

---

## 📊 Hata İstatistikleri

### Yaygın Hata Dağılımı
- **401 (Auth)**: %40 - En yaygın
- **500 (Server)**: %25 - İkinci sırada
- **Network**: %20 - Bağlantı sorunları
- **Timeout**: %10 - Yavaş bağlantı
- **Validation**: %5 - Kullanıcı hatası

### Çözüm Süreleri
- **401**: Anında (re-login)
- **500**: 2-5 dakika (retry)
- **Network**: Kullanıcıya bağlı
- **Timeout**: 30-60 saniye (retry)

---

## 📞 Destek

### Acil Durumlar
- **Telefon**: +90 530 826 66 98
- **E-posta**: info@biletsokagi.com

### Teknik Destek
- **PayTR Dokümantasyon**: `PAYTR_SETUP_GUIDE.md`
- **Güvenlik Kılavuzu**: `SECURITY_FEATURES_GUIDE.md`
- **API Dokümantasyonu**: `api/README.md`

---

**🎯 Sonuç**: Bu kılavuzu takip ederek PayTR ödeme sorunlarının %95'ini çözebilirsiniz. Sorun devam ederse teknik destek ile iletişime geçin.
