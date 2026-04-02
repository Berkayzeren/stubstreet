# SMS Doğrulama Sorun Giderme Rehberi

Bu rehber, SMS doğrulama sisteminde yaşanan sorunları çözmek için hazırlanmıştır.

## 🔧 Yapılan İyileştirmeler

### 1. Countdown Timer Eklendi
- SMS gönderildikten sonra 60 saniye boyunca tekrar gönder butonu devre dışı kalır
- Kullanıcı arayüzünde geri sayım gösterilir (MM:SS formatında)
- Spam koruması sağlanır

### 2. Gelişmiş Hata Yönetimi
- Firebase Auth hata kodları için Türkçe açıklamalar
- Detaylı hata mesajları kullanıcıya gösterilir
- Timeout ve retry mekanizmaları eklendi

### 3. Kullanıcı Deneyimi İyileştirmeleri
- SMS gönderildiğinde bilgilendirici mesaj
- Telefon numarası formatı doğrulaması
- Spam klasörü kontrolü için uyarı

## 🚨 SMS Gelmiyor Sorunları

### 1. Firebase Console Ayarları
Firebase Console'da şu ayarları kontrol edin:

1. **Authentication > Sign-in method > Phone** aktif mi?
2. **Test phone numbers** bölümünde test numarası eklenmiş mi?
3. **App verification** ayarları doğru mu?

### 2. Telefon Numarası Formatı
- Türkiye için: `+905XXXXXXXXX` formatında olmalı
- Ülke kodu seçimi doğru yapılmalı
- Yerel numara 10 haneli olmalı (5 ile başlamalı)

### 3. Test Ortamı
Geliştirme sırasında test numarası kullanın:

```dart
// Test numarası için Firebase Console'da ekleyin
// Test kodu: 123456
```

### 4. Firebase Quota Kontrolü
- Günlük SMS kotası aşılmış olabilir
- Firebase Console > Usage bölümünden kontrol edin
- Test ortamında quota limitleri düşük olabilir

## 🔍 Hata Kodları ve Çözümleri

| Hata Kodu | Açıklama | Çözüm |
|-----------|----------|-------|
| `operation-not-allowed` | Telefon doğrulama devre dışı | Firebase Console'da Phone provider'ı aktifleştirin |
| `invalid-phone-number` | Geçersiz telefon formatı | Telefon numarası formatını kontrol edin |
| `quota-exceeded` | Günlük kota aşıldı | Daha sonra tekrar deneyin veya test numarası kullanın |
| `captcha-check-failed` | reCAPTCHA başarısız | Sayfayı yenileyin, reklam engelleyiciyi kapatın |
| `too-many-requests` | Çok fazla istek | Bir süre bekleyip tekrar deneyin |

## 🧪 Test Adımları

### 1. Test Numarası ile Test
```bash
# Firebase Console'da test numarası ekleyin
# Test kodu: 123456
# Telefon: +905XXXXXXXXX
```

### 2. Gerçek Numara ile Test
- Doğru ülke kodu seçin
- 10 haneli yerel numara girin
- SMS'in gelmesi 1-2 dakika sürebilir

### 3. Debug Logları
```dart
// Debug modunda detaylı loglar
debugPrint('Phone verification started for: $phoneNumber');
debugPrint('Verification ID: $verificationId');
```

## 📱 Mobil Cihaz Ayarları

### Android
- SMS izinleri verilmiş olmalı
- reCAPTCHA için internet bağlantısı gerekli
- Google Play Services güncel olmalı

### iOS
- SMS izinleri verilmiş olmalı
- reCAPTCHA için internet bağlantısı gerekli
- iOS 13+ gerekli

## 🔧 Geliştirici Notları

### Countdown Timer Implementasyonu
```dart
// 60 saniye countdown timer
Timer.periodic(const Duration(seconds: 1), (timer) {
  setState(() {
    _countdownSeconds--;
    if (_countdownSeconds <= 0) {
      _canResendSms = true;
      timer.cancel();
    }
  });
});
```

### Hata Yönetimi
```dart
// Firebase Auth hatalarını yakala ve kullanıcı dostu mesaj göster
verificationFailed: (e) {
  String humanMessage = _getHumanReadableError(e);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(humanMessage), backgroundColor: Colors.red),
  );
}
```

## 📞 Destek

SMS doğrulama sorunları devam ederse:
1. Firebase Console loglarını kontrol edin
2. Test numarası ile deneyin
3. Telefon numarası formatını doğrulayın
4. Firebase quota limitlerini kontrol edin

## 🚀 Gelecek İyileştirmeler

- [ ] reCAPTCHA entegrasyonu
- [ ] SMS delivery status tracking
- [ ] Multiple phone number support
- [ ] Voice call fallback option
