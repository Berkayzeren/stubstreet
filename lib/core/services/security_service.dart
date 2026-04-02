import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Güvenlik servisi - DDoS koruması, bot tespiti ve güvenlik kontrolleri
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Rate limiting için memory cache
  final Map<String, List<DateTime>> _requestHistory = {};
  
  // Güvenlik ayarları
  static const int _maxRequestsPerMinute = 60;
  static const int _maxTicketsPerHour = 10;
  static const int _maxMessagesPerMinute = 30;
  
  // Device fingerprint cache
  String? _deviceFingerprint;
  
  /// Cihaz parmak izi oluştur
  Future<String> getDeviceFingerprint() async {
    if (_deviceFingerprint != null) return _deviceFingerprint!;
    
    try {
      String deviceId = '';
      String deviceModel = '';
      String osVersion = '';
      
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        deviceModel = androidInfo.model;
        osVersion = androidInfo.version.release;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
        deviceModel = iosInfo.model;
        osVersion = iosInfo.systemVersion;
      }
      
      // Package bilgisi
      final packageInfo = await PackageInfo.fromPlatform();
      
      // Fingerprint oluştur
      final fingerprintData = '$deviceId|$deviceModel|$osVersion|${packageInfo.packageName}|${packageInfo.version}';
      final bytes = utf8.encode(fingerprintData);
      final digest = sha256.convert(bytes);
      
      _deviceFingerprint = digest.toString();
      
      // Secure storage'a kaydet
      await _secureStorage.write(key: 'device_fingerprint', value: _deviceFingerprint);
      
      return _deviceFingerprint!;
    } catch (e) {
      debugPrint('Device fingerprint error: $e');
      return 'unknown';
    }
  }
  
  /// Request rate limiting kontrolü
  Future<bool> checkRateLimit(String action) async {
    final now = DateTime.now();
    final key = '${_auth.currentUser?.uid ?? 'anonymous'}_$action';
    
    // Request geçmişini al
    _requestHistory[key] ??= [];
    final history = _requestHistory[key]!;
    
    // Eski kayıtları temizle (1 dakikadan eski)
    history.removeWhere((time) => now.difference(time).inMinutes >= 1);
    
    // Limit kontrolü
    int maxRequests = _maxRequestsPerMinute;
    if (action == 'create_ticket') {
      maxRequests = _maxTicketsPerHour ~/ 60; // Saatlik limiti dakikaya çevir
    } else if (action == 'send_message') {
      maxRequests = _maxMessagesPerMinute;
    }
    
    if (history.length >= maxRequests) {
      // Rate limit aşıldı, güvenlik olayı logla
      await _logSecurityEvent(
        type: 'RATE_LIMIT_EXCEEDED',
        severity: 'warning',
        details: {
          'action': action,
          'requests': history.length,
          'limit': maxRequests,
        },
      );
      return false;
    }
    
    // Yeni request'i kaydet
    history.add(now);
    return true;
  }
  
  /// Güvenlik olayını logla
  Future<void> _logSecurityEvent({
    required String type,
    required String severity,
    required Map<String, dynamic> details,
  }) async {
    try {
      final deviceFingerprint = await getDeviceFingerprint();
      
      await _firestore.collection('securityLogs').add({
        'type': type,
        'severity': severity,
        'userId': _auth.currentUser?.uid,
        'deviceFingerprint': deviceFingerprint,
        'timestamp': FieldValue.serverTimestamp(),
        'details': details,
        'platform': defaultTargetPlatform.toString(),
        'appVersion': (await PackageInfo.fromPlatform()).version,
      });
    } catch (e) {
      debugPrint('Security logging error: $e');
    }
  }
  
  /// Şüpheli aktivite kontrolü
  Future<bool> checkSuspiciousActivity() async {
    try {
      if (_auth.currentUser == null) return false;
      
      // Son 1 saatteki güvenlik olaylarını kontrol et
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      final events = await _firestore
          .collection('securityLogs')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(oneHourAgo))
          .where('severity', whereIn: ['warning', 'critical'])
          .limit(10)
          .get();
      
      // 5'ten fazla uyarı varsa şüpheli aktivite
      if (events.docs.length >= 5) {
        await _logSecurityEvent(
          type: 'SUSPICIOUS_ACTIVITY',
          severity: 'critical',
          details: {
            'warningCount': events.docs.length,
            'timeWindow': '1 hour',
          },
        );
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Suspicious activity check error: $e');
      return false;
    }
  }
  
  /// API isteği güvenlik header'ları ekle
  Map<String, String> getSecureHeaders() {
    return {
      'X-Device-Fingerprint': _deviceFingerprint ?? 'unknown',
      'X-App-Version': 'biletsokagi-flutter-1.0.0',
      'X-Platform': defaultTargetPlatform.toString(),
      'X-Request-ID': _generateRequestId(),
    };
  }
  
  /// Request ID oluştur
  String _generateRequestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.toString().substring(8);
    return 'REQ-$timestamp-$random';
  }
  
  /// Token güvenlik kontrolü
  Future<bool> validateToken(String token) async {
    try {
      // Token formatı kontrolü
      if (token.isEmpty || token.length < 100) {
        return false;
      }
      
      // JWT decode (basit kontrol)
      final parts = token.split('.');
      if (parts.length != 3) {
        return false;
      }
      
      // Expiration kontrolü
      try {
        final payload = json.decode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        );
        
        final exp = payload['exp'] as int?;
        if (exp != null) {
          final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          if (expDate.isBefore(DateTime.now())) {
            return false;
          }
        }
      } catch (e) {
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('Token validation error: $e');
      return false;
    }
  }
  
  /// Bilet oluşturma spam kontrolü
  Future<bool> canCreateTicket(String title) async {
    if (!await checkRateLimit('create_ticket')) {
      return false;
    }
    
    try {
      // Aynı başlıkla son 5 dakika içinde bilet oluşturulmuş mu?
      final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
      final recentTickets = await _firestore
          .collection('tickets')
          .where('sellerId', isEqualTo: _auth.currentUser!.uid)
          .where('title', isEqualTo: title)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
          .limit(1)
          .get();
      
      if (recentTickets.docs.isNotEmpty) {
        await _logSecurityEvent(
          type: 'DUPLICATE_TICKET_ATTEMPT',
          severity: 'warning',
          details: {
            'title': title,
            'timeWindow': '5 minutes',
          },
        );
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('Ticket spam check error: $e');
      return true; // Hata durumunda izin ver
    }
  }
  
  /// Mesaj gönderme spam kontrolü
  Future<bool> canSendMessage(String conversationId) async {
    return await checkRateLimit('send_message');
  }
  
  /// Giriş denemesi kontrolü
  Future<bool> checkLoginAttempts(String email) async {
    try {
      // Son 15 dakikadaki başarısız giriş denemelerini kontrol et
      final fifteenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 15));
      final attempts = await _firestore
          .collection('loginAttempts')
          .where('email', isEqualTo: email)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(fifteenMinutesAgo))
          .where('success', isEqualTo: false)
          .get();
      
      if (attempts.docs.length >= 5) {
        await _logSecurityEvent(
          type: 'EXCESSIVE_LOGIN_ATTEMPTS',
          severity: 'critical',
          details: {
            'email': email,
            'attempts': attempts.docs.length,
            'timeWindow': '15 minutes',
          },
        );
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('Login attempts check error: $e');
      return true;
    }
  }
  
  /// Giriş denemesini kaydet
  Future<void> logLoginAttempt(String email, bool success) async {
    try {
      await _firestore.collection('loginAttempts').add({
        'email': email,
        'success': success,
        'deviceFingerprint': await getDeviceFingerprint(),
        'timestamp': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.toString(),
      });
      
      if (!success) {
        await _logSecurityEvent(
          type: 'FAILED_LOGIN',
          severity: 'info',
          details: {
            'email': email,
          },
        );
      }
    } catch (e) {
      debugPrint('Login attempt logging error: $e');
    }
  }
  
  /// IP adresi kontrolü (backend tarafından yapılır)
  Future<bool> isIPBlacklisted() async {
    // Bu kontrol backend tarafından yapılır
    // Flutter'da sadece sonucu kontrol ederiz
    return false;
  }
  
  /// Güvenlik durumu özeti
  Future<SecurityStatus> getSecurityStatus() async {
    final isSuspicious = await checkSuspiciousActivity();
    final deviceFingerprint = await getDeviceFingerprint();
    
    return SecurityStatus(
      isSecure: !isSuspicious,
      deviceFingerprint: deviceFingerprint,
      lastSecurityCheck: DateTime.now(),
      warnings: isSuspicious ? ['Suspicious activity detected'] : [],
    );
  }
  
  /// Bellek temizleme
  void clearRateLimitCache() {
    final now = DateTime.now();
    _requestHistory.removeWhere((key, history) {
      history.removeWhere((time) => now.difference(time).inMinutes >= 60);
      return history.isEmpty;
    });
  }
}

/// Güvenlik durumu modeli
class SecurityStatus {
  final bool isSecure;
  final String deviceFingerprint;
  final DateTime lastSecurityCheck;
  final List<String> warnings;
  
  SecurityStatus({
    required this.isSecure,
    required this.deviceFingerprint,
    required this.lastSecurityCheck,
    required this.warnings,
  });
}

