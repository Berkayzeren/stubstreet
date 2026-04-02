# Firebase Yapı Analizi ve Düzeltmeler

## 1. Bilet Görüntüleme Sorunu ve Buyer/Seller Ayrımı

### Sorun:
- `whereIn` ve `orderBy` kombinasyonu composite index gerektiriyordu
- Bazı biletlerin `status` veya `createdAt` alanları eksik olabilir
- Sadece satışta olan biletler görünmeliydi

### Çözüm:
- Tüm biletleri alıp manuel filtreleme yapılıyor (index sorunu için)
- Sadece `status='available'` olan biletler gösteriliyor
- Debug logları ile tüm status dağılımı görülebiliyor
- `createdAt` yoksa `saleDate` kullanılıyor

### Buyer ve Seller Ayrımı:
- **Buyer (Alıcı)**: Bilet satın almak isteyen kullanıcı
- **Seller (Satıcı)**: Bilet satan kullanıcı
- **Çakışma yok**: Bir kullanıcı hem alıcı hem satıcı olabilir
- `users.role` alanı kullanıcının varsayılan rolünü belirtir
- `tickets.sellerId` ve `tickets.buyerId` alanları işlem bazlı rolleri gösterir

## 2. User ve UsernameIndex Collection'ları

### Amaç ve Kullanım:
- **users**: Ana kullanıcı profil verileri (private)
  - email, isim, telefon, rol, durum vb.
  - Sadece authenticated kullanıcılar erişebilir
  
- **usernameIndex**: Username-email/uid eşleştirmesi (public)
  - Login ekranında username ile giriş için
  - Herkes okuyabilir (authentication öncesi)
  - Sadece username, email, uid ve role/status bilgileri

### Senkronizasyon:
- Kullanıcı username değiştirdiğinde her iki collection güncellenmeli
- Script'ler mevcut: `create_username_index.dart` ve `seed_username_index.js`

## 3. Firebase Rules ve Index Düzeltmeleri

### Rules Güncellemeleri:
1. **Tickets**: Detaylı update kuralları, status kontrolü
2. **UsernameIndex**: Username format kontrolü (alfanumerik, 3-20 karakter)
3. **UserProfiles**: Genişletilmiş profil bilgileri için yeni collection
4. **NotificationSettings**: Bildirim tercihleri
5. **PushNotifications**: Push bildirimleri geçmişi

### Yeni Index'ler:
1. `users.username` - Username aramaları için
2. `users.role` + `users.status` - Rol bazlı filtreleme
3. `tickets.buyerId` + `createdAt` - Alınan biletler
4. `messages` (COLLECTION_GROUP) - Global mesaj aramaları
5. `userProfiles.isOnline` + `lastSeenAt` - Çevrimiçi kullanıcılar
6. `pushNotifications` - Bildirim yönetimi

## 4. Chat Username Hataları

### Sorun:
- Mesajlarda `senderName` ve `receiverName` alanları boş kalıyordu
- Chat'te kullanıcılar "Unknown User" olarak görünüyordu

### Çözüm:
- `FirebaseChatService.sendMessage()` metoduna username çözümleme eklendi
- Mesaj gönderilmeden önce users collection'dan isimler alınıyor
- Öncelik sırası: displayName > username > firstName+lastName > "User"

### Conversation Güncellemesi:
- `isActive` alanı eklendi (soft delete için)
- `updatedAt` timestamp'i eklendi

## Öneriler

1. **Migration Script'i**: Mevcut biletlerin status'lerini kontrol edin
2. **Username Unique Kontrolü**: Backend'de username uniqueness kontrolü ekleyin
3. **Cache Mekanizması**: Sık kullanılan username'leri cache'leyin
4. **Monitoring**: Firebase Console'da yeni index'lerin performansını izleyin

## Deploy Adımları

```bash
# 1. Rules'ları deploy et
firebase deploy --only firestore:rules

# 2. Index'leri deploy et
firebase deploy --only firestore:indexes

# 3. UsernameIndex'i güncelle (opsiyonel)
dart run scripts/create_username_index.dart
```

## Deploy Sonuçları

✅ **Firestore Rules**: Başarıyla deploy edildi
✅ **Firestore Indexes**: Başarıyla deploy edildi

### Dikkat Edilmesi Gerekenler

1. **Bilet Görüntüleme**: Uygulamayı yeniden başlatın ve tüm biletlerin görünüp görünmediğini kontrol edin
2. **Chat Username'leri**: Yeni mesajlarda username'ler doğru görünecek, eski mesajlar etkilenmez
3. **Index Build**: Yeni index'lerin oluşması birkaç dakika sürebilir
4. **whereIn Sorgusu**: `status` alanında whereIn kullanımı için composite index gerekebilir

### Test Adımları

1. Farklı status'te biletler oluşturun (available, reserved, draft)
2. Bilet ara sayfasında tüm biletlerin listelendiğini doğrulayın
3. Chat'te mesaj gönderin ve username'lerin doğru göründüğünü kontrol edin
4. Firebase Console'da Rules ve Index'lerin aktif olduğunu doğrulayın
