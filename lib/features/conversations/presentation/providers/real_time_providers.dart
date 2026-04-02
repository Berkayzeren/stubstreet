// lib/features/conversations/presentation/providers/real_time_providers.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firebase_realtime_service.dart';
import '../../domain/entities/message.dart' as msg;
import '../../../orders/domain/entities/order.dart' as order_entity;
import 'package:cloud_firestore/cloud_firestore.dart';

// Import enums
import '../../domain/entities/message.dart' show MessageType;
import '../../../orders/domain/entities/order.dart' show OrderStatus;

part 'real_time_providers.g.dart';

// Firebase real-time service singleton provider
@riverpod
FirebaseRealtimeService realTimeService(Ref ref) {
  return FirebaseRealtimeService();
}

// Connection status provider - Firebase is always connected
@riverpod
Stream<bool> connectionStatus(Ref ref) async* {
  final service = ref.watch(realTimeServiceProvider);

  // Initialize service if not already done
  await service.initialize();

  // Firebase is always connected when initialized
  yield true;
}

// Real-time messages stream for a specific conversation
@riverpod
Stream<List<msg.Message>> conversationMessages(
  Ref ref,
  String conversationId,
) async* {
  final service = ref.watch(realTimeServiceProvider);

  // Initialize service
  await service.initialize();

  // Listen to real-time message stream
  final messageStream = service.messageStream.where(
    (message) => message.conversationId == conversationId,
  );

  // Also get initial messages from Firestore
  List<msg.Message> messages = [];

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: false)
        .get();

    messages = snapshot.docs
        .map((doc) => msg.Message.fromFirestore(doc))
        .toList();
    yield messages;
  } catch (e) {
    debugPrint('Error loading initial messages: $e');
    yield messages;
  }

  // Listen for new messages
  await for (final newMessage in messageStream) {
    // Safely add new message to the list
    // Check if message already exists to avoid duplicates
    final existingIndex = messages.indexWhere((msg) => msg.id == newMessage.id);
    if (existingIndex == -1) {
      messages = [...messages, newMessage];
      // Sort messages by creation time to maintain chronological order
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      yield messages;
    }
  }
}

// Real-time order updates stream
@riverpod
Stream<order_entity.Order?> orderUpdates(
  Ref ref,
  String orderId,
) async* {
  final service = ref.watch(realTimeServiceProvider);

  await service.initialize();

  // Get initial order state
  try {
    final doc = await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .get();

    if (doc.exists) {
      yield order_entity.Order.fromFirestore(doc);
    }
  } catch (e) {
    debugPrint('Error loading initial order: $e');
  }

  // Listen for real-time updates
  await for (final updatedOrder in service.orderUpdateStream) {
    if (updatedOrder.id == orderId) {
      yield updatedOrder;
    }
  }
}

// DEPRECATED: Use firebase_chat_providers.userConversationsProvider instead
// This provider has been deprecated to avoid ID conflicts
// @deprecated
// Stream<List<Conversation>> userConversations(
//   Ref ref,
//   String userId,
// ) async* {
//   // This provider has been deprecated - use firebase_chat_providers.userConversationsProvider
//   yield [];
// }

// Typing indicator provider
@riverpod
class TypingIndicator extends _$TypingIndicator {
  Timer? _typingTimer;

  @override
  Map<String, bool> build() {
    return {};
  }

  void startTyping(String conversationId, String userId) {
    final service = ref.read(realTimeServiceProvider);
    service.sendTypingIndicator(
      conversationId: conversationId,
      userId: userId,
      isTyping: true,
    );

    // Update local state
    state = {...state, '$conversationId:$userId': true};

    // Stop typing after 3 seconds of inactivity
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      stopTyping(conversationId, userId);
    });
  }

  void stopTyping(String conversationId, String userId) {
    final service = ref.read(realTimeServiceProvider);
    service.sendTypingIndicator(
      conversationId: conversationId,
      userId: userId,
      isTyping: false,
    );

    // Update local state
    final newState = Map<String, bool>.from(state);
    newState.remove('$conversationId:$userId');
    state = newState;

    _typingTimer?.cancel();
  }

  bool isTyping(String conversationId, String userId) {
    return state['$conversationId:$userId'] == true;
  }
}

// Message sending provider
@riverpod
class MessageSender extends _$MessageSender {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(realTimeServiceProvider);
      await service.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        type: type,
      );

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Order status update provider
@riverpod
class OrderStatusUpdater extends _$OrderStatusUpdater {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
    Map<String, dynamic>? additionalData,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(realTimeServiceProvider);
      await service.updateOrderStatus(
        orderId: orderId,
        status: status,
        additionalData: additionalData,
      );

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Connection indicator widget provider
@riverpod
class ConnectionIndicator extends _$ConnectionIndicator {
  @override
  String build() {
    return 'Bağlantı kontrol ediliyor...';
  }

  void updateStatus(bool isConnected) {
    if (isConnected) {
      state = '🟢 Firebase bağlantısı aktif';
    } else {
      state = '🔴 Çevrimdışı';
    }
  }
}
