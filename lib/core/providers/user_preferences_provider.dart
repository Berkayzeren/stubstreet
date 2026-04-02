// lib/core/providers/user_preferences_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Kullanıcı profili tercihleri
class UserPreferences {
  final bool profileVisibility;
  final bool showOnlineStatus;
  final bool allowDirectMessages;
  final bool autoPlayVideos;
  final bool autoPlayAudio;
  final bool showReadReceipts;
  final bool dataUsageOptimization;
  final String defaultCurrency;
  final bool showLocationInProfile;
  final bool allowProfileSearch;

  const UserPreferences({
    this.profileVisibility = true,
    this.showOnlineStatus = true,
    this.allowDirectMessages = true,
    this.autoPlayVideos = false,
    this.autoPlayAudio = false,
    this.showReadReceipts = true,
    this.dataUsageOptimization = false,
    this.defaultCurrency = 'TRY',
    this.showLocationInProfile = false,
    this.allowProfileSearch = true,
  });

  /// Create copy with modified values
  UserPreferences copyWith({
    bool? profileVisibility,
    bool? showOnlineStatus,
    bool? allowDirectMessages,
    bool? autoPlayVideos,
    bool? autoPlayAudio,
    bool? showReadReceipts,
    bool? dataUsageOptimization,
    String? defaultCurrency,
    bool? showLocationInProfile,
    bool? allowProfileSearch,
  }) {
    return UserPreferences(
      profileVisibility: profileVisibility ?? this.profileVisibility,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      allowDirectMessages: allowDirectMessages ?? this.allowDirectMessages,
      autoPlayVideos: autoPlayVideos ?? this.autoPlayVideos,
      autoPlayAudio: autoPlayAudio ?? this.autoPlayAudio,
      showReadReceipts: showReadReceipts ?? this.showReadReceipts,
      dataUsageOptimization: dataUsageOptimization ?? this.dataUsageOptimization,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      showLocationInProfile: showLocationInProfile ?? this.showLocationInProfile,
      allowProfileSearch: allowProfileSearch ?? this.allowProfileSearch,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'profileVisibility': profileVisibility,
      'showOnlineStatus': showOnlineStatus,
      'allowDirectMessages': allowDirectMessages,
      'autoPlayVideos': autoPlayVideos,
      'autoPlayAudio': autoPlayAudio,
      'showReadReceipts': showReadReceipts,
      'dataUsageOptimization': dataUsageOptimization,
      'defaultCurrency': defaultCurrency,
      'showLocationInProfile': showLocationInProfile,
      'allowProfileSearch': allowProfileSearch,
    };
  }

  /// Create from JSON storage
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      profileVisibility: json['profileVisibility'] ?? true,
      showOnlineStatus: json['showOnlineStatus'] ?? true,
      allowDirectMessages: json['allowDirectMessages'] ?? true,
      autoPlayVideos: json['autoPlayVideos'] ?? false,
      autoPlayAudio: json['autoPlayAudio'] ?? false,
      showReadReceipts: json['showReadReceipts'] ?? true,
      dataUsageOptimization: json['dataUsageOptimization'] ?? false,
      defaultCurrency: json['defaultCurrency'] ?? 'TRY',
      showLocationInProfile: json['showLocationInProfile'] ?? false,
      allowProfileSearch: json['allowProfileSearch'] ?? true,
    );
  }
}

/// Kullanıcı tercihleri yöneticisi
class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  static const String _localPrefsKey = 'user_preferences';
  
  UserPreferencesNotifier() : super(const UserPreferences()) {
    _loadPreferences();
  }

  /// Load preferences from both local and Firebase
  Future<void> _loadPreferences() async {
    try {
      // Önce local'dan yükle (hızlı başlangıç için)
      await _loadLocalPreferences();
      
      // Sonra Firebase'den senkronize et
      await _syncFromFirebase();
    } catch (e) {
      debugPrint('Failed to load user preferences: $e');
    }
  }

  /// Load from SharedPreferences (local backup)
  Future<void> _loadLocalPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsString = prefs.getString(_localPrefsKey);
      if (prefsString != null) {
        final prefsMap = Map<String, dynamic>.from(
          Uri.decodeComponent(prefsString).split('&').fold<Map<String, dynamic>>(
            {},
            (map, pair) {
              final parts = pair.split('=');
              if (parts.length == 2) {
                map[parts[0]] = parts[1] == 'true' ? true : parts[1] == 'false' ? false : parts[1];
              }
              return map;
            },
          ),
        );
        state = UserPreferences.fromJson(prefsMap);
      }
    } catch (e) {
      debugPrint('Failed to load local preferences: $e');
    }
  }

  /// Save to both local and Firebase
  Future<void> _savePreferences() async {
    try {
      // Local'a kaydet (hızlı erişim için)
      await _saveLocalPreferences();
      
      // Firebase'e kaydet (senkronizasyon için)
      await _saveToFirebase();
    } catch (e) {
      debugPrint('Failed to save preferences: $e');
    }
  }

  /// Save to SharedPreferences
  Future<void> _saveLocalPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsMap = state.toJson();
      final prefsString = prefsMap.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      await prefs.setString(_localPrefsKey, Uri.encodeComponent(prefsString));
    } catch (e) {
      debugPrint('Failed to save local preferences: $e');
    }
  }

  /// Sync from Firebase
  Future<void> _syncFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('userProfiles')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final preferences = data['preferences'] as Map<String, dynamic>?;
        if (preferences != null) {
          state = UserPreferences.fromJson(preferences);
          // Local'a da kaydet
          await _saveLocalPreferences();
        }
      }
    } catch (e) {
      debugPrint('Failed to sync from Firebase: $e');
    }
  }

  /// Save to Firebase
  Future<void> _saveToFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('userProfiles')
          .doc(user.uid)
          .set({
        'preferences': state.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to save to Firebase: $e');
    }
  }

  // Preference update methods
  Future<void> toggleProfileVisibility() async {
    state = state.copyWith(profileVisibility: !state.profileVisibility);
    await _savePreferences();
  }

  Future<void> toggleOnlineStatus() async {
    state = state.copyWith(showOnlineStatus: !state.showOnlineStatus);
    await _savePreferences();
  }

  Future<void> toggleDirectMessages() async {
    state = state.copyWith(allowDirectMessages: !state.allowDirectMessages);
    await _savePreferences();
  }

  Future<void> toggleAutoPlayVideos() async {
    state = state.copyWith(autoPlayVideos: !state.autoPlayVideos);
    await _savePreferences();
  }

  Future<void> toggleAutoPlayAudio() async {
    state = state.copyWith(autoPlayAudio: !state.autoPlayAudio);
    await _savePreferences();
  }

  Future<void> toggleReadReceipts() async {
    state = state.copyWith(showReadReceipts: !state.showReadReceipts);
    await _savePreferences();
  }

  Future<void> toggleDataOptimization() async {
    state = state.copyWith(dataUsageOptimization: !state.dataUsageOptimization);
    await _savePreferences();
  }

  Future<void> setDefaultCurrency(String currency) async {
    state = state.copyWith(defaultCurrency: currency);
    await _savePreferences();
  }

  Future<void> toggleLocationInProfile() async {
    state = state.copyWith(showLocationInProfile: !state.showLocationInProfile);
    await _savePreferences();
  }

  Future<void> toggleProfileSearch() async {
    state = state.copyWith(allowProfileSearch: !state.allowProfileSearch);
    await _savePreferences();
  }

  /// Force sync from Firebase (kullanıcı manuel olarak senkronize etmek isterse)
  Future<void> forceSyncFromFirebase() async {
    await _syncFromFirebase();
  }

  /// Export preferences for backup
  Map<String, dynamic> exportPreferences() {
    return state.toJson();
  }

  /// Import preferences from backup
  Future<void> importPreferences(Map<String, dynamic> preferences) async {
    state = UserPreferences.fromJson(preferences);
    await _savePreferences();
  }
}

/// Provider for user preferences
final userPreferencesProvider = StateNotifierProvider<UserPreferencesNotifier, UserPreferences>(
  (ref) => UserPreferencesNotifier(),
);
