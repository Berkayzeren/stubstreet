// lib/features/conversations/data/services/conversation_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ConversationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Backend API base URL - environment'a göre değiştirilebilir
  static const String _baseUrl = 'http://localhost:5001/stubstreet-2024/us-central1/api';

  /// Conversation'ı sil (soft delete)
  Future<bool> deleteConversation(String conversationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      // Backend API'sine DELETE isteği gönder
      final response = await http.delete(
        Uri.parse('$_baseUrl/v1/conversations/$conversationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await user.getIdToken()}',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] == true;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Conversation silinemedi');
      }
    } catch (e) {
      throw Exception('Conversation silme hatası: $e');
    }
  }

  /// Conversation'ı arşivle
  Future<bool> archiveConversation(String conversationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      await _firestore.collection('conversations').doc(conversationId).update({
        'status': 'archived',
        'archivedAt': FieldValue.serverTimestamp(),
        'archivedBy': user.uid,
      });

      return true;
    } catch (e) {
      throw Exception('Conversation arşivleme hatası: $e');
    }
  }

  /// Conversation'ı geri yükle
  Future<bool> restoreConversation(String conversationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      await _firestore.collection('conversations').doc(conversationId).update({
        'status': 'active',
        'restoredAt': FieldValue.serverTimestamp(),
        'restoredBy': user.uid,
      });

      return true;
    } catch (e) {
      throw Exception('Conversation geri yükleme hatası: $e');
    }
  }

  /// Kullanıcının conversation'larını getir (silinmemiş olanlar)
  Stream<List<Map<String, dynamic>>> getConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .where('isActive', isEqualTo: true) // Sadece aktif conversation'lar
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  /// Conversation detaylarını getir
  Future<Map<String, dynamic>?> getConversationDetails(String conversationId) async {
    try {
      final doc = await _firestore.collection('conversations').doc(conversationId).get();
      
      if (!doc.exists) {
        return null;
      }

      return {
        'id': doc.id,
        ...doc.data()!,
      };
    } catch (e) {
      throw Exception('Conversation detayları alınamadı: $e');
    }
  }
}
