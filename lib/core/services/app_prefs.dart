// lib/core/services/app_prefs.dart

import 'package:hive_flutter/hive_flutter.dart';

class AppPrefs {
  static const String _boxName = 'app_prefs';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyIsGuestUser = 'is_guest_user';

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
    _initialized = true;
  }

  static bool getOnboardingCompleted() {
    final box = Hive.box(_boxName);
    return (box.get(_keyOnboardingCompleted, defaultValue: false) as bool?) ?? false;
  }

  static Future<void> setOnboardingCompleted(bool value) async {
    final box = Hive.box(_boxName);
    await box.put(_keyOnboardingCompleted, value);
  }

  /// Development helper: Reset onboarding to show it again
  /// Onboarding'i sıfırlayıp tekrar göstermek için geliştirici yardımcısı
  static Future<void> resetOnboarding() async {
    await setOnboardingCompleted(false);
  }

  // Guest user functionality
  static bool getIsGuestUser() {
    final box = Hive.box(_boxName);
    return (box.get(_keyIsGuestUser, defaultValue: false) as bool?) ?? false;
  }

  static Future<void> setIsGuestUser(bool value) async {
    final box = Hive.box(_boxName);
    await box.put(_keyIsGuestUser, value);
  }

  static Future<void> clearGuestMode() async {
    await setIsGuestUser(false);
  }
}


