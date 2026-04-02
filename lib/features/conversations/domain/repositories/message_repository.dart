import '../entities/message.dart';

abstract class MessageRepository {
  // Remote operations
  Future<List<Message>> getMessages(String conversationId, {int limit = 20, int offset = 0});
  Future<Message> sendMessage(Message message);
  Future<Message> updateMessage(Message message);
  Future<void> deleteMessage(String messageId);
  Future<void> markAsRead(String messageId);
  Future<void> markConversationAsRead(String conversationId, String userId);
  
  // Local cache operations
  Future<void> cacheMessages(List<Message> messages);
  Future<List<Message>> getCachedMessages(String conversationId);
  Future<void> clearCache();
  
  // Real-time operations
  Stream<Message> getMessageStream(String conversationId);
  Stream<List<Message>> getMessagesStream(String conversationId);
}
