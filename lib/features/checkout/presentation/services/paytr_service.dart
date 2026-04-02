// lib/features/checkout/presentation/services/paytr_service.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class PaytrService {
  final Dio _dio;
  final String _functionsBaseUrl;

  PaytrService({Dio? dio, String? functionsBaseUrl})
      : _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        )),
        _functionsBaseUrl = functionsBaseUrl ?? (dotenv.env['FUNCTIONS_BASE_URL'] ?? 'https://us-central1-device-streaming-70d2d53c.cloudfunctions.net/api');

  /// PayTR init token endpoint'ini çağırarak WebView'e yollayacağımız parametreleri döndürür
  /// 
  /// Parametreler: payload - email, amount, currency, orderId, customerIp, basket, okUrl, failUrl, installmentCount, testMode, paymentType, non3d
  /// 
  /// Döndürür: Map form parametreleri
  Future<Map<String, dynamic>> initialize(Map<String, dynamic> payload, {int maxRetries = 3}) async {
    // Retry mekanizması ile initialize
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Payload validation (sadece ilk denemede)
        if (attempt == 1) {
          _validatePayload(payload);
        }
        
        // Get Firebase ID token for authentication
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw PayTRException('Kullanıcı oturumu bulunamadı. Lütfen tekrar giriş yapın.');
        }
        
        // Token'ı yenile (retry durumunda)
        final forceRefresh = attempt > 1;
        final idToken = await user.getIdToken(forceRefresh);
        
        final resp = await _dio.post(
          '$_functionsBaseUrl/v1/paytr/initialize',
          data: jsonEncode(payload),
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          ),
        );

        if (resp.statusCode == 200 && resp.data is Map && resp.data['success'] == true) {
          final data = resp.data['data'];
          if (data is Map && data.isNotEmpty) {
            return Map<String, dynamic>.from(data);
          } else {
            throw PayTRException('PayTR response data is empty or invalid');
          }
        } else {
          final errorMsg = resp.data is Map ? resp.data['message'] ?? 'Unknown error' : 'Invalid response format';
          throw PayTRException('PayTR initialize failed: $errorMsg');
        }
      } on DioException catch (e) {
        final errorMessage = _getDioErrorMessage(e);
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        
        debugPrint('❌ PayTR Network Error:');
        debugPrint('   Status Code: $statusCode');
        debugPrint('   Response: $responseData');
        debugPrint('   Error Type: ${e.type}');
        
        // PayTR özel hata mesajlarını kontrol et
        if (responseData is Map) {
          final errorDetail = responseData['error']?.toString() ?? '';
          if (errorDetail.contains('zorunlu alan') || errorDetail.contains('required field')) {
            debugPrint('🚨 PayTR Zorunlu Alan Hatası: $errorDetail');
            throw PayTRException('PayTR Zorunlu Alan Hatası: $errorDetail');
          }
        }
        
        // Son deneme değilse ve retry edilebilir hata ise devam et
        if (attempt < maxRetries && _isRetryableError(e)) {
          final delay = Duration(seconds: 2 * attempt);
          debugPrint('🔄 Retry $attempt/$maxRetries after ${delay.inSeconds}s...');
          await Future.delayed(delay);
          continue;
        }
        
        // 401 hatası özel olarak ele al
        if (statusCode == 401) {
          throw PayTRException('Kimlik doğrulama hatası. Lütfen çıkış yapıp tekrar giriş yapın. (401)');
        }
        
        // 500 hatası özel olarak ele al
        if (statusCode == 500) {
          throw PayTRException('Sunucu hatası. Lütfen daha sonra tekrar deneyin. (500)');
        }
        
        throw PayTRException('Ağ hatası: $errorMessage');
      } catch (e) {
        if (e is PayTRException) rethrow;
        
        // Son deneme değilse ve genel hata ise retry yap
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: 2 * attempt));
          continue;
        }
        
        throw PayTRException('Beklenmeyen hata: $e');
      }
    }
    
    // Bu noktaya ulaşılmamalı, ama güvenlik için
    throw PayTRException('Tüm denemeler başarısız oldu.');
  }

  void _validatePayload(Map<String, dynamic> payload) {
    debugPrint('🔍 PayTR Validation başlıyor...');
    debugPrint('📦 Payload: $payload');
    
    // PayTR temel zorunlu alanları
    final requiredFields = ['email', 'amount', 'orderId', 'okUrl', 'failUrl'];
    
    for (final field in requiredFields) {
      if (!payload.containsKey(field) || payload[field] == null || payload[field].toString().trim().isEmpty) {
        debugPrint('❌ Eksik alan: $field = ${payload[field]}');
        throw PayTRException('PayTR zorunlu alanı eksik: $field');
      }
    }

    // Email format kontrolü
    final email = payload['email'] as String;
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      debugPrint('❌ Geçersiz email: $email');
      throw PayTRException('Geçersiz email formatı: $email');
    }

    // Amount kontrolü (ondalık string, örn: 100.99)
    final amount = payload['amount'];
    if (amount is String) {
      final sanitized = amount.replaceAll(',', '.').trim();
      final parsed = double.tryParse(sanitized);
      if (parsed == null || parsed <= 0) {
        debugPrint('❌ Geçersiz amount: $amount');
        throw PayTRException('Geçersiz tutar (ondalık, örn: 100.99): $amount');
      }
      // Normalize to 2 decimals
      payload['amount'] = parsed.toStringAsFixed(2);
    } else {
      debugPrint('❌ Amount string değil: $amount (${amount.runtimeType})');
      throw PayTRException('Amount string formatında olmalı (örn: 100.99): $amount');
    }

    // Kullanıcı bilgileri kontrolü (opsiyonel ama önerilen)
    final userName = (payload['userName']?.toString() ?? '').trim();
    final userAddress = (payload['userAddress']?.toString() ?? '').trim();
    final userPhone = (payload['userPhone']?.toString() ?? '').trim();
    
    debugPrint('👤 UserName: "$userName" (${userName.length} karakter)');
    debugPrint('📍 UserAddress: "$userAddress" (${userAddress.length} karakter)');
    debugPrint('📞 UserPhone: "$userPhone" (${userPhone.length} karakter)');

    if (userName.length < 2) {
      debugPrint('⚠️ UserName çok kısa, varsayılan kullanılacak');
    }
    
    if (userAddress.length < 5) {
      debugPrint('⚠️ UserAddress çok kısa, varsayılan kullanılacak');
    }

    debugPrint('✅ PayTR Validation tamamlandı');
  }

  /// Check if error is retryable
  bool _isRetryableError(DioException e) {
    // Retry for these error types
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        // Retry for server errors (5xx) but not client errors (4xx)
        final statusCode = e.response?.statusCode;
        return statusCode != null && statusCode >= 500 && statusCode < 600;
      default:
        return false;
    }
  }

  String _getDioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Bağlantı zaman aşımı - İnternet bağlantınızı kontrol edin';
      case DioExceptionType.sendTimeout:
        return 'Gönderim zaman aşımı - Tekrar deneyin';
      case DioExceptionType.receiveTimeout:
        return 'Yanıt zaman aşımı - Tekrar deneyin';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        
        if (statusCode == 401) {
          return 'Kimlik doğrulama hatası (401)';
        } else if (statusCode == 500) {
          return 'Sunucu hatası (500)';
        } else if (statusCode != null && statusCode >= 400) {
          String errorDetail = '';
          if (responseData is Map && responseData['error'] != null) {
            errorDetail = ' - ${responseData['error']}';
          }
          return 'Sunucu hatası ($statusCode)$errorDetail';
        }
        return 'Sunucu hatası ($statusCode)';
      case DioExceptionType.cancel:
        return 'İstek iptal edildi';
      case DioExceptionType.connectionError:
        return 'Bağlantı hatası - İnternet bağlantınızı kontrol edin';
      default:
        return e.message ?? 'Bilinmeyen ağ hatası';
    }
  }
}

/// Custom exception for PayTR related errors
class PayTRException implements Exception {
  final String message;
  
  PayTRException(this.message);
  
  @override
  String toString() => 'PayTR Error: $message';
}


