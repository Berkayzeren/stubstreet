// lib/core/providers/language_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_provider.dart'; // For SharedPreferences provider

/// Supported languages enum
enum AppLanguage {
  turkish('tr', 'TR', 'Türkçe'),
  english('en', 'US', 'English');

  const AppLanguage(this.languageCode, this.countryCode, this.displayName);

  final String languageCode;
  final String countryCode;
  final String displayName;

  Locale get locale => Locale(languageCode, countryCode);
}

/// Language notifier to manage app language state
class LanguageNotifier extends StateNotifier<Locale> {
  final SharedPreferences _prefs;

  LanguageNotifier(this._prefs) : super(_loadLanguageFromPrefs(_prefs));

  /// Load saved language from SharedPreferences
  static Locale _loadLanguageFromPrefs(SharedPreferences prefs) {
    final languageCode = prefs.getString('appLanguage');
    
    switch (languageCode) {
      case 'tr':
        return AppLanguage.turkish.locale;
      case 'en':
        return AppLanguage.english.locale;
      case 'system':
        // Follow device language if explicitly set to system
        final device = WidgetsBinding.instance.platformDispatcher.locale;
        final code = device.languageCode.toLowerCase();
        return code.startsWith('tr') ? AppLanguage.turkish.locale : AppLanguage.english.locale;
      default:
        // No preference saved: follow device language (TR => Turkish, otherwise English)
        final device = WidgetsBinding.instance.platformDispatcher.locale;
        final code = device.languageCode.toLowerCase();
        return code.startsWith('tr') ? AppLanguage.turkish.locale : AppLanguage.english.locale;
    }
  }

  /// Set app language and save to preferences
  Future<void> setLanguage(AppLanguage language) async {
    state = language.locale;
    await _prefs.setString('appLanguage', language.languageCode);
  }

  /// Get current language enum
  AppLanguage get currentLanguage {
    switch (state.languageCode) {
      case 'en':
        return AppLanguage.english;
      case 'tr':
      default:
        return AppLanguage.turkish;
    }
  }

  /// Get display name for current language
  String get currentLanguageDisplayName => currentLanguage.displayName;

  /// Get available languages
  List<AppLanguage> get availableLanguages => AppLanguage.values;

  /// Check if language is supported
  bool isLanguageSupported(String languageCode) {
    return AppLanguage.values.any((lang) => lang.languageCode == languageCode);
  }
}

/// Language provider
final languageNotifierProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LanguageNotifier(prefs);
});
