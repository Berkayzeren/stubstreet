import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/services/firebase_chat_service.dart';
import '../../../../core/services/app_lifecycle_manager.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

part 'firebase_chat_providers.g.dart';

/// Firebase Chat Service Provider
/// 
/// Bu provider, uygulamanın her yerinde kullanılabilecek
/// Firebase chat servis instance'ını sağlar.
@Riverpod(keepAlive: true)
FirebaseChatService firebaseChatService(Ref ref) {
  final service = FirebaseChatService();
  
  // Provider dispose edildiğinde servisi temizle
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
}

/// Auth durumu değişikliklerini handle eden provider
/// Bu provider kullanıcının online/offline durumunu yönetir
@riverpod
class AuthStatusHandler extends _$AuthStatusHandler {
  @override
  void build() {
    // Auth state'i watch et ve değişiklikleri handle et
    final authState = ref.watch(authStateChangesProvider);
    
    authState.whenData((user) {
      if (user != null) {
        // Kullanıcı giriş yaptı - AppLifecycleManager'ı başlat
        final lifecycleManager = ref.read(appLifecycleManagerProvider);
        lifecycleManager.initialize();
      } else {
        // Kullanıcı çıkış yaptı - offline duruma geç
        final chatService = ref.read(firebaseChatServiceProvider);
        chatService.setUserOffline();
      }
    });
  }
}

/// Kullanıcının tüm sohbetlerini dinleyen provider
/// 
/// Bu provider, ana sohbet listesi ekranında kullanılır
/// ve gerçek zamanlı olarak sohbetleri günceller.
final userConversationsProvider = StreamProvider.autoDispose<List<Conversation>>((ref) {
  final chatService = ref.watch(firebaseChatServiceProvider);
  return chatService.getConversationsStream();
});

/// Belirli bir sohbetteki mesajları dinleyen provider
/// 
/// @param conversationId - Dinlenecek sohbetin ID'si
/// @returns `Stream<List<Message>>` - Mesajların gerçek zamanlı stream'i
final conversationMessagesProvider = StreamProvider.autoDispose.family<List<Message>, String>((ref, conversationId) {
  final chatService = ref.watch(firebaseChatServiceProvider);
  return chatService.getMessagesStream(conversationId);
});

/// Kullanıcı durumunu dinleyen provider
/// 
/// @param userId - Durumu takip edilecek kullanıcının ID'si
/// @returns `Stream<Map<String, dynamic>?>` - Kullanıcı durumu bilgileri
final userPresenceProvider = StreamProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, userId) {
  final chatService = ref.watch(firebaseChatServiceProvider);
  return chatService.getUserPresence(userId);
});

/// Mesaj gönderme işlemlerini yöneten provider
/// 
/// Bu provider, mesaj gönderme işlemlerinin durumunu tutar
/// ve hata yönetimi sağlar.
@riverpod
class MessageSender extends _$MessageSender {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  /// Mesaj gönder
  /// 
  /// @param receiverId - Alıcının ID'si
  /// @param content - Mesaj içeriği
  /// @param type - Mesaj tipi (varsayılan: text)
  Future<void> sendMessage({
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    if (content.trim().isEmpty) return;

    state = const AsyncValue.loading();
    
    try {
      final chatService = ref.read(firebaseChatServiceProvider);
      
      // Sohbet oluştur veya mevcut olanı getir
      final conversationId = await chatService.createOrGetConversation(receiverId);
      
      // Mesajı gönder
      await chatService.sendMessage(
        conversationId: conversationId,
        receiverId: receiverId,
        content: content.trim(),
        type: type,
      );
      
      state = const AsyncValue.data(null);
      // print('✅ Mesaj başarıyla gönderildi');
      
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      // print('❌ Mesaj gönderme hatası: $error');
      rethrow;
    }
  }

  /// Sohbetteki mesajları okundu olarak işaretle
  /// 
  /// @param conversationId - Sohbet ID'si
  Future<void> markAsRead(String conversationId) async {
    try {
      final chatService = ref.read(firebaseChatServiceProvider);
      await chatService.markMessagesAsRead(conversationId);
      // print('✅ Mesajlar okundu olarak işaretlendi');
    } catch (error) {
      // print('❌ Mesajları okundu işaretleme hatası: $error');
    }
  }
}

/// Yeni sohbet başlatma işlemlerini yöneten provider
/// 
/// Bu provider, yeni sohbet oluşturma işlemlerinin durumunu tutar.
@riverpod
class ConversationStarter extends _$ConversationStarter {
  @override
  AsyncValue<String?> build() {
    return const AsyncValue.data(null);
  }

  /// Yeni sohbet başlat
  /// 
  /// @param otherUserId - Karşı taraftaki kullanıcının ID'si
  /// @returns String - Oluşturulan conversation ID
  Future<String> startConversation(String otherUserId) async {
    state = const AsyncValue.loading();
    
    try {
      final chatService = ref.read(firebaseChatServiceProvider);
      final conversationId = await chatService.createOrGetConversation(otherUserId);
      
      state = AsyncValue.data(conversationId);
      // print('✅ Sohbet başlatıldı: $conversationId');
      
      return conversationId;
      
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      // print('❌ Sohbet başlatma hatası: $error');
      rethrow;
    }
  }
}

/// Online kullanıcıları sayan yardımcı provider
/// 
/// Bu provider, UI'da kaç kullanıcının online olduğunu göstermek için kullanılabilir.
@riverpod
class OnlineUsersCounter extends _$OnlineUsersCounter {
  @override
  int build() {
    return 0;
  }

  void updateCount(int count) {
    state = count;
  }
}

/// Kullanıcının tüm sohbetlerindeki toplam okunmamış mesaj sayısını hesaplayan provider
/// 
/// Bu provider, bottom navigation bar'da mesaj tab'ının yanında badge göstermek için kullanılır.
@riverpod
int totalUnreadMessagesCount(Ref ref) {
  final AsyncValue<List<Conversation>> conversationsAsync = ref.watch(userConversationsProvider);
  
  return conversationsAsync.when(
    data: (conversations) {
      // Mevcut kullanıcıyı al
      final authState = ref.watch(authStateChangesProvider);
      final currentUserId = authState.value?.uid;
      
      if (currentUserId == null) return 0;
      
      // Tüm konuşmalardaki okunmamış mesaj sayılarını topla
      int totalUnread = 0;
      for (final conversation in conversations) {
        final unreadCount = conversation.unreadCount[currentUserId];
        if (unreadCount != null) {
          totalUnread += (unreadCount as num).toInt();
        }
      }
      
      return totalUnread;
    },
    loading: () => 0, // Loading sırasında 0 döndür
    error: (error, stack) => 0, // Hata durumunda 0 döndür
  );
}