// lib/features/conversations/presentation/providers/chat_moderation_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/chat_moderation_service.dart';

// Chat moderation service provider
final chatModerationServiceProvider = Provider<ChatModerationService>((ref) {
  return ChatModerationService();
});

// Report user provider
final reportUserProvider = StateNotifierProvider<ReportUserNotifier, AsyncValue<void>>((ref) {
  return ReportUserNotifier(ref);
});

class ReportUserNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  
  ReportUserNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> reportUser({
    required String reportedUserId,
    required String reason,
    String? details,
    String? messageId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(chatModerationServiceProvider).reportUser(
        reportedUserId: reportedUserId,
        reason: reason,
        details: details,
        messageId: messageId,
      );
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// Block user provider
final blockUserProvider = StateNotifierProvider<BlockUserNotifier, AsyncValue<void>>((ref) {
  return BlockUserNotifier(ref);
});

class BlockUserNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  
  BlockUserNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> blockUser(String blockedUserId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(chatModerationServiceProvider).blockUser(blockedUserId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> unblockUser(String blockedUserId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(chatModerationServiceProvider).unblockUser(blockedUserId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// Check if user is blocked provider
final isUserBlockedProvider = FutureProvider.family<bool, String>((ref, userId) async {
  return await ref.read(chatModerationServiceProvider).isUserBlocked(userId);
});

// Check if current user is blocked by another user provider
final isBlockedByUserProvider = FutureProvider.family<bool, String>((ref, userId) async {
  return await ref.read(chatModerationServiceProvider).isBlockedByUser(userId);
});

// Get blocked users list provider
final blockedUsersProvider = FutureProvider<List<String>>((ref) async {
  return await ref.read(chatModerationServiceProvider).getBlockedUsers();
});

// Clear chat history provider
final clearChatHistoryProvider = StateNotifierProvider<ClearChatHistoryNotifier, AsyncValue<void>>((ref) {
  return ClearChatHistoryNotifier(ref);
});

class ClearChatHistoryNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  
  ClearChatHistoryNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> clearChat(String otherUserId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(chatModerationServiceProvider).clearChatHistory(otherUserId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
