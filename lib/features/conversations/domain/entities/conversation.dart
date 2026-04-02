// lib/features/conversations/domain/entities/conversation.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum ConversationType { ticketInquiry, general, support, dispute }

enum ConversationStatus { active, closed, archived }

class Conversation {
  final String id;
  final List<String> participants; // Firebase chat için participants listesi
  final String? ticketId; // Opsiyonel - ticket ile ilgili sohbetler için
  final String? buyerId;
  final String? sellerId;
  final String? buyerName;
  final String? sellerName;
  final ConversationType type;
  final ConversationStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? lastMessage; // Firebase chat için lastMessage
  final DateTime? lastMessageTime; // Firebase chat için lastMessageTime
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount; // Firebase chat için unreadCount map
  final bool isDeletedByBuyer;
  final bool isDeletedBySeller;
  final Map<String, dynamic>? metadata;

  const Conversation({
    required this.id,
    required this.participants, // Firebase chat için gerekli
    this.ticketId,
    this.buyerId,
    this.sellerId,
    this.buyerName,
    this.sellerName,
    this.type = ConversationType.general,
    this.status = ConversationStatus.active,
    required this.createdAt,
    this.updatedAt,
    this.lastMessage, // Firebase chat için
    this.lastMessageTime, // Firebase chat için
    this.lastMessageSenderId,
    this.unreadCount = const {}, // Firebase chat için
    this.isDeletedByBuyer = false,
    this.isDeletedBySeller = false,
    this.metadata,
  });

  Conversation copyWith({
    String? id,
    List<String>? participants,
    String? ticketId,
    String? buyerId,
    String? sellerId,
    String? buyerName,
    String? sellerName,
    ConversationType? type,
    ConversationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    Map<String, int>? unreadCount,
    bool? isDeletedByBuyer,
    bool? isDeletedBySeller,
    Map<String, dynamic>? metadata,
  }) {
    return Conversation(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      ticketId: ticketId ?? this.ticketId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      buyerName: buyerName ?? this.buyerName,
      sellerName: sellerName ?? this.sellerName,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      isDeletedByBuyer: isDeletedByBuyer ?? this.isDeletedByBuyer,
      isDeletedBySeller: isDeletedBySeller ?? this.isDeletedBySeller,
      metadata: metadata ?? this.metadata,
    );
  }

  // Get the other participant's information based on current user
  String getOtherParticipantId(String currentUserId) {
    // Firebase chat için participants listesinden karşı kullanıcıyı bul
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  String getOtherParticipantName(String currentUserId) {
    // Eski ticket sisteminden gelen için fallback
    if (buyerId != null && sellerId != null) {
      return currentUserId == buyerId ? (sellerName ?? '') : (buyerName ?? '');
    }
    return 'Bilinmeyen Kullanıcı';
  }

  String? getOtherParticipantAvatarUrl(String currentUserId) {
    // TODO: This method will be updated to use a global avatar service
    // For now, it will return null as metadata is no longer used for avatars
    return null;
  }

  int getUnreadCount(String currentUserId) {
    return unreadCount[currentUserId] ?? 0;
  }

  bool isDeletedBy(String currentUserId) {
    return currentUserId == buyerId ? isDeletedByBuyer : isDeletedBySeller;
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'ticketId': ticketId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'buyerName': buyerName,
      'sellerName': sellerName,
      'type': type.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'isDeletedByBuyer': isDeletedByBuyer,
      'isDeletedBySeller': isDeletedBySeller,
      'metadata': metadata,
    };
  }

  // Create from Firestore document
  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Conversation(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      ticketId: data['ticketId'],
      buyerId: data['buyerId'],
      sellerId: data['sellerId'],
      buyerName: data['buyerName'],
      sellerName: data['sellerName'],
      type: ConversationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ConversationType.general,
      ),
      status: ConversationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ConversationStatus.active,
      ),
      // Safe Timestamp casting with null checks
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt'] != null && data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime'] != null && data['lastMessageTime'] is Timestamp
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      lastMessageSenderId: data['lastMessageSenderId'],
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
      isDeletedByBuyer: data['isDeletedByBuyer'] ?? false,
      isDeletedBySeller: data['isDeletedBySeller'] ?? false,
      metadata: data['metadata'],
    );
  }
}

extension ConversationTypeExtension on ConversationType {
  String get displayName {
    switch (this) {
      case ConversationType.ticketInquiry:
        return 'Bilet Sorgusu';
      case ConversationType.general:
        return 'Genel';
      case ConversationType.support:
        return 'Destek';
      case ConversationType.dispute:
        return 'Anlaşmazlık';
    }
  }

  String get icon {
    switch (this) {
      case ConversationType.ticketInquiry:
        return '🎫';
      case ConversationType.general:
        return '💬';
      case ConversationType.support:
        return '🆘';
      case ConversationType.dispute:
        return '⚠️';
    }
  }
}

extension ConversationStatusExtension on ConversationStatus {
  String get displayName {
    switch (this) {
      case ConversationStatus.active:
        return 'Aktif';
      case ConversationStatus.closed:
        return 'Kapalı';
      case ConversationStatus.archived:
        return 'Arşivlendi';
    }
  }
}
