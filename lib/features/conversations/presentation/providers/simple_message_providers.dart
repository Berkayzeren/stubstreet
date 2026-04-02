// lib/features/conversations/presentation/providers/simple_message_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/conversation.dart';

part 'simple_message_providers.g.dart';

/// Basit mesaj provider'ı - Sadece Firebase Firestore kullanır
/// Websocket olmadan, direkt real-time stream'ler
@riverpod
Stream<List<Message>> simpleConversationMessages(
  ref,
  String conversationId,
) {
  return FirebaseFirestore.instance
      .collection('messages')
      .where('conversationId', isEqualTo: conversationId)
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Message.fromFirestore(doc))
          .toList());
}

/// Basit mesaj gönderme provider'ı
@riverpod
class SimpleMessageSender extends _$SimpleMessageSender {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    state = const AsyncValue.loading();

    try {
      final message = Message(
        id: '', // Firebase otomatik ID verecek
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        receiverName: receiverName,
        type: type,
        status: MessageStatus.sent,
        content: content,
        attachments: [],
        createdAt: DateTime.now(),
      );

      // Firebase'e mesajı ekle (isRead: false olarak ekle)
      final messageData = message.toFirestore();
      messageData['isRead'] = false; // Ensure message is marked as unread initially
      
      final docRef = await FirebaseFirestore.instance
          .collection('messages')
          .add(messageData);

      // Conversation'ı güncelle ve receiver'ın unread count'unu artır
      await _updateConversationLastMessage(
        conversationId,
        message.copyWith(id: docRef.id),
        receiverId,
      );

      // print('✅ Message sent to Firestore: $content');
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      // print('❌ Error sending message: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> _updateConversationLastMessage(
    String conversationId,
    Message message,
    String receiverId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .update({
        'lastMessageId': message.id,
        'lastMessageContent': message.content,
        'lastMessageAt': Timestamp.fromDate(message.createdAt),
        'lastMessageSenderId': message.senderId,
        'updatedAt': Timestamp.now(),
        // Increase unread count for the receiver
        'unreadCount.$receiverId': FieldValue.increment(1),
      });
    } catch (e) {
      // print('⚠️ Failed to update conversation: $e');
      // Non-critical error - message was still sent
    }
  }
}

/// Kullanıcının konuşmalarını getir
@riverpod
Stream<List<Conversation>> simpleUserConversations(
  ref,
  String userId,
) {
  return FirebaseFirestore.instance
      .collection('conversations')
      .where('participants', arrayContains: userId)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Conversation.fromFirestore(doc))
          .where((conv) => !conv.isDeletedBy(userId))
          .toList());
}
