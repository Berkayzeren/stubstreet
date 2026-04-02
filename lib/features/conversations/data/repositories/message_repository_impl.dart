import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/message_repository.dart';
import '../../../../core/services/firebase_realtime_service.dart';

class MessageRepositoryImpl implements MessageRepository {
  final FirebaseFirestore _firestore;
  final FirebaseRealtimeService _realTimeService;
  final Connectivity _connectivity;

  MessageRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseRealtimeService realTimeService,
    required Connectivity connectivity,
  })  : _firestore = firestore,
        _realTimeService = realTimeService,
        _connectivity = connectivity;

  @override
  Future<List<Message>> getMessages(String conversationId, {int limit = 20, int offset = 0}) async {
    try {
      // Check connectivity first
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      if (!isOnline) {
        // Return empty list if offline (could implement local storage later)
        return [];
      }

      // Fetch from Firestore
      Query query = _firestore
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (offset > 0) {
        // For pagination, we would need to implement cursor-based pagination
        // This is a simplified version
        query = query.startAfter([DateTime.now().subtract(Duration(days: offset))]);
      }

      final snapshot = await query.get();
      final messages = snapshot.docs
          .map((doc) => Message.fromFirestore(doc))
          .toList()
          .reversed
          .toList(); // Reverse to get chronological order

      // Messages fetched successfully

      return messages;
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  @override
  Future<Message> sendMessage(Message message) async {
    try {
      // Add to Firestore
      final docRef = await _firestore.collection('messages').add(message.toFirestore());
      
      // Update conversation's last message
      await _updateConversationLastMessage(message);
      
      // Message sent successfully
      final savedMessage = message.copyWith(id: docRef.id);
      
      return savedMessage;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  @override
  Future<Message> updateMessage(Message message) async {
    try {
      await _firestore.collection('messages').doc(message.id).update(message.toFirestore());
      
      // Message updated successfully
      
      return message;
    } catch (e) {
      throw Exception('Failed to update message: $e');
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).delete();
      
      // Message deleted successfully
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  @override
  Future<void> markAsRead(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'status': MessageStatus.read.name,
        'readAt': Timestamp.now(),
      });
      
      // Message marked as read successfully
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  @override
  Future<void> markConversationAsRead(String conversationId, String userId) async {
    try {
      final batch = _firestore.batch();
      
      // Get unread messages for this user
      final unreadMessages = await _firestore
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .where('receiverId', isEqualTo: userId)
          .where('status', isNotEqualTo: MessageStatus.read.name)
          .get();
      
      // Mark all as read
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'status': MessageStatus.read.name,
          'readAt': Timestamp.now(),
        });
      }
      
      // Update conversation unread count
      final userField = userId.endsWith('buyer') ? 'unreadCountBuyer' : 'unreadCountSeller';
      batch.update(
        _firestore.collection('conversations').doc(conversationId),
        {userField: 0},
      );
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark conversation as read: $e');
    }
  }

  @override
  Future<void> cacheMessages(List<Message> messages) async {
    // Cache functionality removed - could implement with local storage later
  }

  @override
  Future<List<Message>> getCachedMessages(String conversationId) async {
    // Cache functionality removed - returning empty list
    return [];
  }

  @override
  Future<void> clearCache() async {
    // Cache functionality removed
  }

  @override
  Stream<Message> getMessageStream(String conversationId) {
    return _realTimeService.messageStream
        .where((message) => message.conversationId == conversationId);
  }

  @override
  Stream<List<Message>> getMessagesStream(String conversationId) async* {
    // Initialize with empty list (cache functionality removed)
    List<Message> messages = [];
    
    await for (final newMessage in getMessageStream(conversationId)) {
      // Add new message to the list
      messages.add(newMessage);
      
      // Sort messages by creation time
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      yield List.from(messages);
    }
  }

  Future<void> _updateConversationLastMessage(Message message) async {
    try {
      await _firestore.collection('conversations').doc(message.conversationId).update({
        'lastMessageId': message.id,
        'lastMessageContent': message.content,
        'lastMessageAt': Timestamp.fromDate(message.createdAt),
        'lastMessageSenderId': message.senderId,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      // Log error but don't throw - this is not critical for message sending
      // TODO: Use proper logging instead of print
      // print('Failed to update conversation last message: $e');
    }
  }
}
