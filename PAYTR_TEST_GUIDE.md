# PayTR Ödeme Sistemi Test Rehberi

Bu rehber, StubStreet uygulamasında PayTR ödeme sistemini nasıl test edeceğinizi açıklar.

## 🚀 Test Ortamı Hazırlığı

### 1. Firebase Emülatörlerini Başlatın

```bash
cd /home/admin/StudioProjects/stubstreet
firebase emulators:start --only firestore,functions
```

### 2. Flutter Uygulamasını Başlatın

```bash
cd /home/admin/StudioProjects/stubstreet
flutter run -d [DEVICE_ID]
```

## 🧪 Test Senaryoları

### Senaryo 1: Başarılı Ödeme Testi

1. **Uygulama Akışı:**
   - Uygulamada bir bilet seçin
   - "Satın Al" butonuna tıklayın
   - Checkout ekranında PayTR seçeneğini seçin
   - "Test Kartları ve Bilgiler" butonuna tıklayın

2. **Test Kartı Bilgileri:**
   ```
   Kart Numarası: 4508 0345 0803 4509
   CVV: 000
   Son Kullanma Tarihi: 12/2030
   Ad Soyad: Test User
   ```

3. **Beklenen Sonuç:**
   - PayTR WebView açılır
   - Ödeme formu gösterilir
   - Kart bilgileri girilir
   - Ödeme başarıyla tamamlanır
   - Sipariş detay sayfasına yönlendirilir

### Senaryo 2: Başarısız Ödeme Testi

1. **Test Kartı Bilgileri:**
   ```
   Kart Numarası: 4508 0345 0803 4508
   CVV: 000
   Son Kullanma Tarihi: 12/2030
   Ad Soyad: Test User
   ```

2. **Beklenen Sonuç:**
   - PayTR WebView açılır
   - Ödeme formu gösterilir
   - Kart bilgileri girilir
   - Ödeme başarısız olur
   - Hata mesajı gösterilir

### Senaryo 3: Ödeme İptali Testi

1. **Test Akışı:**
   - PayTR WebView'ını açın
   - Geri butonuna basın veya ödeme sayfasını kapatın

2. **Beklenen Sonuç:**
   - Checkout ekranına dönülür
   - İptal mesajı gösterilir

## 🔍 Test Kontrol Listesi

### Frontend Kontrolleri

- [ ] PayTR logoları doğru şekilde gösteriliyor
- [ ] Test kartları bilgisi doğru şekilde gösteriliyor
- [ ] Bilet özeti doğru şekilde hesaplanıyor (5% hizmet bedeli)
- [ ] PayTR WebView doğru şekilde açılıyor
- [ ] Ödeme başarılı durumda Order Detail'e yönlendirme yapılıyor
- [ ] Ödeme başarısız durumda hata mesajı gösteriliyor

### Backend Kontrolleri

- [ ] PayTR initialize endpoint'i çalışıyor
- [ ] Hash hesaplama doğru yapılıyor
- [ ] PayTR callback endpoint'i çalışıyor
- [ ] Başarılı ödeme durumunda Order oluşturuluyor
- [ ] Ticket durumu 'sold' olarak güncelleniyor
- [ ] Başarısız ödeme durumunda session 'failed' olarak güncelleniyor

### Güvenlik Kontrolleri

- [ ] PayTR credentials güvenli şekilde saklanıyor
- [ ] Hash doğrulaması yapılıyor
- [ ] SSL sertifikası aktif
- [ ] Test modu aktif (production'da kapatılacak)

## 🎯 Test Verileri

### PayTR Test Credentials
```
Merchant ID: 619278
Test Mode: 1 (aktif)
Hash Type: SHA256
```

### Test URLs
```
Success URL: https://device-streaming-70d2d53c.firebaseapp.com/payment-success
Fail URL: https://device-streaming-70d2d53c.firebaseapp.com/payment-failed
Callback URL: https://api-vddupn2idq-uc.a.run.app/v1/paytr/callback
```

## 📊 Test Sonuçları Kaydetme

Her test senaryosu için aşağıdaki bilgileri kaydedin:

1. **Test Tarihi ve Saati**
2. **Test Senaryosu**
3. **Kullanılan Test Kartı**
4. **Beklenen Sonuç**
5. **Gerçek Sonuç**
6. **Başarı Durumu (✅/❌)**
7. **Notlar/Hatalar**

## 🐛 Sık Karşılaşılan Sorunlar

### PayTR WebView Açılmıyor
- İnternet bağlantısını kontrol edin
- Firebase Functions'ın çalıştığını kontrol edin
- PayTR credentials'ları kontrol edin

### Hash Mismatch Hatası
- Merchant Key doğru mu kontrol edin
- Hash hesaplama algoritması doğru mu kontrol edin
- PayTR dokümantasyonunu kontrol edin

### Callback Çalışmıyor
- Callback URL'nin doğru olduğunu kontrol edin
- HTTPS kullanıldığını kontrol edin
- Firebase Functions loglarını kontrol edin

## 📞 Destek

- **PayTR Dokümantasyon:** [https://dev.paytr.com](https://dev.paytr.com)
- **Firebase Console:** [https://console.firebase.google.com](https://console.firebase.google.com)
- **Test Logs:** Firebase Functions > Logs bölümünden kontrol edilebilir

---

**Önemli:** Production'a geçmeden önce test modunu kapatın (`testMode: '0'`) ve gerçek merchant bilgilerini kullanın.

**Test Tarihi:** 23 Eylül 2025  
**Version:** 1.0.0
