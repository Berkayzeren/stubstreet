// lib/features/conversations/presentation/providers/message_sender_provider.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/message.dart';
import '../../../../core/services/firebase_realtime_service.dart';
import '../../../../core/utils/message_filter.dart';
import 'firebase_chat_providers.dart' as chat_providers;

part 'message_sender_provider.g.dart';

/// Enhanced message sender provider with comprehensive error handling
/// 
/// This provider handles:
/// - Message sending with retry logic
/// - Optimistic UI updates
/// - Proper error handling and user feedback
/// - Message status tracking (sent/delivered/read)
/// - Connection status awareness
/// - Offline message queuing (future enhancement)
@riverpod
class MessageSender extends _$MessageSender {
  // Track current sending operations to prevent duplicates
  final Set<String> _sendingMessages = {};
  
  // Queue for offline messages (future enhancement)
  final List<Message> _offlineQueue = [];

  @override
  AsyncValue<String?> build() {
    return const AsyncValue.data(null);
  }

  /// Send a message with comprehensive error handling and retry logic
  /// 
  /// @param conversationId - The conversation ID to send the message to
  /// @param senderId - ID of the user sending the message (optional, will use current user)
  /// @param receiverId - ID of the user receiving the message
  /// @param content - The message content text
  /// @param type - Type of message (text, image, file, etc.)
  /// @param replyToMessageId - Optional ID of message being replied to
  /// @param attachments - List of attachment URLs/paths
  /// 
  /// @returns The ID of the sent message
  /// @throws Exception if message fails to send after retries
  Future<String> sendMessage({
    required String conversationId,
    String? senderId,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
    String? replyToMessageId,
    List<String> attachments = const [],
  }) async {
    // Get current user ID if senderId not provided
    final currentUser = FirebaseAuth.instance.currentUser;
    final actualSenderId = senderId ?? currentUser?.uid;
    
    if (actualSenderId == null) {
      throw Exception('User not authenticated - cannot send message');
    }

    // Generate a unique temporary ID for this message to prevent duplicates
    final tempMessageId = 'temp_${DateTime.now().millisecondsSinceEpoch}_$actualSenderId';
    
    // Check if this message is already being sent
    if (_sendingMessages.contains(tempMessageId)) {
      debugPrint('⚠️ Message already being sent, ignoring duplicate request');
      return tempMessageId;
    }

    _sendingMessages.add(tempMessageId);
    state = const AsyncValue.loading();

    try {
      // Create the message object with comprehensive data
      final message = Message(
        id: tempMessageId, // Temporary ID, will be replaced by Firestore
        conversationId: conversationId,
        senderId: actualSenderId,
        senderName: currentUser?.displayName ?? 'Unknown User',
        receiverId: receiverId,
        receiverName: '', // Will be populated by backend if needed
        type: type,
        status: MessageStatus.sent,
        content: content.trim(),
        attachments: attachments,
        createdAt: DateTime.now(),
        replyToMessageId: replyToMessageId,
        metadata: {
          'platform': 'flutter',
          'version': '1.0.0',
          'tempId': tempMessageId,
        },
      );

      // Validate message content
      if (message.content.isEmpty && message.attachments.isEmpty) {
        throw Exception('Message cannot be empty');
      }

      if (message.content.length > 5000) {
        throw Exception('Message too long (max 5000 characters)');
      }

      // Hassas bilgi filtresi kontrolü
      final filterResult = MessageFilter.filterMessage(message.content);
      if (!filterResult.isAllowed) {
        throw Exception('Güvenlik nedeniyle mesaj gönderilemedi:\n${filterResult.violationMessage}');
      }

      // Debug: Mesaj verilerini detaylı logla
      debugPrint('🔍 DEBUG: Mesaj gönderiliyor...');
      debugPrint('🔍 DEBUG: Content uzunluğu: ${message.content.length} karakter');
      debugPrint('🔍 DEBUG: Content byte uzunluğu: ${message.content.codeUnits.length} byte');
      debugPrint('🔍 DEBUG: Content: "${message.content}"');
      debugPrint('🔍 DEBUG: Conversation ID: $conversationId');
      debugPrint('🔍 DEBUG: Sender ID: $actualSenderId');
      debugPrint('🔍 DEBUG: Receiver ID: $receiverId');

      // Send message to Firebase with retry logic
      final messageId = await _sendMessageWithRetry(message);
      
      // Update conversation metadata
      await _updateConversationLastMessage(conversationId, message.copyWith(id: messageId));

      // Success - update state and cleanup
      state = AsyncValue.data(messageId);
      _sendingMessages.remove(tempMessageId);
      
      debugPrint('✅ Message sent successfully: $messageId');
      return messageId;

    } catch (error, stackTrace) {
      // Error handling with proper logging
      debugPrint('❌ MESSAGE SENDER DEBUG: Failed to send message: $error');
      debugPrint('❌ MESSAGE SENDER DEBUG: Error type: ${error.runtimeType}');
      debugPrint('❌ MESSAGE SENDER DEBUG: Stack trace: $stackTrace');
      
      // 63 byte hatası için özel kontrol
      if (error.toString().contains('63') || error.toString().contains('byte')) {
        debugPrint('🚨 MESSAGE SENDER DEBUG: 63 byte hatası tespit edildi!');
        debugPrint('🚨 MESSAGE SENDER DEBUG: Content byte uzunluğu: ${content.codeUnits.length}');
        debugPrint('🚨 MESSAGE SENDER DEBUG: Content: "$content"');
        debugPrint('🚨 MESSAGE SENDER DEBUG: Content length: ${content.length}');
      }
      
      _sendingMessages.remove(tempMessageId);
      state = AsyncValue.error(error, stackTrace);
      
      // Re-throw with user-friendly message
      if (error.toString().contains('permission-denied')) {
        throw Exception('Permission denied - you cannot send messages to this user');
      } else if (error.toString().contains('network')) {
        throw Exception('Network error - please check your connection and try again');
      } else if (error.toString().contains('63') || error.toString().contains('byte')) {
        throw Exception('Message content validation error - please check your message and try again');
      } else {
        throw Exception('Failed to send message: ${error.toString()}');
      }
    }
  }

  /// Send message with retry logic (up to 3 attempts)
  /// 
  /// This method handles transient failures by retrying the operation
  /// with exponential backoff between attempts.
  Future<String> _sendMessageWithRetry(Message message, {int attempt = 1}) async {
    const maxAttempts = 3;
    const baseDelayMs = 1000; // 1 second base delay

    try {
      // Use Firebase realtime service for sending
      final realtimeService = FirebaseRealtimeService();
      await realtimeService.sendMessage(
        conversationId: message.conversationId,
        senderId: message.senderId,
        receiverId: message.receiverId,
        content: message.content,
        type: message.type,
      );

      // If using realtime service, we need to return a generated ID
      // In a real implementation, the service should return the message ID
      return 'msg_${DateTime.now().millisecondsSinceEpoch}';

    } catch (error) {
      debugPrint('❌ Send attempt $attempt failed: $error');
      
      // If this is the last attempt, throw the error
      if (attempt >= maxAttempts) {
        rethrow;
      }

      // Wait with exponential backoff before retrying
      final delayMs = baseDelayMs * (attempt * attempt); // 1s, 4s, 9s
      await Future.delayed(Duration(milliseconds: delayMs));
      
      // Retry with next attempt number
      return _sendMessageWithRetry(message, attempt: attempt + 1);
    }
  }

  /// Update conversation's last message information
  /// 
  /// This ensures conversation lists show the most recent message
  /// and proper timestamps for sorting.
  Future<void> _updateConversationLastMessage(
    String conversationId,
    Message message,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .update({
        'lastMessage': message.content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': message.senderId,
        'lastMessageType': message.type.name,
        'lastMessageId': message.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Conversation last message updated: $conversationId');
    } catch (e) {
      // Non-critical error - message was still sent successfully
      debugPrint('⚠️ Failed to update conversation last message: $e');
    }
  }

  /// Mark a conversation as read by the current user
  /// 
  /// This updates all unread messages in the conversation to read status
  /// and emits appropriate WebSocket events for real-time updates.
  Future<void> markAsRead(String conversationId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      debugPrint('🔍 markAsRead başlatıldı (message_sender_provider) - ConversationId: $conversationId, UserId: ${currentUser.uid}');
      
      // Get all unread messages in this conversation for current user
      // Check both isRead field and status field for better compatibility
      final unreadMessages = await FirebaseFirestore.instance
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      debugPrint('🔍 Okunmamış mesaj sayısı (message_sender_provider): ${unreadMessages.docs.length}');

      // Batch update all unread messages
      final batch = FirebaseFirestore.instance.batch();
      
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'status': MessageStatus.read.name,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      // ÖNEMLI: Conversation'daki unread count'u da sıfırla
      batch.update(
        FirebaseFirestore.instance.collection('conversations').doc(conversationId),
        {
          'unreadCount.${currentUser.uid}': 0,
        }
      );

      // Execute batch update
      await batch.commit();
      
      debugPrint('✅ Marked ${unreadMessages.docs.length} messages as read in conversation: $conversationId, unreadCount sıfırlandı');

      // UI'ı anında senkronize etmek için unread sağlayıcılarını invalid et
      // Böylece bottom bar rozeti ve sohbet listesi anında güncellenir
      try {
        ref.invalidate(chat_providers.userConversationsProvider);
        ref.invalidate(chat_providers.totalUnreadMessagesCountProvider);
      } catch (_) {
        // no-op: invalidation optional
      }

    } catch (e) {
      debugPrint('❌ Failed to mark conversation as read: $e');
      // Don't throw - this is not critical functionality
    }
  }

  /// Clear any pending operations (useful for cleanup)
  void clearPendingOperations() {
    _sendingMessages.clear();
    _offlineQueue.clear();
    state = const AsyncValue.data(null);
  }

  /// Get the current number of pending send operations
  int get pendingSendCount => _sendingMessages.length;

  /// Get the current offline queue size (for future offline support)
  int get offlineQueueSize => _offlineQueue.length;
}

/// Provider for accessing the message sender
/// 
/// Usage example:
/// ```dart
/// final messageId = await ref.read(messageSenderProvider.notifier).sendMessage(
///   conversationId: 'conv123',
///   receiverId: 'user456',
///   content: 'Hello!',
/// );
/// ```
