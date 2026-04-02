import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FeatureFlagService {
  static const String _enhancedMessagingKey = 'enhanced_messaging_enabled';
  static const String _attachmentSharingKey = 'attachment_sharing_enabled';
  static const String _voiceMessagesKey = 'voice_messages_enabled';
  static const String _messagingAnalyticsKey = 'messaging_analytics_enabled';
  
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  static final FeatureFlagService _instance = FeatureFlagService._internal();
  factory FeatureFlagService() => _instance;
  FeatureFlagService._internal();

  // Default feature flags - can be overridden by remote config
  static const Map<String, bool> _defaultFlags = {
    _enhancedMessagingKey: true,
    _attachmentSharingKey: true,
    _voiceMessagesKey: false,
    _messagingAnalyticsKey: true,
  };

  // Cache for feature flags
  final Map<String, bool> _flagsCache = {};

  /// Initialize the feature flag service
  Future<void> init() async {
    await _loadFlags();
  }

  /// Load feature flags from local storage
  Future<void> _loadFlags() async {
    for (final key in _defaultFlags.keys) {
      final value = await _storage.read(key: key);
      if (value != null) {
        _flagsCache[key] = value.toLowerCase() == 'true';
      } else {
        _flagsCache[key] = _defaultFlags[key] ?? false;
      }
    }
  }

  /// Get a feature flag value
  bool isEnabled(String flagKey) {
    return _flagsCache[flagKey] ?? _defaultFlags[flagKey] ?? false;
  }

  /// Set a feature flag value (for testing/admin purposes)
  Future<void> setFlag(String flagKey, bool value) async {
    _flagsCache[flagKey] = value;
    await _storage.write(key: flagKey, value: value.toString());
  }

  /// Update flags from remote configuration
  Future<void> updateFromRemote(Map<String, bool> remoteFlags) async {
    for (final entry in remoteFlags.entries) {
      if (_defaultFlags.containsKey(entry.key)) {
        _flagsCache[entry.key] = entry.value;
        await _storage.write(key: entry.key, value: entry.value.toString());
      }
    }
  }

  /// Clear all feature flags
  Future<void> clearFlags() async {
    _flagsCache.clear();
    for (final key in _defaultFlags.keys) {
      await _storage.delete(key: key);
    }
    await _loadFlags();
  }

  // Convenience methods for specific features
  bool get isEnhancedMessagingEnabled => isEnabled(_enhancedMessagingKey);
  bool get isAttachmentSharingEnabled => isEnabled(_attachmentSharingKey);
  bool get isVoiceMessagesEnabled => isEnabled(_voiceMessagesKey);
  bool get isMessagingAnalyticsEnabled => isEnabled(_messagingAnalyticsKey);

  /// Enable enhanced messaging (for gradual rollout)
  Future<void> enableEnhancedMessaging() async {
    await setFlag(_enhancedMessagingKey, true);
  }

  /// Disable enhanced messaging (for rollback)
  Future<void> disableEnhancedMessaging() async {
    await setFlag(_enhancedMessagingKey, false);
  }

  /// Get all current flags for debugging
  Map<String, bool> getAllFlags() {
    return Map.from(_flagsCache);
  }
}
