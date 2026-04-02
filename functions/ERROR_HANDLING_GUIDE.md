# Hata Yönetimi ve Ortak Yanıt Formatı

Bu proje global hata yönetimi ve ortak yanıt formatı kullanmaktadır. Tüm API yanıtları standardize edilmiş format ile döndürülür.

## Ortak Yanıt Formatı

### Başarılı Yanıt
```json
{
  "success": true,
  "data": { ... },
  "error": null,
  "timestamp": "2024-01-01T00:00:00.000Z",
  "message": "İşlem başarılı" // opsiyonel
}
```

### Hata Yanıtı
```json
{
  "success": false,
  "data": null,
  "error": "Hata mesajı",
  "details": "Hata detayları", // opsiyonel
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### Validation Hatası (422)
```json
{
  "success": false,
  "data": null,
  "error": "Validation hatası",
  "details": [
    {
      "field": "email",
      "message": "Geçerli email adresi gerekli",
      "value": "invalid-email"
    }
  ],
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### Sayfalama ile Yanıt
```json
{
  "success": true,
  "data": [...],
  "error": null,
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 50,
    "totalPages": 5,
    "hasNext": true,
    "hasPrev": false
  },
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

## Hata Kodları

- **400**: Hatalı istek
- **401**: Yetkilendirme hatası
- **403**: Erişim reddedildi
- **404**: Kaynak bulunamadı
- **409**: Çakışma hatası
- **422**: Validation hatası
- **429**: Çok fazla istek
- **500**: Sunucu hatası

## Kullanım

### Response Helper Fonksiyonları

```javascript
const { 
  successResponse, 
  errorResponse, 
  validationErrorResponse,
  paginatedResponse,
  unauthorizedResponse,
  forbiddenResponse,
  notFoundResponse,
  conflictResponse,
  serverErrorResponse
} = require('./utils/responseHelper');

// Başarılı yanıt
return successResponse(res, data, 'İşlem başarılı');

// Hata yanıtı
return errorResponse(res, 'Hata mesajı', 400);

// Validation hatası
return validationErrorResponse(res, validationErrors);

// Sayfalama ile yanıt
return paginatedResponse(res, data, pagination);

// Özel hata yanıtları
return unauthorizedResponse(res, 'Giriş yapmanız gerekli');
return forbiddenResponse(res, 'Bu işlem için yetkiniz yok');
return notFoundResponse(res, 'Kaynak bulunamadı');
```

### Middleware Kullanımı

```javascript
const { errorHandler, validationHandler, notFoundHandler, asyncHandler } = require('./middleware/errorHandler');

// Route'larda validation middleware'i kullanma
app.post('/api/users', 
  [
    body('email').isEmail().withMessage('Geçerli email gerekli'),
    body('name').notEmpty().withMessage('İsim gerekli')
  ],
  validationHandler, // Validation hatalarını yakalar
  asyncHandler(async (req, res) => {
    // Async işlemler
    const user = await createUser(req.body);
    return successResponse(res, user, 'Kullanıcı oluşturuldu', 201);
  })
);

// Global error handler'lar (app.js'in sonuna ekleyin)
app.use(notFoundHandler); // 404 handler
app.use(errorHandler); // Global error handler
```

### Async Handler Kullanımı

```javascript
// Async fonksiyonlardaki hataları otomatik yakalar
app.get('/api/users/:id', 
  asyncHandler(async (req, res) => {
    const user = await getUserById(req.params.id);
    if (!user) {
      return notFoundResponse(res, 'Kullanıcı bulunamadı');
    }
    return successResponse(res, user);
  })
);
```

### Hata Fırlatma

```javascript
// Hata fırlatma örnekleri
const err = new Error('Özel hata mesajı');
err.status = 400;
throw err; // veya next(err);

// Validation hatası için
const validationError = new Error('Validation hatası');
validationError.status = 422;
validationError.validationErrors = errors.array();
throw validationError;
```

## Test Endpoint'leri

Hata yönetimi sistemini test etmek için aşağıdaki endpoint'leri kullanabilirsiniz:

```bash
# Validation testi (422 hatası)
curl -X POST http://localhost:3000/test/validation \
  -H "Content-Type: application/json" \
  -d '{"email": "invalid-email", "age": 150, "name": ""}'

# 404 testi
curl http://localhost:3000/test/404

# 500 testi
curl http://localhost:3000/test/500

# Auth testi (401 hatası)
curl http://localhost:3000/test/auth

# Auth testi (geçerli token ile)
curl http://localhost:3000/test/auth \
  -H "Authorization: Bearer your-firebase-token"
```

## Geliştirme Notları

1. **Hata Yakalama**: Tüm async işlemler `asyncHandler` ile sarılmalı
2. **Validation**: `validationHandler` middleware'i validation hatalarını otomatik yakalar
3. **Standart Yanıt**: Her zaman response helper fonksiyonlarını kullanın
4. **Hata Fırlatma**: `next(err)` ile hataları global handler'a gönderin
5. **Logging**: Hatalar otomatik olarak console.error ile loglanır

Bu sistem sayesinde tüm API yanıtları tutarlı format ile döndürülür ve hata yönetimi merkezi olarak yapılır.
