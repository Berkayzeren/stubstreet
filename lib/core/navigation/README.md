# 🚀 Swipe-Back Navigation System

Bu dosya, StubStreet uygulamasında **tüm sayfalarda** soldan sağa kaydırarak geri gitme özelliğini implement eder.

## ✨ Özellikler

- **🎯 Global Swipe-Back**: Tüm sayfalarda otomatik olarak aktif
- **📱 Cross-Platform**: Android, iOS ve Web'de tutarlı davranış
- **🎨 Visual Feedback**: Progress indicator ve haptic feedback
- **⚡ Performance**: Smooth animations ve optimize edilmiş gestures
- **🔧 Customizable**: Threshold ve animation settings ayarlanabilir
- **🛡️ Safe**: Edge case'ler ve error handling dahil

## 📁 Dosya Yapısı

```
lib/core/navigation/
├── swipe_back_wrapper.dart        # Ana swipe-back widget
├── custom_page_route.dart         # Custom page transitions
├── route_observer.dart             # Navigation tracking
├── navigation_extensions.dart     # Helper extension methods
└── README.md                      # Bu dosya
```

## 🚀 Kullanım

### 1. Otomatik Aktivasyon (Tüm Sayfalar)

Sistem `main.dart`'ta global olarak aktif edilmiştir. **Hiçbir ek kod gerekmez!**

```dart
// main.dart'ta zaten yapılandırılmış:
MaterialApp(
  pageTransitionsTheme: const CustomPageTransitionsTheme(),
  navigatorObservers: [SwipeBackRouteObserver()],
  // ...
)
```

### 2. Manuel Navigation (Extension Methods)

```dart
// Yeni sayfa açma
context.pushSwipeBack((context) => NewPage());

// Sayfa değiştirme
context.pushReplacementSwipeBack((context) => ReplacementPage());

// Stack temizleme
context.pushAndClearStackSwipeBack((context) => HomePage());
```

### 3. Named Routes (Otomatik Destekli)

```dart
// Named route'lar otomatik olarak swipe-back destekli
Navigator.pushNamed(context, '/profile');
Navigator.pushNamed(context, '/settings');
```

### 4. Custom Ayarlar

```dart
// Özel threshold ile navigation
context.pushSwipeBack(
  (context) => MyPage(),
  swipeThreshold: 0.2, // Daha kolay swipe
  enableSwipeBack: true,
);

// Fullscreen dialog (swipe-back kapalı)
context.pushSwipeBack(
  (context) => FullscreenModal(),
  fullscreenDialog: true, // Swipe-back devre dışı
);
```

## ⚙️ Konfigürasyon

### Swipe Threshold

```dart
// Varsayılan: %30 ekran kaydırma
swipeThreshold: 0.3  

// Kolay swipe: %20
swipeThreshold: 0.2  

// Zor swipe: %50  
swipeThreshold: 0.5
```

### Animation Duration

```dart
// Hızlı animasyon
animationDuration: Duration(milliseconds: 200)

// Varsayılan
animationDuration: Duration(milliseconds: 300)

// Yavaş animasyon
animationDuration: Duration(milliseconds: 500)
```

## 📱 Kullanıcı Deneyimi

### Swipe Gesture

1. **Başlangıç**: Ekranın sol kenarından (20px) sağa kaydırma başlatın
2. **Feedback**: Hafif titreşim ve progress indicator görünür
3. **Progress**: Kaydırma ilerlemesi görsel olarak gösterilir
4. **Threshold**: %30 kaydırma tamamlandığında sayfa otomatik kapanır
5. **Cancel**: %30'dan az kaydırma ile sayfa eski konumuna döner

### Visual Feedback

- **🎯 Progress Indicator**: Sol üstte kaydırma ilerlemesi
- **📳 Haptic Feedback**: Başlangıç, ilerleme ve tamamlama titreşimleri
- **🎨 Animation Effects**: Smooth slide ve scale transitions
- **💫 Shadow Effects**: Arka plan gölgelendirme efekti

## 🛠️ Advanced Usage

### Custom Wrapper

```dart
// Manuel wrapper kullanımı
SwipeBackWrapper(
  enableSwipeBack: true,
  swipeThreshold: 0.25,
  onSwipeStart: () => print('Swipe started'),
  onSwipeComplete: () => print('Swipe completed'),
  onSwipeCancel: () => print('Swipe cancelled'),
  child: MyPageContent(),
)
```

### Route Observer Integration

```dart
// Route değişikliklerini takip etme
SwipeBackRouteObserver().addRouteChangeListener(() {
  print('Route changed: ${SwipeBackRouteObserver().currentRouteName}');
  print('Can swipe back: ${SwipeBackRouteObserver().canSwipeBack}');
});
```

### Navigation Utils

```dart
// Utility methods
SwipeNavigationUtils.navigateToLogin(context);
SwipeNavigationUtils.navigateToHome(context, tabIndex: 1);
SwipeNavigationUtils.goBack(context, result: 'data');

// Route kontrolü
bool isInHome = SwipeNavigationUtils.isRouteInStack(context, '/home');
String? current = SwipeNavigationUtils.getCurrentRouteName(context);
```

## 🐛 Troubleshooting

### Swipe Çalışmıyor

1. **Edge Detection**: Kaydırmayı ekranın sol kenarından başlattığınızdan emin olun
2. **Threshold**: Minimum %30 kaydırma gereklidir
3. **Fullscreen**: Fullscreen dialog'larda swipe-back kapalıdır
4. **Root Page**: Ana sayfa/root'ta swipe-back mevcut değildir

### Performance İssues

1. **Animation**: `animationDuration`'ı azaltın
2. **Threshold**: `swipeThreshold`'ı artırın (daha az hassas)
3. **Disable**: Gereksiz sayfalarda `enableSwipeBack: false` kullanın

### Platform Specific

- **Android**: Sistem back button'ı ile aynı davranışı gösterir
- **iOS**: Native iOS swipe-back davranışını taklit eder  
- **Web**: Mouse/trackpad ile horizontal swipe desteklenir

## 📊 Debug Bilgileri

Debug mode'da console'da şu bilgiler görünür:

```
🚀 Swipe back started at position: 15.0
📏 Swipe progress: 45.2%
✅ Swipe back completed - navigating to previous page
📱 Route popped: MyPage
📚 Current stack depth: 2
```

## 🔄 Future Enhancements

- [ ] Gesture velocity consideration
- [ ] Custom swipe directions (right-to-left for RTL)
- [ ] Per-page swipe customization
- [ ] Predictive back animation (Android 14+)
- [ ] Web mouse gesture support
- [ ] Accessibility improvements

## 💡 Best Practices

1. **Consistent UX**: Tüm sayfalarda aynı threshold kullanın
2. **Visual Feedback**: Progress indicator'ları kullanıcıya gösterin
3. **Performance**: Gereksiz sayfalarda swipe-back'i devre dışı bırakın
4. **Testing**: Farklı cihaz boyutlarında test edin
5. **Accessibility**: Voice-over kullanıcıları için alternatif navigation sağlayın

---

**🎉 Artık tüm sayfalarda swipe-back özelliği aktif! Soldan sağa kaydırarak geri gidebilirsiniz.**
