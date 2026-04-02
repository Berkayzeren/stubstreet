// lib/core/services/secure_storage_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:developer' as developer;

/// Service for securely storing and retrieving sensitive data
class SecureStorageService {
  static const SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  const SecureStorageService._internal();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      // Use AES encryption
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      // Use keychain for iOS
      accessibility: KeychainAccessibility.first_unlock_this_device,
      accountName: 'stubstreet_app',
    ),
    lOptions: LinuxOptions(),
    wOptions: WindowsOptions(),
  );

  // Keys for storing different types of data
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _autoLoginEnabledKey = 'auto_login_enabled';
  static const String _lastLoginTimeKey = 'last_login_time';
  static const String _sessionIdKey = 'session_id';
  static const String _deviceIdKey = 'device_id';
  static const String _logoutReasonKey = 'logout_reason';
  static const String _twoFactorBackupCodesKey = '2fa_backup_codes';

  /// Store access token securely
  Future<void> storeAccessToken(String token) async {
    try {
      await _storage.write(key: _accessTokenKey, value: token);
      developer.log(
        'Access token stored securely',
        name: 'SecureStorageService',
      );
    } catch (e) {
      developer.log(
        'Error storing access token: $e',
        name: 'SecureStorageService',
      );
      rethrow;
    }
  }

  /// Retrieve access token
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      developer.log(
        'Error retrieving access token: $e',
        name: 'SecureStorageService',
      );
      return null;
    }
  }

  /// Store refresh token securely
  Future<void> storeRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
      developer.log(
        'Refresh token stored securely',
        name: 'SecureStorageService',
      );
    } catch (e) {
      developer.log(
        'Error storing refresh token: $e',
        name: 'SecureStorageService',
      );
      rethrow;
    }
  }

  /// Retrieve refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      developer.log(
        'Error retrieving refresh token: $e',
        name: 'SecureStorageService',
      );
      return null;
    }
  }

  /// Store token expiry time
  Future<void> storeTokenExpiry(DateTime expiry) async {
    try {
      await _storage.write(
        key: _tokenExpiryKey,
        value: expiry.toIso8601String(),
      );
      developer.log(
        'Token expiry stored securely',
        name: 'SecureStorageService',
      );
    } catch (e) {
      developer.log(
        'Error storing token expiry: $e',
        name: 'SecureStorageService',
      );
      rethrow;
    }
  }

  /// Retrieve token expiry time
  Future<DateTime?> getTokenExpiry() async {
    try {
      final expiryString = await _storage.read(key: _tokenExpiryKey);
      if (expiryString != null) {
        return DateTime.parse(expiryString);
      }
      return null;
    } catch (e) {
      developer.log(
        'Error retrieving token expiry: $e',
        name: 'SecureStorageService',
      );
      return null;
    }
  }

  /// Check if token is expired
  Future<bool> isTokenExpired() async {
    try {
      final expiry = await getTokenExpiry();
      if (expiry == null) return true;

      // Add 30 seconds buffer to handle clock skew
      final now = DateTime.now().add(const Duration(seconds: 30));
      return expiry.isBefore(now);
    } catch (e) {
      developer.log(
        'Error checking token expiry: $e',
        name: 'SecureStorageService',
      );
      return true; // Assume expired on error
    }
  }

  /// Store user credentials
  Future<void> storeUserCredentials({
    required String userId,
    required String email,
    String? accessToken,
    String? refreshToken,
    DateTime? tokenExpiry,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _userIdKey, value: userId),
        _storage.write(key: _userEmailKey, value: email),
        if (accessToken != null) storeAccessToken(accessToken),
        if (refreshToken != null) storeRefreshToken(refreshToken),
        if (tokenExpiry != null) storeTokenExpiry(tokenExpiry),
      ]);
      developer.log(
        'User credentials stored securely',
        name: 'SecureStorageService',
      );
    } catch (e) {
      developer.log(
        'Error storing user credentials: $e',
        name: 'SecureStorageService',
      );
      rethrow;
    }
  }

  /// Retrieve user ID
  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _userIdKey);
    } catch (e) {
      developer.log(
        'Error retrieving user ID: $e',
        name: 'SecureStorageService',
      );
      return null;
    }
  }

  /// Retrieve user email
  Future<String?> getUserEmail() async {
    try {
      return await _storage.read(key: _userEmailKey);
    } catch (e) {
      developer.log(
        'Error retrieving user email: $e',
        name: 'SecureStorageService',
      );
      return null;
    }
  }

  /// Store session information
  Future<void> storeSessionInfo({
    required String sessionId,
    required String deviceId,
    required DateTime lastLoginTime,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _sessionIdKey, value: sessionId),
        _storage.write(key: _deviceIdKey, value: deviceId),
        _storage.write(
          key: _lastLoginTimeKey,
          value: lastLoginTime.toIso8601String(),
        ),
      ]);
      developer.log(
        'Session info stored securely',
        name: 'SecureStorageService',
      );
    } catch (e) {
      developer.log(
        'Error storing session info: $e',
        name: 'SecureStorageService',
      );
      rethrow;
    }
  }

  /// Retrieve session ID
  Future<String?> getSessionId() async {
    try {
      return await _storage.read(key: _sessionIdKey);
    } catch (e) {
      developer.log(
        'Error retrieving session ID: $e',
        name: 'SecureStorageService',
      );
      return null;
    }
  }

  /// Retrieve device ID
  Future<String?> getDeviceId() async {
    try {
      return await _storage.read(key: _deviceIdKey);
    } catch (e) {
      developer.log(
        'Error retrieving device ID: $e',
        name: 'SecureStorageService',
      );
      return null;
    }
  }

  /// Retrieve last login time
  Future<DateTime?> getLastLoginTime() async {
    try {
      final timeString = await _storage.read(key: _lastLoginTimeKey);
      if (timeString != null) {
        return DateTime.parse(timeString);
      }
      return null;
    } catch (e) {
      developer.log(
        'Error retrieving last login time: $e',
        name: 'SecureStorageService',
      );
      return null;
    }
  }

  /// Enable/disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(
        key: _biometricEnabledKey,
        value: enabled.toString(),
      );
      developer.log(
        'Biometric preference updated: $enabled',
        name: 'SecureStorageService',
      );
    } catch (e) {
      developer.log(
        'Error updating biometric preference: $e',
        name: 'SecureStorageService',
      );
      rethrow;
    }
  }

  /// Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _storage.read(key: _biometricEnabledKey);
      return enabled == 'true';
    } catch (e) {
      developer.log(
        'Error checking biometric preference: $e',
        name: 'SecureStorageService',
      );
      return false;
    }
  }

  /// Enable/disable auto-login
  Future<void> setAutoLoginEnabled(bool enabled) async {
    try {
      await _storage.write(
        key: _autoLoginEnabledKey,
        value: enabled.toString(),
      );
      developer.log(
        'Auto-login preference updated: $enabled',
        name: 'SecureStorageService',
      );
    } catch (e) {
      developer.log(
        'Error updating auto-login preference: $e',
        name: 'SecureStorageService',
      );
      rethrow;
    }
  }

  /// Check if auto-login is enabled
  Future<bool> isAutoLoginEnabled() async {
    try {
      final enabled = await _storage.read(key: _autoLoginEnabledKey);
      return enabled == 'true';
    } catch (e) {
      developer.log(
        'Error checking auto-login preference: $e',
        name: 'SecureStorageService',
      );
      return false;
    }
  }

  /// Store complex data as JSON
  Future<void> storeJson(String key, Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      await _storage.write(key: key, value: jsonString);
      developer.log(
        'JSON data stored securely for key: $key',
        name: 'SecureStorageService',
      );
    } catch (e) {
      developer.log(
        'Error storing JSON data for key $key: $e',
        name: 'SecureStorageService',
      );
      rethrow;
    }
  }

  /// Retrieve complex data from JSON
  Future<Map<String, dynamic>?> getJson(String key) async {
    try {
      final jsonString = await _storage.read(key: key);
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      developer.log(
        'Error retrieving JSON data for key $key: $e',
        name: 'SecureStorageService',
      );
      return null;
    }
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      developer.log(
        'All secure storage data cleared',
        name: 'SecureStorageService',
      );
    } catch (e) {
      developer.log(
        'Error clearing secure storage: $e',
        name: 'SecureStorageService',
      );
      rethrow;
    }
  }

  /// Store logout reason
  Future<void> storeLogoutReason(String reason) async {
    try {
      await _storage.write(key: _logoutReasonKey, value: reason);
      developer.log(
        'Logout reason stored: $reason',
        name: 'SecureStorageService',
      );
    } catch (e) {
      developer.log(
        'Error storing logout reason: $e',
        name: 'SecureStorageService',
      );
      // Don't rethrow - this is not critical
    }
  }

  /// Get logout reason
  Future<String?> getLogoutReason() async {
    try {
      return await _storage.read(key: _logoutReasonKey);
    } catch (e) {
      developer.log(
        'Error retrieving logout reason: $e',
        name: 'SecureStorageService',
      );
      return null;
    }
  }

  /// Clear logout reason
  Future<void> clearLogoutReason() async {
    try {
      await _storage.delete(key: _logoutReasonKey);
    } catch (e) {
      developer.log(
        'Error clearing logout reason: $e',
        name: 'SecureStorageService',
      );
      // Don't rethrow - this is not critical
    }
  }

  /// Store 2FA backup codes
  Future<void> store2FABackupCodes(String userId, List<String> codes) async {
    try {
      final key = '${_twoFactorBackupCodesKey}_$userId';
      final codesJson = jsonEncode(codes);
      await _storage.write(key: key, value: codesJson);
      developer.log(
        '2FA backup codes stored for user: $userId',
        name: 'SecureStorageService',
      );
    } catch (e) {
      developer.log(
        'Error storing 2FA backup codes: $e',
        name: 'SecureStorageService',
      );
      rethrow;
    }
  }

  /// Get 2FA backup codes
  Future<List<String>> get2FABackupCodes(String userId) async {
    try {
      final key = '${_twoFactorBackupCodesKey}_$userId';
      final codesJson = await _storage.read(key: key);
      
      if (codesJson == null) {
        return [];
      }
      
      final codesList = jsonDecode(codesJson) as List<dynamic>;
      return List<String>.from(codesList);
    } catch (e) {
      developer.log(
        'Error retrieving 2FA backup codes: $e',
        name: 'SecureStorageService',
      );
      return [];
    }
  }

  /// Clear 2FA backup codes
  Future<void> clear2FABackupCodes(String userId) async {
    try {
      final key = '${_twoFactorBackupCodesKey}_$userId';
      await _storage.delete(key: key);
      developer.log(
        '2FA backup codes cleared for user: $userId',
        name: 'SecureStorageService',
      );
    } catch (e) {
      developer.log(
        'Error clearing 2FA backup codes: $e',
        name: 'SecureStorageService',
      );
      // Don't rethrow - this is not critical
    }
  }

  /// Clear authentication data only
  Future<void> clearAuthData() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _tokenExpiryKey),
        _storage.delete(key: _userIdKey),
        _storage.delete(key: _userEmailKey),
        _storage.delete(key: _sessionIdKey),
        _storage.delete(key: _lastLoginTimeKey),
        _storage.delete(key: _logoutReasonKey),
      ]);
      developer.log(
        'Authentication data cleared',
        name: 'SecureStorageService',
      );
    } catch (e) {
      developer.log(
        'Error clearing authentication data: $e',
        name: 'SecureStorageService',
      );
      rethrow;
    }
  }

  /// Check if secure storage is available
  Future<bool> isStorageAvailable() async {
    try {
      await _storage.containsKey(key: 'test_key');
      return true;
    } catch (e) {
      developer.log(
        'Secure storage not available: $e',
        name: 'SecureStorageService',
      );
      return false;
    }
  }

  /// Get all stored keys (for debugging)
  Future<Map<String, String>> getAllStoredData() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      developer.log(
        'Error reading all stored data: $e',
        name: 'SecureStorageService',
      );
      return {};
    }
  }
}
