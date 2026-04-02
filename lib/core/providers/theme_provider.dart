// lib/core/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences provider must be overridden in main');
});

/// Theme mode provider for managing app-wide theme preferences
/// Supports system, light, and dark themes with persistent storage
final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(),
);

/// Notification for theme changes with SharedPreferences persistence
class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const String _themeKey = 'theme_mode';
  
  /// Initialize with system theme as default
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  /// Load saved theme preference from SharedPreferences
  /// Falls back to system theme if no preference is saved
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey);
      if (themeIndex != null) {
        // Convert stored integer back to ThemeMode enum
        state = ThemeMode.values[themeIndex];
      }
    } catch (e) {
      // If loading fails, keep system default
      state = ThemeMode.system;
    }
  }

  /// Save theme preference to SharedPreferences
  /// Stores the theme mode as an integer index for persistence
  Future<void> _saveTheme(ThemeMode theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, theme.index);
    } catch (e) {
      // Silently fail if saving fails - theme will still work in memory
      debugPrint('Failed to save theme preference: $e');
    }
  }

  /// Toggle between light and dark themes
  /// If currently system, switches to light first
  Future<void> toggleTheme() async {
    ThemeMode newTheme;
    
    switch (state) {
      case ThemeMode.system:
        newTheme = ThemeMode.light;
        break;
      case ThemeMode.light:
        newTheme = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        newTheme = ThemeMode.light;
        break;
    }
    
    state = newTheme;
    await _saveTheme(newTheme);
  }

  /// Set specific theme mode
  /// Useful for settings where user can pick exact mode
  Future<void> setTheme(ThemeMode theme) async {
    state = theme;
    await _saveTheme(theme);
  }

  /// Get current theme display name for UI
  String get themeDisplayName {
    switch (state) {
      case ThemeMode.system:
        return 'Sistem';
      case ThemeMode.light:
        return 'Açık';
      case ThemeMode.dark:
        return 'Koyu';
    }
  }

  /// Check if current theme is dark (considering system theme)
  bool isDark(BuildContext context) {
    switch (state) {
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
    }
  }
}

/// Provider for notification preferences with persistent storage
final notificationPreferencesProvider = StateNotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
  (ref) => NotificationPreferencesNotifier(),
);

/// Notification preferences data class
class NotificationPreferences {
  final bool pushNotifications;
  final bool emailNotifications;
  final bool messageNotifications;
  final bool ticketNotifications;

  const NotificationPreferences({
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.messageNotifications = true,
    this.ticketNotifications = true,
  });

  /// Create copy with modified values
  NotificationPreferences copyWith({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? messageNotifications,
    bool? ticketNotifications,
  }) {
    return NotificationPreferences(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      messageNotifications: messageNotifications ?? this.messageNotifications,
      ticketNotifications: ticketNotifications ?? this.ticketNotifications,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'messageNotifications': messageNotifications,
      'ticketNotifications': ticketNotifications,
    };
  }

  /// Create from JSON storage
  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      pushNotifications: json['pushNotifications'] ?? true,
      emailNotifications: json['emailNotifications'] ?? true,
      messageNotifications: json['messageNotifications'] ?? true,
      ticketNotifications: json['ticketNotifications'] ?? true,
    );
  }
}

/// Notification preferences manager with SharedPreferences persistence
class NotificationPreferencesNotifier extends StateNotifier<NotificationPreferences> {
  static const String _prefsKey = 'notification_preferences';

  /// Initialize with default preferences
  NotificationPreferencesNotifier() : super(const NotificationPreferences()) {
    _loadPreferences();
  }

  /// Load notification preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsString = prefs.getString(_prefsKey);
      if (prefsString != null) {
        final prefsMap = Map<String, dynamic>.from(
          Uri.decodeComponent(prefsString).split('&').fold<Map<String, String>>(
            {},
            (map, pair) {
              final parts = pair.split('=');
              if (parts.length == 2) {
                map[parts[0]] = parts[1];
              }
              return map;
            },
          ),
        );
        state = NotificationPreferences.fromJson(prefsMap);
      }
    } catch (e) {
      // Keep default preferences if loading fails
      debugPrint('Failed to load notification preferences: $e');
    }
  }

  /// Save notification preferences to SharedPreferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsMap = state.toJson();
      final prefsString = prefsMap.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      await prefs.setString(_prefsKey, Uri.encodeComponent(prefsString));
    } catch (e) {
      debugPrint('Failed to save notification preferences: $e');
    }
  }

  /// Toggle push notifications
  Future<void> togglePushNotifications() async {
    state = state.copyWith(pushNotifications: !state.pushNotifications);
    await _savePreferences();
  }

  /// Toggle email notifications
  Future<void> toggleEmailNotifications() async {
    state = state.copyWith(emailNotifications: !state.emailNotifications);
    await _savePreferences();
  }

  /// Toggle message notifications
  Future<void> toggleMessageNotifications() async {
    state = state.copyWith(messageNotifications: !state.messageNotifications);
    await _savePreferences();
  }

  /// Toggle ticket notifications
  Future<void> toggleTicketNotifications() async {
    state = state.copyWith(ticketNotifications: !state.ticketNotifications);
    await _savePreferences();
  }
}
