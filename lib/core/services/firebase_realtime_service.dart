// lib/core/services/firebase_realtime_service.dart
// Firebase-only real-time service for messages and orders
// This service replaces Socket.IO with Firebase's native real-time capabilities

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import '../../features/conversations/domain/entities/message.dart' as msg;
import '../../features/orders/domain/entities/order.dart' as order_entity;
import '../../features/conversations/domain/entities/message.dart' show MessageType;
import '../../features/orders/domain/entities/order.dart' show OrderStatus;
import '../utils/message_filter.dart';

/// Firebase-only real-time service for handling messages and orders
/// This service uses Firebase's native real-time listeners instead of Socket.IO
class FirebaseRealtimeService {
  static final FirebaseRealtimeService _instance = FirebaseRealtimeService._internal();
  factory FirebaseRealtimeService() => _instance;
  FirebaseRealtimeService._internal();

  FirebaseMessaging? _messaging;
  FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;
  bool _isInitialized = false;

  // Stream controllers for real-time data
  final StreamController<msg.Message> _messageController = StreamController<msg.Message>.broadcast();
  final StreamController<order_entity.Order> _orderUpdateController = StreamController<order_entity.Order>.broadcast();
  final StreamController<Map<String, bool>> _typingController = StreamController<Map<String, bool>>.broadcast();

  // Active listeners to manage subscriptions
  final Map<String, StreamSubscription> _messageListeners = {};
  final Map<String, StreamSubscription> _orderListeners = {};
  final Map<String, StreamSubscription> _typingListeners = {};

  // Streams for external consumption
  Stream<msg.Message> get messageStream => _messageController.stream;
  Stream<order_entity.Order> get orderUpdateStream => _orderUpdateController.stream;
  Stream<Map<String, bool>> get typingStream => _typingController.stream;

  /// Initialize the Firebase real-time service
  /// Sets up Firebase Messaging and local notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initFirebaseMessaging();
      await _initLocalNotifications();
      _isInitialized = true;
      // Firebase Realtime Service initialized successfully
    } catch (e) {
      // Failed to initialize Firebase Realtime Service: $e
      rethrow;
    }
  }

  /// Initialize Firebase Messaging for push notifications
  Future<void> _initFirebaseMessaging() async {
    _messaging = FirebaseMessaging.instance;
    
    // Request permission for notifications
    final settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Firebase Messaging permission granted');
    } else {
      debugPrint('❌ Firebase Messaging permission denied');
    }

    // Configure foreground message handling
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Configure background message handling
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  /// Initialize local notifications
  Future<void> _initLocalNotifications() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin!.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Handle foreground messages (when app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📱 Received foreground message: ${message.messageId}');
    
    // Parse message data and add to stream
    if (message.data.containsKey('messageId')) {
      await _fetchAndEmitMessage(message.data['messageId']);
    }
    
    // Show local notification
    await _showLocalNotification(message);
  }

  /// Handle background messages (when app is closed)
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('📱 Received background message: ${message.messageId}');
    // Background message handling is limited - just log for now
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    // TODO: Navigate to specific conversation or order
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (_flutterLocalNotificationsPlugin == null) return;

    const androidDetails = AndroidNotificationDetails(
      'messages',
      'Messages',
      channelDescription: 'New message notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin!.show(
      message.hashCode,
      message.notification?.title ?? 'New Message',
      message.notification?.body ?? 'You have a new message',
      details,
      payload: message.data.toString(),
    );
  }

  /// Fetch and emit a specific message
  Future<void> _fetchAndEmitMessage(String messageId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('messages')
          .doc(messageId)
          .get();
      
      if (doc.exists) {
        final message = msg.Message.fromFirestore(doc);
        _messageController.add(message);
      }
    } catch (e) {
      debugPrint('❌ Error fetching message $messageId: $e');
    }
  }

  /// Start listening to messages in a conversation
  /// This replaces Socket.IO's room joining functionality
  Future<void> joinConversation(String conversationId, String userId) async {
    debugPrint('🔗 Joining conversation: $conversationId');
    
    // Cancel existing listener if any
    _messageListeners[conversationId]?.cancel();
    
    // Start listening to messages in this conversation
    _messageListeners[conversationId] = FirebaseFirestore.instance
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen(
          (snapshot) {
            for (final change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                final message = msg.Message.fromFirestore(change.doc);
                _messageController.add(message);
                debugPrint('📨 New message received: ${message.content}');
              }
            }
          },
          onError: (error) {
            debugPrint('❌ Error listening to messages: $error');
          },
        );

    // Start listening to typing indicators
    _startTypingListener(conversationId, userId);
  }

  /// Start listening to typing indicators
  void _startTypingListener(String conversationId, String userId) {
    _typingListeners[conversationId]?.cancel();
    
    _typingListeners[conversationId] = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('typing')
        .snapshots()
        .listen(
          (snapshot) {
            final typingMap = <String, bool>{};
            for (final doc in snapshot.docs) {
              final data = doc.data();
              final isTyping = data['isTyping'] as bool? ?? false;
              final typingUserId = data['userId'] as String? ?? '';
              if (typingUserId != userId) { // Don't show our own typing
                typingMap['$conversationId:$typingUserId'] = isTyping;
              }
            }
            _typingController.add(typingMap);
          },
          onError: (error) {
            debugPrint('❌ Error listening to typing indicators: $error');
          },
        );
  }

  /// Leave a conversation (stop listening)
  Future<void> leaveConversation(String conversationId) async {
    debugPrint('🔗 Leaving conversation: $conversationId');
    
    _messageListeners[conversationId]?.cancel();
    _messageListeners.remove(conversationId);
    
    _typingListeners[conversationId]?.cancel();
    _typingListeners.remove(conversationId);
  }

  /// Send a message using Firebase
  /// This replaces Socket.IO's emit functionality
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    try {
      // Hassas bilgi filtresi kontrolü
      final filterResult = MessageFilter.filterMessage(content);
      if (!filterResult.isAllowed) {
        throw Exception('Güvenlik nedeniyle mesaj gönderilemedi: ${filterResult.violationMessage}');
      }

      // Debug: Mesaj verilerini detaylı logla
      debugPrint('🔍 FIREBASE DEBUG: Mesaj gönderiliyor...');
      debugPrint('🔍 FIREBASE DEBUG: Content uzunluğu: ${content.length} karakter');
      debugPrint('🔍 FIREBASE DEBUG: Content byte uzunluğu: ${content.codeUnits.length} byte');
      debugPrint('🔍 FIREBASE DEBUG: Content: "$content"');
      debugPrint('🔍 FIREBASE DEBUG: Conversation ID: $conversationId');
      debugPrint('🔍 FIREBASE DEBUG: Sender ID: $senderId');
      debugPrint('🔍 FIREBASE DEBUG: Receiver ID: $receiverId');

      final messageData = {
        'conversationId': conversationId,
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        'type': type.name,
        'status': 'sent',
        'attachments': [],
        'reactions': {},
        'readBy': [senderId], // Mark as read by sender
        'createdAt': FieldValue.serverTimestamp(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Add message to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('messages')
          .add(messageData);

      debugPrint('✅ FIREBASE DEBUG: Message sent to Firebase: $content (ID: ${docRef.id})');

      // Update conversation's last message info
      await _updateConversationLastMessage(conversationId, content, senderId);

    } catch (e) {
      debugPrint('❌ FIREBASE DEBUG: Failed to send message: $e');
      debugPrint('❌ FIREBASE DEBUG: Error type: ${e.runtimeType}');
      debugPrint('❌ FIREBASE DEBUG: Error details: ${e.toString()}');
      
      // 63 byte hatası için özel kontrol
      if (e.toString().contains('63') || e.toString().contains('byte')) {
        debugPrint('🚨 FIREBASE DEBUG: 63 byte hatası tespit edildi!');
        debugPrint('🚨 FIREBASE DEBUG: Content byte uzunluğu: ${content.codeUnits.length}');
        debugPrint('🚨 FIREBASE DEBUG: Content: "$content"');
      }
      
      rethrow;
    }
  }

  /// Update conversation's last message info
  Future<void> _updateConversationLastMessage(
    String conversationId,
    String content,
    String senderId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .update({
        'lastMessage': content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Failed to update conversation last message: $e');
    }
  }

  /// Send typing indicator
  Future<void> sendTypingIndicator({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('typing')
          .doc(userId)
          .set({
        'userId': userId,
        'isTyping': isTyping,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Auto-clear typing indicator after 3 seconds
      if (isTyping) {
        Timer(const Duration(seconds: 3), () {
          sendTypingIndicator(
            conversationId: conversationId,
            userId: userId,
            isTyping: false,
          );
        });
      }
    } catch (e) {
      debugPrint('❌ Failed to send typing indicator: $e');
    }
  }

  /// Update order status using Firebase
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final updateData = {
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
        ...?additionalData,
      };

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update(updateData);

      debugPrint('✅ Order status updated: $orderId -> ${status.name}');
    } catch (e) {
      debugPrint('❌ Failed to update order status: $e');
      rethrow;
    }
  }

  /// Start listening to order updates
  Future<void> listenToOrderUpdates(String orderId) async {
    _orderListeners[orderId]?.cancel();
    
    _orderListeners[orderId] = FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              final order = order_entity.Order.fromFirestore(snapshot);
              _orderUpdateController.add(order);
              // Order update received: ${order.status}
            }
          },
          onError: (error) {
            // Error listening to order updates: $error
          },
        );
  }

  /// Stop listening to order updates
  Future<void> stopListeningToOrderUpdates(String orderId) async {
    _orderListeners[orderId]?.cancel();
    _orderListeners.remove(orderId);
  }

  /// Clean up all resources
  Future<void> dispose() async {
    // Cancel all listeners
    for (final listener in _messageListeners.values) {
      await listener.cancel();
    }
    for (final listener in _orderListeners.values) {
      await listener.cancel();
    }
    for (final listener in _typingListeners.values) {
      await listener.cancel();
    }

    // Clear maps
    _messageListeners.clear();
    _orderListeners.clear();
    _typingListeners.clear();

    // Close stream controllers
    await _messageController.close();
    await _orderUpdateController.close();
    await _typingController.close();

    // Firebase Realtime Service disposed
  }
}
