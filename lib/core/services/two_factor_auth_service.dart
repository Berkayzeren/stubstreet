// lib/core/services/two_factor_auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:math' as math;
import 'dart:developer' as developer;
import 'secure_storage_service.dart';
import 'two_factor_auth_types.dart';
import '../utils/base32_encoder.dart';

/// Service for Two-Factor Authentication (2FA) management
class TwoFactorAuthService {
  final FirebaseFirestore _firestore;
  final SecureStorageService _secureStorage;

  TwoFactorAuthService(this._firestore, [SecureStorageService? secureStorage])
      : _secureStorage = secureStorage ?? SecureStorageService();

  /// Get 2FA configuration for user
  Future<TwoFactorConfig?> getTwoFactorConfig(String userId) async {
    try {
      final doc = await _firestore
          .collection('twoFactorConfigs')
          .doc(userId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return TwoFactorConfig.fromFirestore(doc);
    } catch (e) {
      developer.log('Error getting 2FA config: $e', name: 'TwoFactorAuthService');
      return null;
    }
  }

  /// Check if 2FA is enabled for user
  Future<bool> isTwoFactorEnabled(String userId) async {
    final config = await getTwoFactorConfig(userId);
    return config?.status == TwoFactorStatus.enabled;
  }

  /// Setup SMS-based 2FA
  Future<String> setupSMS2FA({
    required String userId,
    required String phoneNumber,
  }) async {
    try {
      // Generate verification code
      final verificationCode = _generateVerificationCode();
      
      // Store pending verification
      await _storePendingVerification(
        userId: userId,
        method: TwoFactorMethod.sms,
        code: verificationCode,
        phoneNumber: phoneNumber,
      );

      // In production, send SMS via your SMS provider
      // For now, we'll log it (in production, remove this)
      developer.log(
        'SMS 2FA setup code for $phoneNumber: $verificationCode',
        name: 'TwoFactorAuthService',
      );

      // Simulate SMS sending (replace with actual SMS service)
      await _simulateSMSSending(phoneNumber, verificationCode);

      return 'SMS doğrulama kodu $phoneNumber numarasına gönderildi.';
    } catch (e) {
      developer.log('Error setting up SMS 2FA: $e', name: 'TwoFactorAuthService');
      throw Exception('SMS 2FA kurulumu başarısız: $e');
    }
  }

  /// Setup TOTP-based 2FA
  Future<Map<String, dynamic>> setupTOTP2FA({
    required String userId,
    required String userEmail,
  }) async {
    try {
      // Generate TOTP secret
      final secret = _generateTOTPSecret();
      
      // Create TOTP URI for QR code
      final appName = 'Bilet Sokağı';
      final totpUri = 'otpauth://totp/$appName:$userEmail?secret=$secret&issuer=$appName';
      
      // Store pending TOTP setup
      await _storePendingVerification(
        userId: userId,
        method: TwoFactorMethod.totp,
        totpSecret: secret,
      );

      return {
        'secret': secret,
        'qrCodeUri': totpUri,
        'manualEntryKey': _formatSecretForManualEntry(secret),
        'message': 'TOTP uygulamanızda bu kodu okutun veya manuel olarak girin.',
      };
    } catch (e) {
      developer.log('Error setting up TOTP 2FA: $e', name: 'TwoFactorAuthService');
      throw Exception('TOTP 2FA kurulumu başarısız: $e');
    }
  }

  /// Verify 2FA setup
  Future<TwoFactorConfig> verify2FASetup({
    required String userId,
    required String verificationCode,
    required TwoFactorMethod method,
  }) async {
    try {
      // Get pending verification
      final pendingDoc = await _firestore
          .collection('pending2FAVerifications')
          .doc(userId)
          .get();

      if (!pendingDoc.exists) {
        throw Exception('Bekleyen doğrulama bulunamadı.');
      }

      final pendingData = pendingDoc.data()!;
      final expectedMethod = TwoFactorMethod.values.firstWhere(
        (m) => m.name == pendingData['method'],
      );

      if (expectedMethod != method) {
        throw Exception('Doğrulama yöntemi uyuşmuyor.');
      }

      bool isValid = false;

      switch (method) {
        case TwoFactorMethod.sms:
          final expectedCode = pendingData['code'] as String;
          isValid = verificationCode == expectedCode;
          break;

        case TwoFactorMethod.totp:
          final secret = pendingData['totpSecret'] as String;
          isValid = _verifyTOTPCode(secret, verificationCode);
          break;

        case TwoFactorMethod.email:
          // Email verification implementation
          final expectedCode = pendingData['code'] as String;
          isValid = verificationCode == expectedCode;
          break;
      }

      if (!isValid) {
        throw Exception('Geçersiz doğrulama kodu.');
      }

      // Generate backup codes
      final backupCodes = _generateBackupCodes();

      // Create 2FA configuration
      final config = TwoFactorConfig(
        userId: userId,
        status: TwoFactorStatus.enabled,
        enabledMethods: [method],
        phoneNumber: pendingData['phoneNumber'] as String?,
        totpSecret: pendingData['totpSecret'] as String?,
        backupCodes: backupCodes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save configuration
      await _firestore
          .collection('twoFactorConfigs')
          .doc(userId)
          .set(config.toFirestore());

      // Clean up pending verification
      await _firestore
          .collection('pending2FAVerifications')
          .doc(userId)
          .delete();

      // Store backup codes securely
      await _secureStorage.store2FABackupCodes(userId, backupCodes);

      developer.log('2FA setup completed for user: $userId', name: 'TwoFactorAuthService');
      return config;
    } catch (e) {
      developer.log('Error verifying 2FA setup: $e', name: 'TwoFactorAuthService');
      rethrow;
    }
  }

  /// Verify 2FA code during login
  Future<bool> verify2FACode({
    required String userId,
    required String code,
    TwoFactorMethod? preferredMethod,
  }) async {
    try {
      final config = await getTwoFactorConfig(userId);
      if (config == null || config.status != TwoFactorStatus.enabled) {
        return false;
      }

      // Check backup codes first
      if (await _verifyBackupCode(userId, code)) {
        await _updateLastUsed(userId);
        return true;
      }

      // Verify with enabled methods
      for (final method in config.enabledMethods) {
        bool isValid = false;

        switch (method) {
          case TwoFactorMethod.sms:
            // For SMS, we need to check if there's a recent verification code
            isValid = await _verifySMSCode(userId, code);
            break;

          case TwoFactorMethod.totp:
            if (config.totpSecret != null) {
              isValid = _verifyTOTPCode(config.totpSecret!, code);
            }
            break;

          case TwoFactorMethod.email:
            // Email verification
            isValid = await _verifyEmailCode(userId, code);
            break;
        }

        if (isValid) {
          await _updateLastUsed(userId);
          return true;
        }
      }

      return false;
    } catch (e) {
      developer.log('Error verifying 2FA code: $e', name: 'TwoFactorAuthService');
      return false;
    }
  }

  /// Send 2FA code for login
  Future<String> send2FACode({
    required String userId,
    required TwoFactorMethod method,
  }) async {
    try {
      final config = await getTwoFactorConfig(userId);
      if (config == null || config.status != TwoFactorStatus.enabled) {
        throw Exception('2FA etkin değil.');
      }

      if (!config.enabledMethods.contains(method)) {
        throw Exception('Bu 2FA yöntemi etkin değil.');
      }

      switch (method) {
        case TwoFactorMethod.sms:
          if (config.phoneNumber == null) {
            throw Exception('Telefon numarası bulunamadı.');
          }
          return await _sendSMSCode(userId, config.phoneNumber!);

        case TwoFactorMethod.email:
          return await _sendEmailCode(userId);

        case TwoFactorMethod.totp:
          return 'TOTP uygulamanızdan kodu girin.';
      }
    } catch (e) {
      developer.log('Error sending 2FA code: $e', name: 'TwoFactorAuthService');
      rethrow;
    }
  }

  /// Disable 2FA
  Future<void> disable2FA(String userId) async {
    try {
      await _firestore
          .collection('twoFactorConfigs')
          .doc(userId)
          .delete();

      await _secureStorage.clear2FABackupCodes(userId);

      developer.log('2FA disabled for user: $userId', name: 'TwoFactorAuthService');
    } catch (e) {
      developer.log('Error disabling 2FA: $e', name: 'TwoFactorAuthService');
      throw Exception('2FA devre dışı bırakma başarısız: $e');
    }
  }

  /// Get backup codes
  Future<List<String>> getBackupCodes(String userId) async {
    try {
      return await _secureStorage.get2FABackupCodes(userId);
    } catch (e) {
      developer.log('Error getting backup codes: $e', name: 'TwoFactorAuthService');
      return [];
    }
  }

  /// Regenerate backup codes
  Future<List<String>> regenerateBackupCodes(String userId) async {
    try {
      final newCodes = _generateBackupCodes();
      
      // Update in Firestore
      await _firestore
          .collection('twoFactorConfigs')
          .doc(userId)
          .update({
        'backupCodes': newCodes,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update in secure storage
      await _secureStorage.store2FABackupCodes(userId, newCodes);

      return newCodes;
    } catch (e) {
      developer.log('Error regenerating backup codes: $e', name: 'TwoFactorAuthService');
      throw Exception('Yedek kodlar yenilenemedi: $e');
    }
  }

  // Private helper methods

  String _generateVerificationCode() {
    final random = math.Random.secure();
    return (100000 + random.nextInt(900000)).toString(); // 6-digit code
  }

  String _generateTOTPSecret() {
    final random = math.Random.secure();
    final bytes = List<int>.generate(20, (i) => random.nextInt(256));
    return Base32Encoder.encode(bytes);
  }

  String _formatSecretForManualEntry(String secret) {
    // Format secret for manual entry (groups of 4 characters)
    final formatted = StringBuffer();
    for (int i = 0; i < secret.length; i += 4) {
      if (i > 0) formatted.write(' ');
      formatted.write(secret.substring(i, math.min(i + 4, secret.length)));
    }
    return formatted.toString();
  }

  List<String> _generateBackupCodes() {
    final random = math.Random.secure();
    final codes = <String>[];
    
    for (int i = 0; i < 10; i++) {
      final code = (10000000 + random.nextInt(90000000)).toString(); // 8-digit codes
      codes.add(code);
    }
    
    return codes;
  }

  bool _verifyTOTPCode(String secret, String code) {
    try {
      // Simple TOTP verification (in production, use a proper TOTP library)
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final timeStep = now ~/ 30; // 30-second time step
      
      // Check current time step and ±1 for clock skew tolerance
      for (int i = -1; i <= 1; i++) {
        final testTimeStep = timeStep + i;
        final expectedCode = _generateTOTPCode(secret, testTimeStep);
        if (expectedCode == code) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      developer.log('Error verifying TOTP code: $e', name: 'TwoFactorAuthService');
      return false;
    }
  }

  String _generateTOTPCode(String secret, int timeStep) {
    // Simplified TOTP generation (use proper library in production)
    final key = Base32Encoder.decode(secret);
    final timeBytes = _intToBytes(timeStep);
    
    final hmac = Hmac(sha1, key);
    final digest = hmac.convert(timeBytes);
    
    final offset = digest.bytes[19] & 0xf;
    final code = ((digest.bytes[offset] & 0x7f) << 24) |
                 ((digest.bytes[offset + 1] & 0xff) << 16) |
                 ((digest.bytes[offset + 2] & 0xff) << 8) |
                 (digest.bytes[offset + 3] & 0xff);
    
    return (code % 1000000).toString().padLeft(6, '0');
  }

  List<int> _intToBytes(int value) {
    final bytes = List<int>.filled(8, 0);
    for (int i = 7; i >= 0; i--) {
      bytes[i] = value & 0xff;
      value >>= 8;
    }
    return bytes;
  }

  Future<void> _storePendingVerification({
    required String userId,
    required TwoFactorMethod method,
    String? code,
    String? phoneNumber,
    String? totpSecret,
  }) async {
    await _firestore
        .collection('pending2FAVerifications')
        .doc(userId)
        .set({
      'userId': userId,
      'method': method.name,
      'code': code,
      'phoneNumber': phoneNumber,
      'totpSecret': totpSecret,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': FieldValue.serverTimestamp(), // Add 10 minutes in production
    });
  }

  Future<void> _simulateSMSSending(String phoneNumber, String code) async {
    // Simulate SMS sending delay
    await Future.delayed(const Duration(seconds: 1));
    
    // In production, integrate with SMS service like Twilio, AWS SNS, etc.
    developer.log(
      'SMS sent to $phoneNumber: Your verification code is $code',
      name: 'TwoFactorAuthService',
    );
  }

  Future<String> _sendSMSCode(String userId, String phoneNumber) async {
    final code = _generateVerificationCode();
    
    // Store verification code temporarily
    await _firestore
        .collection('smsVerificationCodes')
        .doc(userId)
        .set({
      'code': code,
      'phoneNumber': phoneNumber,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': FieldValue.serverTimestamp(), // Add 5 minutes in production
    });

    await _simulateSMSSending(phoneNumber, code);
    return 'SMS kodu $phoneNumber numarasına gönderildi.';
  }

  Future<String> _sendEmailCode(String userId) async {
    // Email code implementation
    final code = _generateVerificationCode();
    
    // Store email verification code
    await _firestore
        .collection('emailVerificationCodes')
        .doc(userId)
        .set({
      'code': code,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': FieldValue.serverTimestamp(), // Add 5 minutes in production
    });

    // In production, send email via your email service
    developer.log('Email 2FA code for user $userId: $code', name: 'TwoFactorAuthService');
    return 'E-posta doğrulama kodu gönderildi.';
  }

  Future<bool> _verifySMSCode(String userId, String code) async {
    try {
      final doc = await _firestore
          .collection('smsVerificationCodes')
          .doc(userId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      final expectedCode = data['code'] as String;
      
      if (expectedCode == code) {
        // Clean up used code
        await _firestore
            .collection('smsVerificationCodes')
            .doc(userId)
            .delete();
        return true;
      }
      
      return false;
    } catch (e) {
      developer.log('Error verifying SMS code: $e', name: 'TwoFactorAuthService');
      return false;
    }
  }

  Future<bool> _verifyEmailCode(String userId, String code) async {
    try {
      final doc = await _firestore
          .collection('emailVerificationCodes')
          .doc(userId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      final expectedCode = data['code'] as String;
      
      if (expectedCode == code) {
        // Clean up used code
        await _firestore
            .collection('emailVerificationCodes')
            .doc(userId)
            .delete();
        return true;
      }
      
      return false;
    } catch (e) {
      developer.log('Error verifying email code: $e', name: 'TwoFactorAuthService');
      return false;
    }
  }

  Future<bool> _verifyBackupCode(String userId, String code) async {
    try {
      final backupCodes = await _secureStorage.get2FABackupCodes(userId);
      
      if (backupCodes.contains(code)) {
        // Remove used backup code
        backupCodes.remove(code);
        await _secureStorage.store2FABackupCodes(userId, backupCodes);
        
        // Update Firestore
        await _firestore
            .collection('twoFactorConfigs')
            .doc(userId)
            .update({
          'backupCodes': backupCodes,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        return true;
      }
      
      return false;
    } catch (e) {
      developer.log('Error verifying backup code: $e', name: 'TwoFactorAuthService');
      return false;
    }
  }

  Future<void> _updateLastUsed(String userId) async {
    try {
      await _firestore
          .collection('twoFactorConfigs')
          .doc(userId)
          .update({
        'lastUsed': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      developer.log('Error updating last used: $e', name: 'TwoFactorAuthService');
    }
  }
}
