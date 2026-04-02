import '../entities/conversation.dart';

abstract class ConversationRepository {
  // Remote operations
  Future<List<Conversation>> getUserConversations(String userId, {int limit = 50, int offset = 0});
  Future<Conversation> createConversation(Conversation conversation);
  Future<Conversation> updateConversation(Conversation conversation);
  Future<void> deleteConversation(String conversationId, String userId);
  Future<Conversation?> getConversation(String conversationId);
  Future<Conversation?> getConversationByTicket(String ticketId);
  
  // Local cache operations
  Future<void> cacheConversations(List<Conversation> conversations);
  Future<List<Conversation>> getCachedConversations(String userId);
  Future<void> clearCache();
  
  // Real-time operations
  Stream<List<Conversation>> getConversationsStream(String userId);
  Stream<Conversation> getConversationStream(String conversationId);
}
