# Firebase Ayarları

Bu dosya, uygulamanın düzgün çalışması için gerekli Firebase ayarlarını içerir.

## 1. Firebase Authentication
Firebase Console'da Authentication > Sign-in method bölümünde şunları aktifleştirin:

### Phone Authentication
- **Phone** provider'ını aktifleştirin
- **Test phone numbers** bölümünde test numarası ekleyin:
  - Phone number: `+905XXXXXXXXX` (kendi numaranız)
  - Test code: `123456`
- **App verification** ayarlarını kontrol edin
- **reCAPTCHA** ayarlarını yapılandırın

### Email/Password Authentication
- **Email/Password** provider'ını aktifleştirin
- **Email link (passwordless sign-in)** isteğe bağlı

### SMS Doğrulama Sorunları
SMS gelmiyorsa:
1. Test numarası kullanın
2. Telefon numarası formatını kontrol edin (+90 ile başlamalı)
3. Firebase quota limitlerini kontrol edin
4. reCAPTCHA ayarlarını doğrulayın

## 2. Firebase Storage
Firebase Console'da Storage bölümünde:
- Storage'ı etkinleştirin
- Rules'u aşağıdaki gibi güncelleyin:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Users can upload their own profile pictures
    match /users/{userId}/profile/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Ticket images - only sellers can upload, everyone can read
    match /tickets/{ticketId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        resource == null || 
        request.auth.uid == resource.metadata.uploadedBy;
    }
    
    // Chat attachments - only conversation participants
    match /chats/{conversationId}/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 3. Firestore Rules
Firestore Database > Rules bölümünde rules'u güncelleyin:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Tickets collection
    match /tickets/{ticketId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
        request.auth.uid == request.resource.data.sellerId;
      allow update: if request.auth != null && 
        request.auth.uid == resource.data.sellerId;
      allow delete: if request.auth != null && 
        request.auth.uid == resource.data.sellerId;
    }
    
    // Orders collection
    match /orders/{orderId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.buyerId || 
         request.auth.uid == resource.data.sellerId);
    }
    
    // Conversations collection
    match /conversations/{conversationId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.buyerId || 
         request.auth.uid == resource.data.sellerId);
    }
    
    // Messages collection
    match /messages/{messageId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.senderId || 
         request.auth.uid == resource.data.receiverId);
    }
    
    // Payments collection
    match /payments/{paymentId} {
      allow read: if request.auth != null && 
        (request.auth.uid == resource.data.payerId || 
         request.auth.uid == resource.data.payeeId);
      allow write: if false; // Only server can write
    }
  }
}
```

## 4. Firestore Indexes
Firestore Database > Indexes bölümünde şu indexleri oluşturun:

### Tickets Collection
- `sellerId` (Ascending), `createdAt` (Descending)
- `status` (Ascending), `createdAt` (Descending)
- `category` (Ascending), `status` (Ascending), `createdAt` (Descending)
- `city` (Ascending), `status` (Ascending), `createdAt` (Descending)

### Orders Collection
- `buyerId` (Ascending), `createdAt` (Descending)
- `sellerId` (Ascending), `createdAt` (Descending)
- `status` (Ascending), `createdAt` (Descending)

### Conversations Collection
- `buyerId` (Ascending), `lastMessageAt` (Descending)
- `sellerId` (Ascending), `lastMessageAt` (Descending)
- `ticketId` (Ascending), `createdAt` (Descending)

### Messages Collection
- `conversationId` (Ascending), `createdAt` (Ascending)
- `senderId` (Ascending), `createdAt` (Descending)

## 5. App Check (Opsiyonel ama önerilen)
Güvenlik için App Check'i etkinleştirin.

## 6. Extensions (Stripe için)
Eğer Stripe kullanacaksanız, Firebase Extensions'dan "Run Payments with Stripe" extension'ını ekleyin.

Bu ayarları yaptıktan sonra uygulamanın tüm özellikleri çalışacaktır.
