// lib/core/services/push_notification_handler.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../features/conversations/presentation/screens/chat_screen.dart';

class PushNotificationHandler {
  static final PushNotificationHandler _instance =
      PushNotificationHandler._internal();
  factory PushNotificationHandler() => _instance;
  PushNotificationHandler._internal();

  FlutterLocalNotificationsPlugin? _localNotifications;
  FirebaseMessaging? _firebaseMessaging;
  BuildContext? _currentContext;

  // Navigation context for deep linking
  void setNavigationContext(BuildContext context) {
    _currentContext = context;
  }

  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _initializeFirebaseMessaging();
    _setupMessageHandlers();
  }

  Future<void> _initializeLocalNotifications() async {
    _localNotifications = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications!.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    if (_localNotifications == null) return;

    // Messages channel
    const messagesChannel = AndroidNotificationChannel(
      'messages',
      'Messages',
      description: 'Notifications for new messages',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('message_sound'),
    );

    // Orders channel
    const ordersChannel = AndroidNotificationChannel(
      'orders',
      'Orders',
      description: 'Notifications for order updates',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('order_sound'),
    );

    await _localNotifications!
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(messagesChannel);

    await _localNotifications!
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(ordersChannel);
  }

  Future<void> _initializeFirebaseMessaging() async {
    _firebaseMessaging = FirebaseMessaging.instance;

    // Request permission
    await _firebaseMessaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    // Get FCM token
    final token = await _firebaseMessaging!.getToken();
    debugPrint('📱 FCM Token: $token');

    // Token'ı backend'e göndermenin yanında Firestore'a kullanıcı alt koleksiyonuna da kaydedelim
    // Neden: Çoklu cihaz desteği ve token yönetimi için her cihaz token'ı ayrı belge olarak tutulur.
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && token != null) {
        final tokenDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('fcmTokens')
            .doc(token);
        await tokenDoc.set({
          'createdAt': FieldValue.serverTimestamp(),
          'platform': defaultTargetPlatform.toString(),
          'appVersion': null,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('❌ Failed to persist FCM token in Firestore: $e');
    }

    // Ayrıca API'ye de iletmeye devam edelim (istenirse)
    await _sendTokenToServer(token);
  }

  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Check for initial message when app is launched from notification
    _checkForInitialMessage();
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint(
      '📱 Received foreground message: ${message.notification?.title}',
    );

    // Show local notification for foreground messages
    await _showLocalNotification(message);

    // Update badge count
    await _updateBadgeCount(message);
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('📱 Message opened app: ${message.data}');
    await _navigateFromNotification(message.data);
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    debugPrint('📱 Background message: ${message.messageId}');
    // Handle background processing if needed
  }

  Future<void> _checkForInitialMessage() async {
    final initialMessage = await _firebaseMessaging?.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('📱 Initial message: ${initialMessage.data}');
      // Delay navigation to ensure app is fully loaded
      await Future.delayed(const Duration(seconds: 1));
      await _navigateFromNotification(initialMessage.data);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (_localNotifications == null) return;

    final notification = message.notification;
    final data = message.data;

    if (notification == null) return;

    final notificationType = data['type'] ?? 'general';
    final channelId = _getChannelId(notificationType);

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final androidDetailsWithChannel = AndroidNotificationDetails(
      channelId,
      _getChannelName(notificationType),
      channelDescription: 'Default notification channel',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: const BigTextStyleInformation(''),
    );

    final details = NotificationDetails(
      android: androidDetailsWithChannel,
      iOS: iosDetails,
    );

    await _localNotifications!.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: _createPayload(data),
    );
  }

  Future<void> _updateBadgeCount(RemoteMessage message) async {
    // Update app icon badge count
    final badgeCount = int.tryParse(message.data['badge'] ?? '0') ?? 0;
    if (badgeCount > 0) {
      await _localNotifications
          ?.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(badge: true);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      final data = _parsePayload(payload);
      _navigateFromNotification(data);
    }
  }

  Future<void> _navigateFromNotification(Map<String, dynamic> data) async {
    if (_currentContext == null) {
      debugPrint('⚠️ No navigation context available for deep linking');
      return;
    }

    final type = data['type'] as String?;
    final id = data['id'] as String?;

    if (type == null || id == null) {
      debugPrint('⚠️ Invalid notification data for navigation');
      return;
    }

    try {
      switch (type) {
        case 'message':
          await _navigateToChat(data);
          break;
        case 'order':
          await _navigateToOrder(data);
          break;
        case 'conversation':
          await _navigateToConversation(data);
          break;
        default:
          debugPrint('⚠️ Unknown notification type: $type');
      }
    } catch (e) {
      debugPrint('❌ Error navigating from notification: $e');
    }
  }

  Future<void> _navigateToChat(Map<String, dynamic> data) async {
    final conversationId = data['conversationId'] as String?;
    final otherUserName = data['otherUserName'] as String? ?? 'User';
    final otherUserId = data['otherUserId'] as String? ?? 'unknown';
    final currentUserId = data['currentUserId'] as String?;

    if (conversationId == null || currentUserId == null) {
      debugPrint('⚠️ Missing required data for chat navigation');
      return;
    }

    if (_currentContext != null && _currentContext!.mounted) {
      await Navigator.of(_currentContext!).push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: conversationId,
            otherUserName: otherUserName,
            otherUserId: otherUserId,
            currentUserId: currentUserId,
          ),
        ),
      );
    }
  }

  Future<void> _navigateToOrder(Map<String, dynamic> data) async {
    final orderId = data['orderId'] as String?;

    if (orderId == null) {
      debugPrint('⚠️ Missing order ID for navigation');
      return;
    }

    // TODO: Implement order detail navigation
    // if (_currentContext != null && _currentContext!.mounted) {
    //   await Navigator.of(_currentContext!).push(
    //     MaterialPageRoute(
    //       builder: (context) => OrderDetailScreen(orderId: orderId),
    //     ),
    //   );
    // }

    debugPrint('🔗 Navigate to order: $orderId');
  }

  Future<void> _navigateToConversation(Map<String, dynamic> data) async {
    await _navigateToChat(data);
  }

  String _getChannelId(String type) {
    switch (type) {
      case 'message':
      case 'conversation':
        return 'messages';
      case 'order':
        return 'orders';
      default:
        return 'default';
    }
  }

  String _getChannelName(String type) {
    switch (type) {
      case 'message':
      case 'conversation':
        return 'Messages';
      case 'order':
        return 'Orders';
      default:
        return 'General';
    }
  }

  String _createPayload(Map<String, dynamic> data) {
    // Simple payload format: type|id|extra_data
    final type = data['type'] ?? 'general';
    final id = data['id'] ?? '';
    final extraData = data.entries
        .where((entry) => entry.key != 'type' && entry.key != 'id')
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');

    return '$type|$id|$extraData';
  }

  Map<String, dynamic> _parsePayload(String payload) {
    final parts = payload.split('|');
    final data = <String, dynamic>{};

    if (parts.isNotEmpty) data['type'] = parts[0];
    if (parts.length > 1) data['id'] = parts[1];
    if (parts.length > 2) {
      final extraParts = parts[2].split('&');
      for (final part in extraParts) {
        final keyValue = part.split('=');
        if (keyValue.length == 2) {
          data[keyValue[0]] = keyValue[1];
        }
      }
    }

    return data;
  }

  Future<void> _sendTokenToServer(String? token) async {
    if (token == null) return;

    try {
      debugPrint('📤 FCM token already saved to Firestore: $token');
      
      // Token zaten Firestore'da kaydedildi (yukarıda _initializeFirebaseMessaging'de)
      // İsteğe bağlı olarak backend API'ye de gönderilebilir:
      
      // final user = FirebaseAuth.instance.currentUser;
      // if (user != null) {
      //   await http.post(
      //     Uri.parse('https://your-backend-api.com/fcm-token'),
      //     headers: {'Content-Type': 'application/json'},
      //     body: json.encode({
      //       'token': token, 
      //       'userId': user.uid,
      //       'platform': defaultTargetPlatform.toString(),
      //     }),
      //   );
      // }
    } catch (e) {
      debugPrint('❌ Error sending FCM token to server: $e');
    }
  }

  // Badge management methods
  Future<void> clearBadge() async {
    await _localNotifications
        ?.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(badge: false);
  }

  Future<void> setBadgeCount(int count) async {
    // For iOS
    await _localNotifications
        ?.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(badge: count > 0);

    // For Android, you might need to use a plugin like flutter_app_badger
    // await FlutterAppBadger.updateBadgeCount(count);
  }

  // Notification permission status
  Future<bool> areNotificationsEnabled() async {
    if (_firebaseMessaging == null) return false;

    final settings = await _firebaseMessaging!.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  Future<void> requestNotificationPermissions() async {
    if (_firebaseMessaging == null) return;

    await _firebaseMessaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications?.cancelAll();
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications?.cancel(id);
  }
}

// Extension for easy notification data creation
extension NotificationDataHelper on Map<String, dynamic> {
  static Map<String, dynamic> createMessageData({
    required String conversationId,
    required String otherUserName,
    required String currentUserId,
    String? messageId,
  }) {
    return {
      'type': 'message',
      'id': messageId ?? conversationId,
      'conversationId': conversationId,
      'otherUserName': otherUserName,
      'currentUserId': currentUserId,
    };
  }

  static Map<String, dynamic> createOrderData({
    required String orderId,
    String? orderStatus,
  }) {
    return {
      'type': 'order',
      'id': orderId,
      'orderId': orderId,
      if (orderStatus != null) 'orderStatus': orderStatus,
    };
  }
}
