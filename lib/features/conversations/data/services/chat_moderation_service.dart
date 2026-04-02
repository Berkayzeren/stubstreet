// lib/features/conversations/data/services/chat_moderation_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service for handling chat moderation features like reporting and blocking users
class ChatModerationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Report a user for inappropriate behavior
  Future<void> reportUser({
    required String reportedUserId,
    required String reason,
    String? details,
    String? messageId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to report someone');
    }

    try {
      await _firestore.collection('reports').add({
        'reporterId': currentUser.uid,
        'reportedUserId': reportedUserId,
        'reason': reason,
        'details': details,
        'messageId': messageId,
        'status': 'pending', // pending, reviewed, resolved, dismissed
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also add to user's report count for tracking
      await _firestore.collection('users').doc(reportedUserId).update({
        'reportCount': FieldValue.increment(1),
        'lastReportedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }

  /// Block a user to prevent further communication
  Future<void> blockUser(String blockedUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to block someone');
    }

    try {
      // Add to current user's block list
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('blockedUsers')
          .doc(blockedUserId)
          .set({
        'blockedUserId': blockedUserId,
        'blockedAt': FieldValue.serverTimestamp(),
      });

      // Also add to a global blocks collection for easier querying
      await _firestore.collection('blocks').add({
        'blockerId': currentUser.uid,
        'blockedUserId': blockedUserId,
        'blockedAt': FieldValue.serverTimestamp(),
      });

      // Close any existing conversation between these users
      await _closeConversation(currentUser.uid, blockedUserId);
    } catch (e) {
      throw Exception('Failed to block user: $e');
    }
  }

  /// Unblock a user
  Future<void> unblockUser(String blockedUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to unblock someone');
    }

    try {
      // Remove from current user's block list
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('blockedUsers')
          .doc(blockedUserId)
          .delete();

      // Remove from global blocks collection
      final blockQuery = await _firestore
          .collection('blocks')
          .where('blockerId', isEqualTo: currentUser.uid)
          .where('blockedUserId', isEqualTo: blockedUserId)
          .get();

      for (final doc in blockQuery.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to unblock user: $e');
    }
  }

  /// Check if a user is blocked by the current user
  Future<bool> isUserBlocked(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final blockDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('blockedUsers')
          .doc(userId)
          .get();

      return blockDoc.exists;
    } catch (e) {
      debugPrint('Error checking if user is blocked: $e');
      return false;
    }
  }

  /// Check if the current user is blocked by another user
  Future<bool> isBlockedByUser(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final blockDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('blockedUsers')
          .doc(currentUser.uid)
          .get();

      return blockDoc.exists;
    } catch (e) {
      debugPrint('Error checking if blocked by user: $e');
      return false;
    }
  }

  /// Get list of blocked users
  Future<List<String>> getBlockedUsers() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    try {
      final blockedUsers = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('blockedUsers')
          .get();

      return blockedUsers.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error getting blocked users: $e');
      return [];
    }
  }

  /// Clear chat history between two users
  Future<void> clearChatHistory(String otherUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to clear chat');
    }

    try {
      // Find the conversation between these users
      final conversationQuery = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: currentUser.uid)
          .get();

      for (final conversationDoc in conversationQuery.docs) {
        final conversationData = conversationDoc.data();
        final participants = List<String>.from(conversationData['participants'] ?? []);
        
        if (participants.contains(otherUserId)) {
          // Mark messages as deleted for the current user
          final messagesQuery = await _firestore
              .collection('conversations')
              .doc(conversationDoc.id)
              .collection('messages')
              .get();

          final batch = _firestore.batch();
          
          for (final messageDoc in messagesQuery.docs) {
            batch.update(messageDoc.reference, {
              'deletedFor': FieldValue.arrayUnion([currentUser.uid]),
            });
          }
          
          await batch.commit();
          break;
        }
      }
    } catch (e) {
      throw Exception('Failed to clear chat history: $e');
    }
  }

  /// Close conversation between two users (used when blocking)
  Future<void> _closeConversation(String userId1, String userId2) async {
    try {
      final conversationQuery = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: userId1)
          .get();

      for (final conversationDoc in conversationQuery.docs) {
        final conversationData = conversationDoc.data();
        final participants = List<String>.from(conversationData['participants'] ?? []);
        
        if (participants.contains(userId2)) {
          await conversationDoc.reference.update({
            'status': 'blocked',
            'closedAt': FieldValue.serverTimestamp(),
          });
          break;
        }
      }
    } catch (e) {
      debugPrint('Error closing conversation: $e');
    }
  }

  /// Get report reasons (can be localized)
  static List<String> getReportReasons() {
    return [
      'Spam',
      'Harassment',
      'Inappropriate Content',
      'Fraud',
      'Other',
    ];
  }
}
