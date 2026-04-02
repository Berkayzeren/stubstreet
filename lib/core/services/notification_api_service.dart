// lib/core/services/notification_api_service.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

/// API servisi ile bildirim gönderme ve yönetme
class NotificationApiService {
  static const String _baseUrl = 'https://us-central1-stubstreet-dev.cloudfunctions.net/api/v1';
  
  /// Manuel bildirim gönder
  static Future<NotificationResult> sendManualNotification({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String type = 'general',
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return NotificationResult.error('Kullanıcı oturum açmamış');
      }

      final token = await user.getIdToken();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userIds': userIds,
          'title': title,
          'body': body,
          'data': data ?? {},
          'type': type,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final data = responseData['data'];
          return NotificationResult.success(
            totalSent: data['totalSent'] ?? 0,
            totalFailed: data['totalFailed'] ?? 0,
            totalUsers: data['totalUsers'] ?? 0,
          );
        } else {
          return NotificationResult.error(responseData['error'] ?? 'Bilinmeyen hata');
        }
      } else {
        return NotificationResult.error('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Notification send error: $e');
      return NotificationResult.error('Ağ hatası: $e');
    }
  }

  /// Kullanıcının bildirim ayarlarını getir
  static Future<NotificationSettings?> getUserNotificationSettings(String userId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final token = await user.getIdToken();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications/settings/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return NotificationSettings.fromJson(responseData['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Get notification settings error: $e');
      return null;
    }
  }

  /// Kullanıcının bildirim ayarlarını güncelle
  static Future<bool> updateUserNotificationSettings(
    String userId,
    NotificationSettings settings,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final token = await user.getIdToken();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications/settings/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(settings.toJson()),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Update notification settings error: $e');
      return false;
    }
  }

  /// Tüm kullanıcılara duyuru gönder
  static Future<NotificationResult> sendAnnouncementToAll({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Bu örnekte sadece admin kullanıcıları alıyoruz
    // Gerçek uygulamada tüm kullanıcı ID'lerini almak için ayrı bir endpoint olmalı
    return sendManualNotification(
      userIds: ['all'], // Backend'de 'all' değeri tüm kullanıcıları temsil edebilir
      title: title,
      body: body,
      data: data,
      type: 'announcement',
    );
  }

  /// Belirli kategorideki kullanıcılara bildirim gönder
  static Future<NotificationResult> sendNotificationToCategory({
    required String category, // 'buyers', 'sellers', 'premium' vs.
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    return sendManualNotification(
      userIds: [category], // Backend'de kategori bazlı filtreleme
      title: title,
      body: body,
      data: data,
      type: 'category',
    );
  }
}

/// Bildirim gönderme sonucu
class NotificationResult {
  final bool success;
  final String? error;
  final int totalSent;
  final int totalFailed;
  final int totalUsers;

  NotificationResult._({
    required this.success,
    this.error,
    this.totalSent = 0,
    this.totalFailed = 0,
    this.totalUsers = 0,
  });

  factory NotificationResult.success({
    required int totalSent,
    required int totalFailed,
    required int totalUsers,
  }) {
    return NotificationResult._(
      success: true,
      totalSent: totalSent,
      totalFailed: totalFailed,
      totalUsers: totalUsers,
    );
  }

  factory NotificationResult.error(String error) {
    return NotificationResult._(
      success: false,
      error: error,
    );
  }

  String get message {
    if (!success) return error ?? 'Bilinmeyen hata';
    return '$totalSent/$totalUsers kullanıcıya bildirim gönderildi';
  }
}

/// Kullanıcı bildirim ayarları
class NotificationSettings {
  final bool pushNotifications;
  final bool emailNotifications;
  final bool messageNotifications;
  final bool orderNotifications;
  final bool announcementNotifications;
  final bool marketingNotifications;

  const NotificationSettings({
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.messageNotifications = true,
    this.orderNotifications = true,
    this.announcementNotifications = true,
    this.marketingNotifications = false,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pushNotifications: json['pushNotifications'] ?? true,
      emailNotifications: json['emailNotifications'] ?? true,
      messageNotifications: json['messageNotifications'] ?? true,
      orderNotifications: json['orderNotifications'] ?? true,
      announcementNotifications: json['announcementNotifications'] ?? true,
      marketingNotifications: json['marketingNotifications'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'messageNotifications': messageNotifications,
      'orderNotifications': orderNotifications,
      'announcementNotifications': announcementNotifications,
      'marketingNotifications': marketingNotifications,
    };
  }

  NotificationSettings copyWith({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? messageNotifications,
    bool? orderNotifications,
    bool? announcementNotifications,
    bool? marketingNotifications,
  }) {
    return NotificationSettings(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      messageNotifications: messageNotifications ?? this.messageNotifications,
      orderNotifications: orderNotifications ?? this.orderNotifications,
      announcementNotifications: announcementNotifications ?? this.announcementNotifications,
      marketingNotifications: marketingNotifications ?? this.marketingNotifications,
    );
  }
}
