// lib/core/services/auth_state_manager.dart

import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'secure_storage_service.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

/// Authentication state manager for handling token expiration,
/// session management, automatic token refresh, and inactivity timeout
class AuthStateManager {
  final AuthRepository _authRepository;
  final SecureStorageService _secureStorage;
  Timer? _tokenRefreshTimer;
  Timer? _sessionCheckTimer;
  Timer? _inactivityTimer;
  DateTime _lastActivityTime = DateTime.now();

  static const Duration _tokenCheckInterval = Duration(minutes: 5);
  static const Duration _sessionCheckInterval = Duration(minutes: 1);
  static const Duration _tokenRefreshBuffer = Duration(
    minutes: 5,
  ); // Refresh 5 minutes before expiry
  static const Duration _inactivityTimeout = Duration(minutes: 30); // 30 dakika inaktivite timeout
  static const Duration _inactivityCheckInterval = Duration(minutes: 1); // Her dakika kontrol et

  AuthStateManager(this._authRepository, [SecureStorageService? secureStorage])
    : _secureStorage = secureStorage ?? SecureStorageService();

  /// Initialize the auth state manager
  Future<void> initialize() async {
    developer.log('Initializing AuthStateManager', name: 'AuthStateManager');

    // Start periodic token validation
    _startTokenValidationTimer();

    // Start session monitoring
    _startSessionMonitoring();

    // Start inactivity monitoring
    _startInactivityMonitoring();

    // Check initial state
    await _validateCurrentSession();
  }

  /// Start periodic token validation
  void _startTokenValidationTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = Timer.periodic(_tokenCheckInterval, (timer) async {
      await _checkAndRefreshToken();
    });

    developer.log('Token validation timer started', name: 'AuthStateManager');
  }

  /// Start session monitoring
  void _startSessionMonitoring() {
    _sessionCheckTimer?.cancel();
    _sessionCheckTimer = Timer.periodic(_sessionCheckInterval, (timer) async {
      await _validateCurrentSession();
    });

    developer.log('Session monitoring started', name: 'AuthStateManager');
  }

  /// Start inactivity monitoring
  void _startInactivityMonitoring() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer.periodic(_inactivityCheckInterval, (timer) async {
      await _checkInactivityTimeout();
    });

    developer.log('Inactivity monitoring started', name: 'AuthStateManager');
  }

  /// Check if user has been inactive for too long
  Future<void> _checkInactivityTimeout() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final timeSinceLastActivity = now.difference(_lastActivityTime);

      if (timeSinceLastActivity >= _inactivityTimeout) {
        developer.log(
          'User inactive for ${timeSinceLastActivity.inMinutes} minutes, signing out',
          name: 'AuthStateManager',
        );
        
        // Store reason for logout
        await _secureStorage.storeLogoutReason('inactivity_timeout');
        
        // Sign out user
        await _authRepository.signOut();
      }
    } catch (e) {
      developer.log(
        'Error during inactivity check: $e',
        name: 'AuthStateManager',
      );
    }
  }

  /// Record user activity to reset inactivity timer
  void recordActivity() {
    _lastActivityTime = DateTime.now();
    developer.log(
      'User activity recorded at ${_lastActivityTime.toIso8601String()}',
      name: 'AuthStateManager',
    );
  }

  /// Check and refresh token if needed
  Future<void> _checkAndRefreshToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        developer.log(
          'No authenticated user found during token check',
          name: 'AuthStateManager',
        );
        return;
      }

      // Check if token expires soon
      final tokenExpiry = await _secureStorage.getTokenExpiry();
      if (tokenExpiry != null) {
        final now = DateTime.now();
        final timeUntilExpiry = tokenExpiry.difference(now);

        if (timeUntilExpiry <= _tokenRefreshBuffer) {
          developer.log(
            'Token expires in ${timeUntilExpiry.inMinutes} minutes, refreshing...',
            name: 'AuthStateManager',
          );
          await _authRepository.refreshToken();
        }
      } else {
        // No expiry time stored, refresh token
        developer.log(
          'No token expiry found, refreshing token',
          name: 'AuthStateManager',
        );
        await _authRepository.refreshToken();
      }
    } catch (e) {
      developer.log(
        'Error during token refresh check: $e',
        name: 'AuthStateManager',
      );
      // Don't throw - this is a background operation
    }
  }

  /// Validate current session
  Future<void> _validateCurrentSession() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Check if user is still valid
      await user.reload();

      // Check if token is valid
      final isValid = await _authRepository.isTokenValid();
      if (!isValid) {
        developer.log(
          'Invalid token detected, signing out user',
          name: 'AuthStateManager',
        );
        await _authRepository.signOut();
      }
    } catch (e) {
      developer.log(
        'Error during session validation: $e',
        name: 'AuthStateManager',
      );
      // If there's an error validating the session, sign out for security
      try {
        await _authRepository.signOut();
      } catch (signOutError) {
        developer.log(
          'Error during forced sign out: $signOutError',
          name: 'AuthStateManager',
        );
      }
    }
  }

  /// Handle user login
  Future<void> onUserLogin(User user) async {
    try {
      developer.log('User logged in: ${user.uid}', name: 'AuthStateManager');

      // Reset activity timer
      _lastActivityTime = DateTime.now();

      // Store session information
      await _secureStorage.storeSessionInfo(
        sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
        deviceId: 'device_${user.uid}', // In production, use actual device ID
        lastLoginTime: DateTime.now(),
      );

      // Start monitoring for this session
      _startTokenValidationTimer();
      _startSessionMonitoring();
      _startInactivityMonitoring();
    } catch (e) {
      developer.log('Error handling user login: $e', name: 'AuthStateManager');
      rethrow;
    }
  }

  /// Handle user logout
  Future<void> onUserLogout() async {
    try {
      developer.log('User logged out', name: 'AuthStateManager');

      // Stop timers
      _tokenRefreshTimer?.cancel();
      _sessionCheckTimer?.cancel();
      _inactivityTimer?.cancel();

      // Clear secure storage
      await _secureStorage.clearAuthData();
    } catch (e) {
      developer.log('Error handling user logout: $e', name: 'AuthStateManager');
      // Don't rethrow - logout should complete even if cleanup fails
    }
  }

  /// Force token refresh
  Future<void> forceTokenRefresh() async {
    try {
      await _authRepository.refreshToken();
      developer.log('Token refreshed successfully', name: 'AuthStateManager');
    } catch (e) {
      developer.log(
        'Error forcing token refresh: $e',
        name: 'AuthStateManager',
      );
      rethrow;
    }
  }

  /// Check if current session is valid
  Future<bool> isSessionValid() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Check if token is expired
      final isExpired = await _secureStorage.isTokenExpired();
      if (isExpired) {
        // Try to refresh
        try {
          await _authRepository.refreshToken();
          return true;
        } catch (e) {
          developer.log(
            'Failed to refresh expired token: $e',
            name: 'AuthStateManager',
          );
          return false;
        }
      }

      return true;
    } catch (e) {
      developer.log(
        'Error checking session validity: $e',
        name: 'AuthStateManager',
      );
      return false;
    }
  }

  /// Get session information
  Future<SessionInfo?> getSessionInfo() async {
    try {
      final userId = await _secureStorage.getUserId();
      final email = await _secureStorage.getUserEmail();
      final sessionId = await _secureStorage.getSessionId();
      final deviceId = await _secureStorage.getDeviceId();
      final lastLoginTime = await _secureStorage.getLastLoginTime();
      final tokenExpiry = await _secureStorage.getTokenExpiry();

      if (userId != null && email != null) {
        return SessionInfo(
          userId: userId,
          email: email,
          sessionId: sessionId,
          deviceId: deviceId,
          lastLoginTime: lastLoginTime,
          tokenExpiry: tokenExpiry,
        );
      }

      return null;
    } catch (e) {
      developer.log('Error getting session info: $e', name: 'AuthStateManager');
      return null;
    }
  }

  /// Enable/disable auto-login
  Future<void> setAutoLoginEnabled(bool enabled) async {
    try {
      await _secureStorage.setAutoLoginEnabled(enabled);
      developer.log(
        'Auto-login ${enabled ? 'enabled' : 'disabled'}',
        name: 'AuthStateManager',
      );
    } catch (e) {
      developer.log(
        'Error setting auto-login preference: $e',
        name: 'AuthStateManager',
      );
      rethrow;
    }
  }

  /// Check if auto-login is enabled and valid
  Future<bool> canAutoLogin() async {
    try {
      final isEnabled = await _secureStorage.isAutoLoginEnabled();
      if (!isEnabled) return false;

      return await isSessionValid();
    } catch (e) {
      developer.log(
        'Error checking auto-login availability: $e',
        name: 'AuthStateManager',
      );
      return false;
    }
  }

  /// Get time remaining until inactivity timeout
  Duration get timeUntilInactivityTimeout {
    final now = DateTime.now();
    final timeSinceActivity = now.difference(_lastActivityTime);
    final remaining = _inactivityTimeout - timeSinceActivity;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Check if user is close to inactivity timeout (5 minutes warning)
  bool get isCloseToInactivityTimeout {
    return timeUntilInactivityTimeout <= const Duration(minutes: 5);
  }

  /// Dispose resources
  void dispose() {
    _tokenRefreshTimer?.cancel();
    _sessionCheckTimer?.cancel();
    _inactivityTimer?.cancel();
    developer.log('AuthStateManager disposed', name: 'AuthStateManager');
  }
}

/// Session information model
class SessionInfo {
  final String userId;
  final String email;
  final String? sessionId;
  final String? deviceId;
  final DateTime? lastLoginTime;
  final DateTime? tokenExpiry;

  const SessionInfo({
    required this.userId,
    required this.email,
    this.sessionId,
    this.deviceId,
    this.lastLoginTime,
    this.tokenExpiry,
  });

  bool get isTokenExpired {
    if (tokenExpiry == null) return true;
    return DateTime.now().isAfter(tokenExpiry!);
  }

  Duration? get timeUntilExpiry {
    if (tokenExpiry == null) return null;
    final now = DateTime.now();
    if (now.isAfter(tokenExpiry!)) return Duration.zero;
    return tokenExpiry!.difference(now);
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'sessionId': sessionId,
      'deviceId': deviceId,
      'lastLoginTime': lastLoginTime?.toIso8601String(),
      'tokenExpiry': tokenExpiry?.toIso8601String(),
    };
  }

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      userId: json['userId'] as String,
      email: json['email'] as String,
      sessionId: json['sessionId'] as String?,
      deviceId: json['deviceId'] as String?,
      lastLoginTime: json['lastLoginTime'] != null
          ? DateTime.parse(json['lastLoginTime'] as String)
          : null,
      tokenExpiry: json['tokenExpiry'] != null
          ? DateTime.parse(json['tokenExpiry'] as String)
          : null,
    );
  }
}
