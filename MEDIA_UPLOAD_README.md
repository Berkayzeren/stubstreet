# Media Upload & Storage Service

Firebase Storage entegrasyonu ile kapsamlı medya yükleme servisi.

## Özellikler

✅ **Abstract MediaUploadService** - İlerleme durumu takibi ile  
✅ **Token tabanlı güvenlik** - Firebase Auth ile güvenli yüklemeler  
✅ **Resim sıkıştırma** - Otomatik resim optimizasyonu  
✅ **Küçük resim oluşturma** - Cloud Functions ile otomatik thumbnail  
✅ **İlerleme durumu takibi** - Gerçek zamanlı yükleme ilerlemesi  
✅ **Dosya doğrulama** - Boyut ve tip kontrolleri  
✅ **Hata yönetimi** - Kapsamlı hata yakalama ve işleme  

## Kurulum

### 1. Bağımlılıklar

```yaml
dependencies:
  firebase_storage: ^12.4.9
  firebase_auth: ^5.6.2
  image_picker: ^1.0.4
  image_cropper: ^5.0.1
  crypto: ^3.0.3
  image: ^4.0.17
  mime: ^1.0.4
```

### 2. Firebase Functions

```bash
cd functions
npm install
```

### 3. Security Rules

`storage.rules` dosyası otomatik olarak yapılandırılmıştır.

## Kullanım

### Basit Resim Yükleme

```dart
class ProfileImageUpload extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MediaUploadWidget(
      userId: 'user123',
      folder: 'profile_images',
      uploadType: MediaUploadType.image,
      onUploadComplete: (result) {
        print('Yükleme tamamlandı: ${result.downloadUrl}');
      },
      onUploadError: (error) {
        print('Yükleme hatası: $error');
      },
    );
  }
}
```

### Manuel Yükleme (Özel Kontrol)

```dart
class CustomUploadExample extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadService = ref.read(mediaUploadServiceProvider);
    
    return ElevatedButton(
      onPressed: () async {
        final result = await uploadService.pickAndUploadProfileImage(
          userId: 'user123',
          context: context,
          onProgress: (progress) {
            print('İlerleme: ${(progress * 100).toStringAsFixed(1)}%');
          },
          onStatusUpdate: (status) {
            print('Durum: $status');
          },
        );
        
        if (result != null) {
          print('Yüklendi: ${result.downloadUrl}');
        }
      },
      child: Text('Profil Resmi Yükle'),
    );
  }
}
```

### Dosya Yükleme

```dart
Future<void> uploadCustomFile() async {
  final uploadService = ref.read(mediaUploadServiceProvider);
  final file = File('path/to/your/file.pdf');
  
  try {
    final result = await uploadService.uploadFile(
      file: file,
      path: 'documents/user123/document.pdf',
      type: MediaUploadType.document,
      metadata: {
        'category': 'legal',
        'uploaded_by': 'user123',
      },
      onProgress: (progress) {
        print('İlerleme: ${(progress * 100).toStringAsFixed(1)}%');
      },
      onStatusUpdate: (status) {
        print('Durum: $status');
      },
    );
    
    print('Dosya yüklendi: ${result.downloadUrl}');
  } catch (e) {
    print('Hata: $e');
  }
}
```

## Cloud Functions

### Resim İşleme
- **processImage**: Yüklenen resimler otomatik olarak işlenir
- **cleanupProcessedImages**: Orijinal resim silindiğinde temizlik yapar
- **getImageVariants**: Resim varyantlarını getirir (thumbnail, compressed)

### Örnek Kullanım

```dart
// Cloud Function ile resim varyantlarını getir
final response = await http.get(
  Uri.parse('https://your-project.cloudfunctions.net/getImageVariants?imagePath=users/123/profile.jpg'),
);

final variants = json.decode(response.body);
print('Thumbnail: ${variants['thumbnail']}');
print('Compressed: ${variants['compressed']}');
```

## Güvenlik

### Firebase Storage Rules

```javascript
// Users can only access their own files
match /users/{userId}/{allPaths=**} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}

// Profile images - readable by all authenticated users
match /profile_images/{userId}/{allPaths=**} {
  allow read: if request.auth != null;
  allow write: if request.auth != null && request.auth.uid == userId;
}
```

### Token Tabanlı Güvenlik

Tüm yüklemeler Firebase Auth token'ları ile güvenli hale getirilmiştir. Presigned URL benzeri işlevsellik için Firebase Auth kullanılır.

## Resim Sıkıştırma

### Yerel Sıkıştırma
```dart
final options = ImageProcessingOptions(
  quality: 85,
  maxWidth: 1024,
  maxHeight: 1024,
  createThumbnail: true,
  thumbnailSize: 200,
);

final result = await uploadService.uploadImageWithProcessing(
  imageFile: imageFile,
  userId: 'user123',
  folder: 'images',
  options: options,
);
```

### Cloud Functions Sıkıştırma
Yüklenen resimler otomatik olarak:
- Thumbnail (200x200) oluşturulur
- Compressed versiyonu (800x600 max) oluşturulur
- Orijinal resim korunur

## Hata Yönetimi

```dart
try {
  final result = await uploadService.uploadFile(/*...*/);
} on MediaUploadException catch (e) {
  switch (e.code) {
    case 'AUTH_ERROR':
      // Kimlik doğrulama hatası
      break;
    case 'VALIDATION_ERROR':
      // Dosya doğrulama hatası
      break;
    case 'UPLOAD_ERROR':
      // Yükleme hatası
      break;
  }
}
```

## Yapılandırma

### Dosya Boyutu Limitleri
- Resim: 5MB
- Video: 50MB
- Belge: 10MB
- Ses: 25MB

### Desteklenen Formatlar
- **Resim**: JPEG, PNG, GIF, WebP
- **Video**: MP4, MOV, AVI
- **Belge**: PDF, TXT, DOC
- **Ses**: MP3, WAV, OGG

## Geliştirici Notları

1. **Resim sıkıştırma** işlemi hem yerel hem de cloud tarafında yapılır
2. **Thumbnail oluşturma** sadece Cloud Functions'da yapılır
3. **Progress tracking** gerçek zamanlı olarak çalışır
4. **Security rules** kullanıcı bazlı erişim kontrolü sağlar
5. **Error handling** katmanlı hata yönetimi sunar

## Test Etme

```bash
# Flutter testleri
flutter test

# Functions testleri
cd functions
npm test

# Emulator ile test
firebase emulators:start
```

## Deployment

```bash
# Storage rules deploy
firebase deploy --only storage

# Functions deploy
firebase deploy --only functions
```
