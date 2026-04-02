// lib/core/theme/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

// @riverpod anotasyonu ile state'i yönetecek bir Notifier oluşturuyoruz.
@riverpod
class AppThemeNotifier extends _$AppThemeNotifier {
  // State'in başlangıç değerini belirliyoruz.
  // Varsayılan olarak sistem temasını kullanacak.
  @override
  ThemeMode build() {
    return ThemeMode.system;
  }

  // Temayı değiştirecek metot.
  void setTheme(ThemeMode themeMode) {
    state = themeMode;
  }

  // Temayı toggle edecek metot.
  void toggleTheme() {
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
    } else {
      state = ThemeMode.dark;
    }
  }
}
