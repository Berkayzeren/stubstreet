// lib/core/services/app_lifecycle_manager.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_chat_service.dart';
import '../providers/user_preferences_provider.dart';

/// Global uygulama yaşam döngüsü yöneticisi
/// 
/// Bu sınıf, uygulamanın yaşam döngüsü durumlarını takip eder ve
/// kullanıcının çevrimiçi/çevrimdışı durumunu otomatik olarak yönetir.
class AppLifecycleManager with WidgetsBindingObserver {
  final FirebaseChatService _chatService;
  final Ref _ref;
  bool _isInitialized = false;
  Timer? _activityTimer;

  AppLifecycleManager({
    required FirebaseChatService chatService,
    required Ref ref,
  })  : _chatService = chatService,
        _ref = ref;

  /// Lifecycle manager'ı başlat
  void initialize() {
    if (_isInitialized) return;
    
    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;
    
    // Uygulama başlatıldığında kullanıcıyı çevrimiçi yap
    _setUserOnline();
    
    // Periyodik aktivite güncellemesi başlat
    _startActivityTimer();
    
    debugPrint('🔄 AppLifecycleManager başlatıldı');
  }

  /// Lifecycle manager'ı temizle
  void dispose() {
    if (!_isInitialized) return;
    
    WidgetsBinding.instance.removeObserver(this);
    _activityTimer?.cancel();
    _isInitialized = false;
    
    // Uygulama kapatılırken kullanıcıyı çevrimdışı yap
    _setUserOffline();
    
    debugPrint('🔄 AppLifecycleManager temizlendi');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    debugPrint('🔄 Uygulama durumu değişti: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        // Uygulama ön plana geçti - kullanıcıyı çevrimiçi yap ve timer'ı başlat
        _setUserOnline();
        _startActivityTimer();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Uygulama arka plana geçti veya pasif durumda - timer'ı durdur ve çevrimdışı yap
        _activityTimer?.cancel();
        _setUserOffline();
        break;
      case AppLifecycleState.detached:
        // Uygulama tamamen kapatıldı - timer'ı durdur ve çevrimdışı yap
        _activityTimer?.cancel();
        _setUserOffline();
        break;
      case AppLifecycleState.hidden:
        // Uygulama gizlendi - timer'ı durdur ve çevrimdışı yap
        _activityTimer?.cancel();
        _setUserOffline();
        break;
    }
  }

  /// Kullanıcıyı çevrimiçi duruma geç
  void _setUserOnline() {
    try {
      // Kullanıcı tercihleri kontrol et
      final userPrefs = _ref.read(userPreferencesProvider);
      if (!userPrefs.showOnlineStatus) {
        debugPrint('🔄 Kullanıcı çevrimiçi durumu gizleme tercihinde - online durumu güncellenmedi');
        return;
      }

      _chatService.setUserOnline();
      debugPrint('✅ Kullanıcı çevrimiçi duruma geçti');
    } catch (e) {
      debugPrint('❌ Kullanıcı çevrimiçi duruma geçirilirken hata: $e');
    }
  }

  /// Kullanıcıyı çevrimdışı duruma geç
  void _setUserOffline() {
    try {
      _chatService.setUserOffline();
      debugPrint('📴 Kullanıcı çevrimdışı duruma geçti');
    } catch (e) {
      debugPrint('❌ Kullanıcı çevrimdışı duruma geçirilirken hata: $e');
    }
  }

  /// Manuel olarak kullanıcı durumunu güncelle
  void updateUserPresence({required bool isOnline}) {
    if (isOnline) {
      _setUserOnline();
    } else {
      _setUserOffline();
    }
  }

  /// Periyodik aktivite güncellemesi başlat
  void _startActivityTimer() {
    _activityTimer?.cancel();
    
    // Her 2 dakikada bir aktivite güncelle
    _activityTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      try {
        final userPrefs = _ref.read(userPreferencesProvider);
        if (userPrefs.showOnlineStatus) {
          _chatService.setUserOnline();
        }
      } catch (e) {
        debugPrint('❌ Periyodik aktivite güncellemesi hatası: $e');
      }
    });
    
    debugPrint('⏰ Aktivite timer başlatıldı');
  }
}

/// AppLifecycleManager provider'ı
final appLifecycleManagerProvider = Provider<AppLifecycleManager>((ref) {
  final manager = AppLifecycleManager(
    chatService: FirebaseChatService(),
    ref: ref,
  );
  
  // Provider dispose edildiğinde manager'ı temizle
  ref.onDispose(() {
    manager.dispose();
  });
  
  return manager;
});
