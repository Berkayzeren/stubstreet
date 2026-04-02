# 🎬 Stub Street Animasyon Sistemi

Bu klasör Stub Street uygulamasının kapsamlı animasyon sistemini içerir. Tüm animasyonlar performans ve kullanıcı deneyimi gözetilerek tasarlanmıştır.

## 📦 Animasyon Modülleri

### 1. **app_animations.dart** - Temel Animasyonlar
- `AppAnimations` sınıfı - Merkezi animasyon yönetimi
- `AnimatedButton` - Buton press animasyonları
- `SuccessAnimation` - Başarı durumu animasyonları
- `ErrorShakeAnimation` - Hata titreme efekti
- `SkeletonLoader` - Skeleton loading
- `StaggeredListAnimation` - Liste animasyonları

### 2. **feedback_animations.dart** - Kullanıcı Geri Bildirimi
- `FeedbackAnimations` sınıfı - Snackbar ve toast animasyonları
- `AnimatedSuccessMessage` - Başarı mesajları
- `AnimatedErrorMessage` - Hata mesajları
- `FormErrorAnimationWrapper` - Form validasyon animasyonları
- `AchievementUnlockDialog` - Başarı kilidi açma

### 3. **enhanced_loading.dart** - Gelişmiş Loading
- `EnhancedLoading` sınıfı - Skeleton ve shimmer efektleri
- `PulseLoadingButton` - Buton loading efekti
- `TypingTextAnimation` - Yazı yazma animasyonu
- Çeşitli skeleton layout'ları (mesaj listesi, profil, bilet)

### 4. **chat_animations.dart** - Chat Animasyonları
- `ChatAnimations` sınıfı - Chat'e özel animasyonlar
- Message send/status animasyonları
- Typing indicator animasyonları
- Connection status göstergeleri
- Reaction animasyonları

### 5. **page_transitions.dart** - Sayfa Geçişleri
- `PageTransitions` sınıfı - Custom page routes
- Slide, fade, scale, bottom sheet geçişleri
- `NavigatorAnimationExtensions` - Navigator extensions
- Shared axis transitions

### 6. **notification_animations.dart** - Bildirim Animasyonları
- `NotificationAnimations` sınıfı - Notification system
- Banner, toast, popup notifications
- Floating notifications
- Auto-dismiss ve progress indicators

### 7. **gallery_animations.dart** - Galeri Animasyonları
- `GalleryAnimations` sınıfı - Media gallery
- Hero transitions
- Zoom ve pan gestures
- `GalleryOverlay` - Fullscreen gallery
- `AnimatedImageCard` - Resim kartları

## 🚀 Kullanım Örnekleri

### Temel Animasyonlar
```dart
import 'package:stubstreet/core/animations/index.dart';

// Animasyonlu buton
AnimatedButton(
  onPressed: () => print('Pressed!'),
  child: Text('Tıkla'),
)

// Skeleton loader
SkeletonLoader(width: 200, height: 20)

// Başarı animasyonu
SuccessAnimation(
  show: isSuccess,
  child: Icon(Icons.check),
)
```

### Sayfa Geçişleri
```dart
// Sağdan kayarak gelen sayfa
Navigator.of(context).push(
  PageTransitions.slideFromRight(page: NewPage()),
);

// Navigator extension kullanımı
Navigator.of(context).pushSlideFromRight(NewPage());
```

### Bildirimler
```dart
// Banner notification
NotificationAnimations.showNotificationBanner(
  context: context,
  title: 'Yeni Mesaj',
  message: 'Ali sana bir mesaj gönderdi',
  icon: Icons.message,
);

// Toast bildirim
NotificationAnimations.showToast(
  context: context,
  message: 'İşlem başarılı!',
  icon: Icons.check,
);
```

### Chat Animasyonları
```dart
// Mesaj gönderme animasyonu
ChatAnimations.animatedMessageSend(
  child: MessageWidget(),
  isLoading: isSending,
)

// Typing indicator
ChatAnimations.animatedTypingIndicator(
  typingUsers: ['Ali', 'Veli'],
)
```

### Galeri Kullanımı
```dart
// Animasyonlu resim kartı
AnimatedImageCard(
  imageUrl: 'https://example.com/image.jpg',
  heroTag: 'image_1',
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => GalleryOverlay(
        images: imageList,
        heroTag: 'image_1',
      ),
    ),
  ),
)
```

## ⚡ Performance Tips

1. **AnimationController Dispose**: Her zaman dispose() edin
2. **Conditional Animations**: Gereksiz animasyonları koşullu yapın
3. **Throttling**: Hızlı değişen değerler için debounce kullanın
4. **Memory Management**: Büyük resimler için cache yönetimi

## 🎨 Customization

Animasyonları özelleştirmek için `AppAnimations` sınıfındaki sabitleri kullanın:

```dart
class AppAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve bounce = Curves.elasticOut;
}
```

## 🔧 Import Kullanımı

Tüm animasyonları tek import ile kullanın:
```dart
import 'package:stubstreet/core/animations/index.dart';
```

Veya spesifik modülleri import edin:
```dart
import 'package:stubstreet/core/animations/app_animations.dart';
import 'package:stubstreet/core/animations/page_transitions.dart';
```
