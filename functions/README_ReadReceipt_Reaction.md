# ReadReceipt ve Reaction Yardımcı Fonksiyonları

Bu dokümanda `readReceipts` ve `messages` koleksiyonlarını güncelleme için yazılmış yardımcı fonksiyonlar açıklanmaktadır.

## Yardımcı Fonksiyonlar

### 1. `createReadReceipt(messageId, userId, conversationId)`

Bir mesaj için read receipt oluşturur.

**Parametreler:**
- `messageId` (string): Mesaj ID'si
- `userId` (string): Kullanıcı ID'si
- `conversationId` (string): Konuşma ID'si

**Dönen Değer:** 
- `Promise<Object>`: Read receipt bilgisi

**Kullanım Örneği:**
```javascript
const readReceipt = await createReadReceipt('messageId123', 'userId456', 'conversationId789');
```

### 2. `updateMessageStatus(messageId, status, userId)`

Mesaj durumunu günceller.

**Parametreler:**
- `messageId` (string): Mesaj ID'si
- `status` (string): Yeni durum ('sent', 'delivered', 'read')
- `userId` (string, opsiyonel): Kullanıcı ID'si

**Dönen Değer:**
- `Promise<Object>`: Güncellenmiş mesaj bilgisi

**Kullanım Örneği:**
```javascript
await updateMessageStatus('messageId123', 'read', 'userId456');
```

### 3. `toggleReaction(messageId, emoji, userId)`

Mesaj reaksiyonunu toggle eder (ekler/kaldırır).

**Parametreler:**
- `messageId` (string): Mesaj ID'si
- `emoji` (string): Emoji karakteri
- `userId` (string): Kullanıcı ID'si

**Dönen Değer:**
- `Promise<Object>`: Güncellenmiş reaksiyon bilgisi

**Kullanım Örneği:**
```javascript
const result = await toggleReaction('messageId123', '👍', 'userId456');
// result.action: 'added' veya 'removed'
```

## API Endpoints

### 1. PUT `/v1/messages/:mid/read`

Mesajı okundu olarak işaretler ve read receipt oluşturur.

**Response:**
```json
{
  "success": true,
  "data": {
    "messageId": "messageId123",
    "readReceipt": {
      "id": "receiptId",
      "messageId": "messageId123",
      "userId": "userId456",
      "conversationId": "conversationId789",
      "readAt": "2024-01-01T12:00:00Z"
    }
  },
  "error": null
}
```

### 2. POST `/v1/messages/:mid/reactions`

Mesaja reaksiyon ekler veya kaldırır.

**Request Body:**
```json
{
  "emoji": "👍"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "messageId": "messageId123",
    "emoji": "👍",
    "userId": "userId456",
    "action": "added"
  },
  "error": null
}
```

### 3. GET `/v1/messages/:mid/read-receipts`

Mesajın read receipt'lerini getirir.

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "receiptId",
      "messageId": "messageId123",
      "userId": "userId456",
      "conversationId": "conversationId789",
      "readAt": "2024-01-01T12:00:00Z"
    }
  ],
  "error": null
}
```

### 4. GET `/v1/messages/:mid/reactions`

Mesajın reaksiyonlarını getirir.

**Response:**
```json
{
  "success": true,
  "data": {
    "messageId": "messageId123",
    "reactions": {
      "👍": [
        {
          "userId": "userId456",
          "createdAt": "2024-01-01T12:00:00Z"
        }
      ],
      "❤️": [
        {
          "userId": "userId789",
          "createdAt": "2024-01-01T12:05:00Z"
        }
      ]
    },
    "totalReactions": 2
  },
  "error": null
}
```

## Veritabanı Koleksiyonları

### `readReceipts` Koleksiyonu

```json
{
  "messageId": "string",
  "userId": "string",
  "conversationId": "string",
  "readAt": "timestamp"
}
```

### `messages` Koleksiyonu - Güncellenmiş Şema

```json
{
  "conversationId": "string",
  "senderId": "string",
  "content": "string",
  "timestamp": "timestamp",
  "status": "string",
  "statusUpdatedAt": "timestamp",
  "readBy": ["userId1", "userId2"],
  "reactions": [
    {
      "emoji": "👍",
      "userId": "userId456",
      "createdAt": "timestamp"
    }
  ]
}
```

## Hata Yönetimi

Tüm yardımcı fonksiyonlar hataları yakalar ve console'a loglar. API endpoint'leri uygun HTTP durum kodları ile hata mesajları döner:

- `400`: Geçersiz parametreler
- `403`: Yetkisiz erişim
- `404`: Bulunamayan kaynak
- `500`: Sunucu hatası

## Güvenlik

- Tüm endpoint'ler `authMiddleware` ile korunmuştur
- Kullanıcılar sadece üyesi oldukları konuşmalardaki mesajlara erişebilir
- Read receipt'ler yalnızca mesajın alıcısı tarafından oluşturulabilir
- Reaksiyonlar kullanıcı bazında kontrol edilir
