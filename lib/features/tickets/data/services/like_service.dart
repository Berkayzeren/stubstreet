// lib/features/tickets/data/services/like_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LikeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Beğeni ekleme/kaldırma (toggle)
  Future<bool> toggleLike(String ticketId, String userId) async {
    try {
      // Kullanıcının bu bileti beğenip beğenmediğini kontrol et
      final existingLike = await _firestore
          .collection('likes')
          .where('ticketId', isEqualTo: ticketId)
          .where('userId', isEqualTo: userId)
          .get();

      if (existingLike.docs.isNotEmpty) {
        // Beğeni varsa kaldır
        await _firestore
            .collection('likes')
            .doc(existingLike.docs.first.id)
            .delete();
        return false; // Beğeni kaldırıldı
      } else {
        // Beğeni yoksa ekle
        await _firestore.collection('likes').add({
          'ticketId': ticketId,
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true; // Beğeni eklendi
      }
    } catch (e) {
      throw Exception('Beğeni işlemi başarısız: $e');
    }
  }

  // Belirli bir bilet için beğeni sayısını getir
  Future<int> getLikeCount(String ticketId) async {
    try {
      final snapshot = await _firestore
          .collection('likes')
          .where('ticketId', isEqualTo: ticketId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Beğeni sayısı alınamadı: $e');
    }
  }

  // Kullanıcının belirli bir bileti beğenip beğenmediğini kontrol et
  Future<bool> isLikedByUser(String ticketId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection('likes')
          .where('ticketId', isEqualTo: ticketId)
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Beğeni durumu kontrol edilemedi: $e');
    }
  }

  // Kullanıcının beğendiği biletleri getir
  Future<List<String>> getUserLikedTickets(String userId) async {
    try {
      debugPrint('🔍 DEBUG: getUserLikedTickets çağrıldı - userId: $userId');
      
      final snapshot = await _firestore
          .collection('likes')
          .where('userId', isEqualTo: userId)
          .get();
      
      debugPrint('📊 DEBUG: ${snapshot.docs.length} beğeni bulundu');
      
      // Sort by creation time if available
      final ticketData = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'ticketId': data['ticketId'] as String,
          'createdAt': data['createdAt'],
        };
      }).toList();
      
      // Sort by createdAt if available
      ticketData.sort((a, b) {
        final aTime = a['createdAt'] as dynamic;
        final bTime = b['createdAt'] as dynamic;
        if (aTime == null || bTime == null) return 0;
        return (bTime as dynamic).compareTo(aTime as dynamic);
      });
      
      return ticketData.map((item) => item['ticketId'] as String).toList();
    } catch (e) {
      throw Exception('Beğenilen biletler alınamadı: $e');
    }
  }

  // Beğeni sayısını gerçek zamanlı olarak dinle
  Stream<int> watchLikeCount(String ticketId) {
    return _firestore
        .collection('likes')
        .where('ticketId', isEqualTo: ticketId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Kullanıcının beğeni durumunu gerçek zamanlı olarak dinle
  Stream<bool> watchIsLikedByUser(String ticketId, String userId) {
    return _firestore
        .collection('likes')
        .where('ticketId', isEqualTo: ticketId)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }
}
