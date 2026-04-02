// lib/core/services/user_moderation_service.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Kullanıcı moderasyon işlemleri için servis
class UserModerationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Kullanıcıyı rapor et
  static Future<void> reportUser({
    required String reportedUserId,
    required String reason,
    String? customReason,
    String? messageId,
    String? conversationId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturum açmamış');
      }

      final reportId = _firestore.collection('reports').doc().id;
      
      await _firestore.collection('reports').doc(reportId).set({
        'id': reportId,
        'reporterId': currentUser.uid,
        'reportedUserId': reportedUserId,
        'reason': reason,
        'customReason': customReason,
        'messageId': messageId,
        'conversationId': conversationId,
        'status': 'pending', // pending, reviewed, resolved, dismissed
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'reviewedBy': null,
        'reviewedAt': null,
        'adminNotes': null,
        'actionTaken': null, // warning, temporary_ban, permanent_ban, no_action
      });

      debugPrint('✅ Kullanıcı raporu oluşturuldu: $reportId');
    } catch (e) {
      debugPrint('❌ Kullanıcı raporlama hatası: $e');
      rethrow;
    }
  }

  /// Kullanıcıyı engelle (kişisel engelleme)
  static Future<void> blockUser(String blockedUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturum açmamış');
      }

      // Kendi kendini engelleyemez
      if (currentUser.uid == blockedUserId) {
        throw Exception('Kendinizi engelleyemezsiniz');
      }

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('blockedUsers')
          .doc(blockedUserId)
          .set({
        'blockedUserId': blockedUserId,
        'blockedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Kullanıcı engellendi: $blockedUserId');
    } catch (e) {
      debugPrint('❌ Kullanıcı engelleme hatası: $e');
      rethrow;
    }
  }

  /// Kullanıcı engelini kaldır
  static Future<void> unblockUser(String blockedUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturum açmamış');
      }

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('blockedUsers')
          .doc(blockedUserId)
          .delete();

      debugPrint('✅ Kullanıcı engeli kaldırıldı: $blockedUserId');
    } catch (e) {
      debugPrint('❌ Kullanıcı engel kaldırma hatası: $e');
      rethrow;
    }
  }

  /// Kullanıcının engellenip engellenmediğini kontrol et
  static Future<bool> isUserBlocked(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('blockedUsers')
          .doc(userId)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('❌ Kullanıcı engel kontrolü hatası: $e');
      return false;
    }
  }

  /// Admin: Kullanıcıyı banla
  static Future<void> banUser({
    required String userId,
    required String reason,
    String? customReason,
    DateTime? banUntil, // null = permanent ban
    required String adminId,
  }) async {
    try {
      final banData = {
        'userId': userId,
        'reason': reason,
        'customReason': customReason,
        'bannedBy': adminId,
        'bannedAt': FieldValue.serverTimestamp(),
        'banUntil': banUntil != null ? Timestamp.fromDate(banUntil) : null,
        'isPermanent': banUntil == null,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Bans koleksiyonuna ekle
      await _firestore.collection('bans').doc(userId).set(banData);

      // User dokümanını güncelle
      await _firestore.collection('users').doc(userId).update({
        'isBanned': true,
        'banReason': reason,
        'bannedAt': FieldValue.serverTimestamp(),
        'bannedBy': adminId,
        'banUntil': banUntil != null ? Timestamp.fromDate(banUntil) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Kullanıcı banlandı: $userId');
    } catch (e) {
      debugPrint('❌ Kullanıcı banlama hatası: $e');
      rethrow;
    }
  }

  /// Admin: Kullanıcı banını kaldır
  static Future<void> unbanUser({
    required String userId,
    required String adminId,
    String? reason,
  }) async {
    try {
      // Bans koleksiyonunu güncelle
      await _firestore.collection('bans').doc(userId).update({
        'isActive': false,
        'unbannedBy': adminId,
        'unbannedAt': FieldValue.serverTimestamp(),
        'unbanReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // User dokümanını güncelle
      await _firestore.collection('users').doc(userId).update({
        'isBanned': false,
        'banReason': null,
        'bannedAt': null,
        'bannedBy': null,
        'banUntil': null,
        'unbannedBy': adminId,
        'unbannedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Kullanıcı ban kaldırıldı: $userId');
    } catch (e) {
      debugPrint('❌ Kullanıcı ban kaldırma hatası: $e');
      rethrow;
    }
  }

  /// Kullanıcının ban durumunu kontrol et
  static Future<UserBanStatus> getUserBanStatus(String userId) async {
    try {
      final banDoc = await _firestore.collection('bans').doc(userId).get();
      
      if (!banDoc.exists) {
        return UserBanStatus(isBanned: false);
      }

      final banData = banDoc.data() as Map<String, dynamic>;
      final isActive = banData['isActive'] ?? false;
      
      if (!isActive) {
        return UserBanStatus(isBanned: false);
      }

      final banUntil = banData['banUntil'] as Timestamp?;
      final isPermanent = banData['isPermanent'] ?? false;

      // Geçici ban süresi dolmuş mu kontrol et
      if (!isPermanent && banUntil != null) {
        if (DateTime.now().isAfter(banUntil.toDate())) {
          // Ban süresi dolmuş, otomatik kaldır
          await unbanUser(
            userId: userId,
            adminId: 'system',
            reason: 'Ban süresi doldu',
          );
          return UserBanStatus(isBanned: false);
        }
      }

      return UserBanStatus(
        isBanned: true,
        reason: banData['reason'],
        customReason: banData['customReason'],
        bannedAt: (banData['bannedAt'] as Timestamp?)?.toDate(),
        banUntil: banUntil?.toDate(),
        isPermanent: isPermanent,
        bannedBy: banData['bannedBy'],
      );
    } catch (e) {
      debugPrint('❌ Ban durumu kontrolü hatası: $e');
      return UserBanStatus(isBanned: false);
    }
  }

  /// Tüm raporları getir (admin için)
  static Stream<List<UserReport>> getReports({
    String? status,
    int limit = 50,
  }) {
    Query query = _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserReport.fromFirestore(doc);
      }).toList();
    });
  }

  /// Raporu güncelle (admin için)
  static Future<void> updateReport({
    required String reportId,
    required String status,
    required String adminId,
    String? adminNotes,
    String? actionTaken,
  }) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'status': status,
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'adminNotes': adminNotes,
        'actionTaken': actionTaken,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Rapor güncellendi: $reportId');
    } catch (e) {
      debugPrint('❌ Rapor güncelleme hatası: $e');
      rethrow;
    }
  }

  /// Banlı kullanıcıları getir (admin için)
  static Stream<List<BannedUser>> getBannedUsers({int limit = 50}) {
    return _firestore
        .collection('bans')
        .where('isActive', isEqualTo: true)
        .orderBy('bannedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BannedUser.fromFirestore(doc);
      }).toList();
    });
  }
}

/// Kullanıcı ban durumu
class UserBanStatus {
  final bool isBanned;
  final String? reason;
  final String? customReason;
  final DateTime? bannedAt;
  final DateTime? banUntil;
  final bool isPermanent;
  final String? bannedBy;

  UserBanStatus({
    required this.isBanned,
    this.reason,
    this.customReason,
    this.bannedAt,
    this.banUntil,
    this.isPermanent = false,
    this.bannedBy,
  });

  String get banMessage {
    if (!isBanned) return '';
    
    if (isPermanent) {
      return 'Hesabınız kalıcı olarak askıya alınmıştır.\nSebep: $reason';
    } else if (banUntil != null) {
      return 'Hesabınız ${banUntil!.day}/${banUntil!.month}/${banUntil!.year} tarihine kadar askıya alınmıştır.\nSebep: $reason';
    }
    
    return 'Hesabınız askıya alınmıştır.\nSebep: $reason';
  }
}

/// Kullanıcı raporu
class UserReport {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String reason;
  final String? customReason;
  final String? messageId;
  final String? conversationId;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? adminNotes;
  final String? actionTaken;

  UserReport({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    this.customReason,
    this.messageId,
    this.conversationId,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.adminNotes,
    this.actionTaken,
  });

  factory UserReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserReport(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      reportedUserId: data['reportedUserId'] ?? '',
      reason: data['reason'] ?? '',
      customReason: data['customReason'],
      messageId: data['messageId'],
      conversationId: data['conversationId'],
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewedBy'],
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      adminNotes: data['adminNotes'],
      actionTaken: data['actionTaken'],
    );
  }
}

/// Banlı kullanıcı
class BannedUser {
  final String userId;
  final String reason;
  final String? customReason;
  final String bannedBy;
  final DateTime? bannedAt;
  final DateTime? banUntil;
  final bool isPermanent;
  final bool isActive;

  BannedUser({
    required this.userId,
    required this.reason,
    this.customReason,
    required this.bannedBy,
    this.bannedAt,
    this.banUntil,
    required this.isPermanent,
    required this.isActive,
  });

  factory BannedUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BannedUser(
      userId: data['userId'] ?? '',
      reason: data['reason'] ?? '',
      customReason: data['customReason'],
      bannedBy: data['bannedBy'] ?? '',
      bannedAt: (data['bannedAt'] as Timestamp?)?.toDate(),
      banUntil: (data['banUntil'] as Timestamp?)?.toDate(),
      isPermanent: data['isPermanent'] ?? false,
      isActive: data['isActive'] ?? true,
    );
  }
}