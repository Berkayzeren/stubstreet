// lib/features/conversations/domain/entities/message.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, file, system, offer, reminder }

enum MessageStatus { sent, delivered, read, failed }

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final MessageType type;
  final MessageStatus status;
  final String content;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? readAt;
  final bool isEdited;
  final bool isDeleted;
  final String? replyToMessageId;
  final Map<String, dynamic>? metadata;
  final Map<String, List<String>> reactions; // emoji -> list of user IDs who reacted

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.type,
    required this.status,
    required this.content,
    required this.attachments,
    required this.createdAt,
    this.updatedAt,
    this.readAt,
    this.isEdited = false,
    this.isDeleted = false,
    this.replyToMessageId,
    this.metadata,
    this.reactions = const {},
  });

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? receiverId,
    String? receiverName,
    MessageType? type,
    MessageStatus? status,
    String? content,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? readAt,
    bool? isEdited,
    bool? isDeleted,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
    Map<String, List<String>>? reactions,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      type: type ?? this.type,
      status: status ?? this.status,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      readAt: readAt ?? this.readAt,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      metadata: metadata ?? this.metadata,
      reactions: reactions ?? this.reactions,
    );
  }

  bool get isRead => readAt != null;
  bool get hasAttachments => attachments.isNotEmpty;
  bool get isReply => replyToMessageId != null;

  // Convert to Firestore document
  /// 
  /// This method ensures compatibility with both frontend and backend expectations
  /// by including all necessary fields with proper naming conventions.
  Map<String, dynamic> toFirestore() {
    return {
      // Core message fields
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'type': type.name,
      'status': status.name,
      'content': content,
      'attachments': attachments,
      
      // Timestamp fields - using both formats for compatibility
      'createdAt': Timestamp.fromDate(createdAt),
      'timestamp': Timestamp.fromDate(createdAt), // Backend compatibility
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      
      // Status and meta fields
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'isRead': readAt != null, // Backend compatibility
      'replyToMessageId': replyToMessageId,
      'metadata': metadata,
      
      // Advanced features
      'reactions': reactions.map((emoji, userIds) => 
        MapEntry(emoji, userIds)), // Convert reactions to proper format
      
      // Read tracking for multiple participants
      'readBy': readAt != null ? [senderId] : [senderId], // Mark sender as having read their own message
    };
  }

  // Create from Firestore document
  /// 
  /// This factory method handles both new and legacy data formats
  /// to ensure compatibility across different versions of the app.
  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle timestamp field compatibility (backend uses 'timestamp', frontend uses 'createdAt')
    DateTime createdAt;
    if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
      createdAt = (data['timestamp'] as Timestamp).toDate();
    } else {
      createdAt = DateTime.now(); // Fallback for malformed data
    }
    
    // Handle read status compatibility
    DateTime? readAt;
    if (data['readAt'] != null && data['readAt'] is Timestamp) {
      readAt = (data['readAt'] as Timestamp).toDate();
    } else if (data['isRead'] == true && data['createdAt'] != null && data['createdAt'] is Timestamp) {
      // Legacy compatibility - if marked as read but no readAt timestamp
      readAt = (data['createdAt'] as Timestamp).toDate();
    }
    
    // Parse reactions with error handling
    Map<String, List<String>> reactions = {};
    if (data['reactions'] != null && data['reactions'] is Map) {
      try {
        final reactionsData = data['reactions'] as Map<String, dynamic>;
        reactions = reactionsData.map((emoji, userIds) {
          if (userIds is List) {
            return MapEntry(emoji, List<String>.from(userIds));
          }
          return MapEntry(emoji, <String>[]);
        });
      } catch (e) {
        // Ignore malformed reactions data
        reactions = {};
      }
    }
    
    return Message(
      id: doc.id,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown User',
      receiverId: data['receiverId'] ?? '',
      receiverName: data['receiverName'] ?? 'Unknown User',
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => MessageStatus.sent,
      ),
      content: data['content'] ?? '',
      attachments: List<String>.from(data['attachments'] ?? []),
      createdAt: createdAt,
      updatedAt: data['updatedAt'] != null && data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      readAt: readAt,
      isEdited: data['isEdited'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      replyToMessageId: data['replyToMessageId'],
      metadata: data['metadata'] is Map<String, dynamic> 
          ? data['metadata'] 
          : null,
      reactions: reactions,
    );
  }
}

extension MessageTypeExtension on MessageType {
  String get displayName {
    switch (this) {
      case MessageType.text:
        return 'Metin';
      case MessageType.image:
        return 'Resim';
      case MessageType.file:
        return 'Dosya';
      case MessageType.system:
        return 'Sistem';
      case MessageType.offer:
        return 'Teklif';
      case MessageType.reminder:
        return 'Hatırlatma';
    }
  }

  String get icon {
    switch (this) {
      case MessageType.text:
        return '💬';
      case MessageType.image:
        return '🖼️';
      case MessageType.file:
        return '📎';
      case MessageType.system:
        return '⚙️';
      case MessageType.offer:
        return '💰';
      case MessageType.reminder:
        return '⏰';
    }
  }
}

extension MessageStatusExtension on MessageStatus {
  String get displayName {
    switch (this) {
      case MessageStatus.sent:
        return 'Gönderildi';
      case MessageStatus.delivered:
        return 'Ulaştı';
      case MessageStatus.read:
        return 'Okundu';
      case MessageStatus.failed:
        return 'Başarısız';
    }
  }

  String get icon {
    switch (this) {
      case MessageStatus.sent:
        return '✓';
      case MessageStatus.delivered:
        return '✓✓';
      case MessageStatus.read:
        return '✓✓';
      case MessageStatus.failed:
        return '❌';
    }
  }
}
