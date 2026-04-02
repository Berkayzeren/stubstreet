# Firebase Auth Middleware

Firebase ID token doğrulayan middleware.

## Özellikler

- Firebase ID token doğrulama
- Hata durumunda 401 HTTP kodu döndürür
- Başarılı olduğunda `req.user = decodedToken` atar
- Türkçe hata mesajları

## Kullanım

```javascript
const authMiddleware = require('./middleware/authMiddleware');

// Korumalı route
app.get('/protected-route', authMiddleware, (req, res) => {
  res.json({
    message: 'Bu korumalı bir route',
    user: {
      uid: req.user.uid,
      email: req.user.email,
      name: req.user.name
    }
  });
});
```

## Request Header Formatı

```
Authorization: Bearer <firebase_id_token>
```

## Hata Durumları

### 401 - Authorization header gerekli
```json
{
  "error": "Authorization header gerekli"
}
```

### 401 - ID token gerekli
```json
{
  "error": "ID token gerekli"
}
```

### 401 - Geçersiz token
```json
{
  "error": "Geçersiz token",
  "details": "Token verification failed"
}
```

## Başarılı Durum

Token doğrulandıktan sonra `req.user` objesi şu bilgileri içerir:

```javascript
req.user = {
  uid: "kullanıcı_id",
  email: "kullanıcı@email.com",
  name: "Kullanıcı Adı",
  // diğer Firebase auth claims
}
```
