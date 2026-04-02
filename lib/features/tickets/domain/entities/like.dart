// lib/features/tickets/domain/entities/like.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Like {
  final String id;
  final String userId;
  final String ticketId;
  final DateTime createdAt;

  const Like({
    required this.id,
    required this.userId,
    required this.ticketId,
    required this.createdAt,
  });

  Like copyWith({
    String? id,
    String? userId,
    String? ticketId,
    DateTime? createdAt,
  }) {
    return Like(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ticketId: ticketId ?? this.ticketId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'ticketId': ticketId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Like.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Like(
      id: doc.id,
      userId: data['userId'] ?? '',
      ticketId: data['ticketId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
