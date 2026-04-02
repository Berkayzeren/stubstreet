// lib/features/conversations/presentation/providers/typing_indicator_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'typing_indicator_provider.g.dart';

/// Typing indicator provider that manages real-time typing status
/// 
/// This provider handles:
/// - Starting and stopping typing indicators
/// - Real-time synchronization across devices
/// - Automatic timeout for stuck typing indicators
/// - Multiple user typing status in conversations
/// - Memory cleanup and optimization
@riverpod
class TypingIndicator extends _$TypingIndicator {
  // Map to track active timers for automatic cleanup
  final Map<String, Timer> _typingTimers = {};
  
  // Firestore reference for typing indicators
  late final CollectionReference _typingRef;
  
  // Stream subscriptions for cleanup
  final Map<String, StreamSubscription> _subscriptions = {};

  @override
  Map<String, Map<String, bool>> build() {
    // Initialize Firestore reference
    _typingRef = FirebaseFirestore.instance.collection('typing_indicators');
    
    return {};
  }

  /// Start typing indicator for a user in a conversation
  /// 
  /// @param conversationId - ID of the conversation
  /// @param userId - ID of the user who started typing
  /// @param autoTimeout - Duration after which typing stops automatically (default: 5 seconds)
  Future<void> startTyping(
    String conversationId,
    String userId, {
    Duration autoTimeout = const Duration(seconds: 5),
  }) async {
    try {
      // Cancel any existing timer for this user/conversation
      final timerKey = '${conversationId}_$userId';
      _typingTimers[timerKey]?.cancel();

      // Update local state immediately for responsive UI
      state = {
        ...state,
        conversationId: {
          ...?state[conversationId],
          userId: true,
        },
      };

      // Update Firestore with typing status
      await _typingRef.doc(timerKey).set({
        'conversationId': conversationId,
        'userId': userId,
        'isTyping': true,
        'timestamp': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Set auto-timeout timer
      _typingTimers[timerKey] = Timer(autoTimeout, () {
        stopTyping(conversationId, userId);
      });

      debugPrint('✅ Started typing indicator: $userId in $conversationId');

    } catch (e) {
      debugPrint('❌ Failed to start typing indicator: $e');
    }
  }

  /// Stop typing indicator for a user in a conversation
  /// 
  /// @param conversationId - ID of the conversation
  /// @param userId - ID of the user who stopped typing
  Future<void> stopTyping(String conversationId, String userId) async {
    try {
      final timerKey = '${conversationId}_$userId';
      
      // Cancel timer
      _typingTimers[timerKey]?.cancel();
      _typingTimers.remove(timerKey);

      // Update local state
      final conversationTyping = Map<String, bool>.from(state[conversationId] ?? {});
      conversationTyping.remove(userId);
      
      if (conversationTyping.isEmpty) {
        state = Map<String, Map<String, bool>>.from(state)..remove(conversationId);
      } else {
        state = {
          ...state,
          conversationId: conversationTyping,
        };
      }

      // Remove from Firestore
      await _typingRef.doc(timerKey).delete();

      debugPrint('✅ Stopped typing indicator: $userId in $conversationId');

    } catch (e) {
      debugPrint('❌ Failed to stop typing indicator: $e');
    }
  }

  /// Listen to typing indicators for a specific conversation
  /// 
  /// @param conversationId - ID of the conversation to monitor
  void listenToConversationTyping(String conversationId) {
    // Check if already listening
    if (_subscriptions.containsKey(conversationId)) {
      return;
    }

    try {
      final subscription = _typingRef
          .where('conversationId', isEqualTo: conversationId)
          .where('isTyping', isEqualTo: true)
          .snapshots()
          .listen(
            (snapshot) => _handleTypingSnapshot(conversationId, snapshot),
            onError: (error) {
              debugPrint('❌ Typing indicator stream error: $error');
            },
          );

      _subscriptions[conversationId] = subscription;
      debugPrint('✅ Started listening to typing indicators for: $conversationId');

    } catch (e) {
      debugPrint('❌ Failed to listen to typing indicators: $e');
    }
  }

  /// Stop listening to typing indicators for a conversation
  /// 
  /// @param conversationId - ID of the conversation to stop monitoring
  void stopListeningToConversationTyping(String conversationId) {
    try {
      _subscriptions[conversationId]?.cancel();
      _subscriptions.remove(conversationId);

      // Clear local state for this conversation
      state = Map<String, Map<String, bool>>.from(state)..remove(conversationId);

      debugPrint('✅ Stopped listening to typing indicators for: $conversationId');

    } catch (e) {
      debugPrint('❌ Failed to stop listening to typing indicators: $e');
    }
  }

  /// Handle typing indicator snapshot updates
  void _handleTypingSnapshot(String conversationId, QuerySnapshot snapshot) {
    try {
      final typingUsers = <String, bool>{};
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          final userId = data['userId'] as String?;
          final isTyping = data['isTyping'] as bool?;
          final timestamp = data['timestamp'] as Timestamp?;
          
          if (userId != null && isTyping == true) {
            // Check if typing indicator is not too old (prevent stuck indicators)
            if (timestamp != null) {
              final age = DateTime.now().difference(timestamp.toDate());
              if (age.inSeconds < 30) { // 30 second maximum age
                typingUsers[userId] = true;
              } else {
                // Clean up old typing indicator
                _cleanupOldTypingIndicator(doc.id);
              }
            } else {
              typingUsers[userId] = true;
            }
          }
        }
      }

      // Update state
      if (typingUsers.isEmpty) {
        state = Map<String, Map<String, bool>>.from(state)..remove(conversationId);
      } else {
        state = {
          ...state,
          conversationId: typingUsers,
        };
      }

    } catch (e) {
      debugPrint('❌ Error handling typing snapshot: $e');
    }
  }

  /// Clean up old typing indicator
  Future<void> _cleanupOldTypingIndicator(String docId) async {
    try {
      await _typingRef.doc(docId).delete();
      debugPrint('🧹 Cleaned up old typing indicator: $docId');
    } catch (e) {
      debugPrint('❌ Failed to cleanup old typing indicator: $e');
    }
  }

  /// Update typing activity timestamp (keep-alive mechanism)
  /// 
  /// This should be called periodically while a user is actively typing
  /// to prevent the typing indicator from expiring.
  Future<void> updateTypingActivity(String conversationId, String userId) async {
    try {
      final timerKey = '${conversationId}_$userId';
      
      await _typingRef.doc(timerKey).update({
        'lastActivity': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      debugPrint('❌ Failed to update typing activity: $e');
    }
  }

  /// Get typing users for a specific conversation
  Map<String, bool> getTypingUsers(String conversationId) {
    return state[conversationId] ?? {};
  }

  /// Check if any user is typing in a conversation
  bool isAnyoneTyping(String conversationId) {
    final typingUsers = state[conversationId] ?? {};
    return typingUsers.values.any((isTyping) => isTyping);
  }

  /// Check if a specific user is typing in a conversation
  bool isUserTyping(String conversationId, String userId) {
    return state[conversationId]?[userId] ?? false;
  }

  /// Clean up all resources
  void dispose() {
    // Cancel all timers
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();

    // Cancel all subscriptions
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Clear state
    state = {};
  }

  /// Perform periodic cleanup of stuck typing indicators
  /// 
  /// This method should be called periodically (e.g., every minute)
  /// to remove typing indicators that may have gotten stuck due to
  /// network issues or app crashes.
  Future<void> performPeriodicCleanup() async {
    try {
      // Find typing indicators older than 1 minute
      final cutoffTime = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(minutes: 1)),
      );

      final oldIndicators = await _typingRef
          .where('timestamp', isLessThan: cutoffTime)
          .get();

      // Delete old indicators
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in oldIndicators.docs) {
        batch.delete(doc.reference);
      }

      if (oldIndicators.docs.isNotEmpty) {
        await batch.commit();
        debugPrint('🧹 Cleaned up ${oldIndicators.docs.length} stuck typing indicators');
      }

    } catch (e) {
      debugPrint('❌ Failed to perform periodic cleanup: $e');
    }
  }
}

/// Provider to get typing users for a specific conversation
@riverpod
Map<String, bool> typingUsers(Ref ref, String conversationId) {
  final typingIndicator = ref.watch(typingIndicatorProvider);
  return typingIndicator[conversationId] ?? {};
}
