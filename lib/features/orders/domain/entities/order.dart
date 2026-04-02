// lib/features/orders/domain/entities/order.dart

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
  refunded,
  disputed,
}

enum OrderType { purchase, sale, transfer }

enum DeliveryMethod { digital, mail, pickup, meetup }

class Order {
  final String id;
  final String ticketId;
  final String buyerId;
  final String sellerId;
  final String buyerName;
  final String sellerName;
  final String buyerEmail;
  final String sellerEmail;
  final OrderStatus status;
  final OrderType type;
  final DeliveryMethod deliveryMethod;
  final double ticketPrice;
  final double serviceFee;
  final double totalAmount;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? confirmedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? trackingNumber;
  final String? deliveryAddress;
  final String? meetupLocation;
  final DateTime? meetupDateTime;
  final String? notes;
  final List<String> attachments;
  final Map<String, dynamic>? metadata;
  final String? buyerAvatarUrl;
  final String? sellerAvatarUrl;

  // Lock işlemleri için
  final bool isLocked;
  final String? lockedBy;
  final DateTime? lockedAt;
  final DateTime? lockExpiresAt;

  const Order({
    required this.id,
    required this.ticketId,
    required this.buyerId,
    required this.sellerId,
    required this.buyerName,
    required this.sellerName,
    required this.buyerEmail,
    required this.sellerEmail,
    required this.status,
    required this.type,
    required this.deliveryMethod,
    required this.ticketPrice,
    required this.serviceFee,
    required this.totalAmount,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
    this.confirmedAt,
    this.shippedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancellationReason,
    this.trackingNumber,
    this.deliveryAddress,
    this.meetupLocation,
    this.meetupDateTime,
    this.notes,
    this.attachments = const [],
    this.metadata,
    this.buyerAvatarUrl,
    this.sellerAvatarUrl,
    this.isLocked = false,
    this.lockedBy,
    this.lockedAt,
    this.lockExpiresAt,
  });

  Order copyWith({
    String? id,
    String? ticketId,
    String? buyerId,
    String? sellerId,
    String? buyerName,
    String? sellerName,
    String? buyerAvatarUrl,
    String? sellerAvatarUrl,
    String? buyerEmail,
    String? sellerEmail,
    OrderStatus? status,
    OrderType? type,
    DeliveryMethod? deliveryMethod,
    double? ticketPrice,
    double? serviceFee,
    double? totalAmount,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? confirmedAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    String? trackingNumber,
    String? deliveryAddress,
    String? meetupLocation,
    DateTime? meetupDateTime,
    String? notes,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
    bool? isLocked,
    String? lockedBy,
    DateTime? lockedAt,
    DateTime? lockExpiresAt,
  }) {
    return Order(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      buyerName: buyerName ?? this.buyerName,
      sellerName: sellerName ?? this.sellerName,
      buyerEmail: buyerEmail ?? this.buyerEmail,
      sellerEmail: sellerEmail ?? this.sellerEmail,
      status: status ?? this.status,
      type: type ?? this.type,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      serviceFee: serviceFee ?? this.serviceFee,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      meetupLocation: meetupLocation ?? this.meetupLocation,
      meetupDateTime: meetupDateTime ?? this.meetupDateTime,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
      buyerAvatarUrl: buyerAvatarUrl ?? this.buyerAvatarUrl,
      sellerAvatarUrl: sellerAvatarUrl ?? this.sellerAvatarUrl,
      isLocked: isLocked ?? this.isLocked,
      lockedBy: lockedBy ?? this.lockedBy,
      lockedAt: lockedAt ?? this.lockedAt,
      lockExpiresAt: lockExpiresAt ?? this.lockExpiresAt,
    );
  }

  bool get isPending => status == OrderStatus.pending;
  bool get isCompleted => status == OrderStatus.delivered;
  bool get isCancelled => status == OrderStatus.cancelled;
  bool get canBeCancelled => isPending || status == OrderStatus.confirmed;
  bool get requiresShipping => deliveryMethod == DeliveryMethod.mail;
  bool get requiresMeetup => deliveryMethod == DeliveryMethod.meetup;

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'ticketId': ticketId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'buyerName': buyerName,
      'sellerName': sellerName,
      'buyerEmail': buyerEmail,
      'sellerEmail': sellerEmail,
      'status': status.name,
      'type': type.name,
      'deliveryMethod': deliveryMethod.name,
      'ticketPrice': ticketPrice,
      'serviceFee': serviceFee,
      'totalAmount': totalAmount,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'confirmedAt': confirmedAt != null
          ? Timestamp.fromDate(confirmedAt!)
          : null,
      'shippedAt': shippedAt != null ? Timestamp.fromDate(shippedAt!) : null,
      'deliveredAt': deliveredAt != null
          ? Timestamp.fromDate(deliveredAt!)
          : null,
      'cancelledAt': cancelledAt != null
          ? Timestamp.fromDate(cancelledAt!)
          : null,
      'cancellationReason': cancellationReason,
      'trackingNumber': trackingNumber,
      'deliveryAddress': deliveryAddress,
      'meetupLocation': meetupLocation,
      'meetupDateTime': meetupDateTime != null
          ? Timestamp.fromDate(meetupDateTime!)
          : null,
      'notes': notes,
      'attachments': attachments,
      'metadata': metadata,
      'isLocked': isLocked,
      'lockedBy': lockedBy,
      'lockedAt': lockedAt != null ? Timestamp.fromDate(lockedAt!) : null,
      'lockExpiresAt': lockExpiresAt != null
          ? Timestamp.fromDate(lockExpiresAt!)
          : null,
      'buyerAvatarUrl': buyerAvatarUrl,
      'sellerAvatarUrl': sellerAvatarUrl,
    };
  }

  // Create from Firestore document
  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      ticketId: data['ticketId'] ?? '',
      buyerId: data['buyerId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      buyerName: data['buyerName'] ?? '',
      sellerName: data['sellerName'] ?? '',
      buyerEmail: data['buyerEmail'] ?? '',
      sellerEmail: data['sellerEmail'] ?? '',
      status: OrderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      type: OrderType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => OrderType.purchase,
      ),
      deliveryMethod: DeliveryMethod.values.firstWhere(
        (e) => e.name == data['deliveryMethod'],
        orElse: () => DeliveryMethod.digital,
      ),
      ticketPrice: _normalizeAmount(data['ticketPrice']),
      serviceFee: _normalizeAmount(data['serviceFee']),
      totalAmount: _normalizeAmount(
        data['totalAmount'],
        fallback: _normalizeAmount(data['ticketPrice']) + _normalizeAmount(data['serviceFee']),
      ),
      currency: data['currency'] ?? 'TRY',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      confirmedAt: data['confirmedAt'] != null
          ? (data['confirmedAt'] as Timestamp).toDate()
          : null,
      shippedAt: data['shippedAt'] != null
          ? (data['shippedAt'] as Timestamp).toDate()
          : null,
      deliveredAt: data['deliveredAt'] != null
          ? (data['deliveredAt'] as Timestamp).toDate()
          : null,
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
      cancellationReason: data['cancellationReason'],
      trackingNumber: data['trackingNumber'],
      deliveryAddress: data['deliveryAddress'],
      meetupLocation: data['meetupLocation'],
      meetupDateTime: data['meetupDateTime'] != null
          ? (data['meetupDateTime'] as Timestamp).toDate()
          : null,
      notes: data['notes'],
      attachments: List<String>.from(data['attachments'] ?? []),
      metadata: data['metadata'],
      isLocked: data['isLocked'] ?? false,
      lockedBy: data['lockedBy'],
      lockedAt: data['lockedAt'] != null
          ? (data['lockedAt'] as Timestamp).toDate()
          : null,
      lockExpiresAt: data['lockExpiresAt'] != null
          ? (data['lockExpiresAt'] as Timestamp).toDate()
          : null,
      buyerAvatarUrl: data['buyerAvatarUrl'],
      sellerAvatarUrl: data['sellerAvatarUrl'],
    );
  }
}

double _normalizeAmount(dynamic value, {double? fallback}) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed != null) return parsed;
  }
  if (value is Map<String, dynamic>) {
    final intValue = value['integerValue'];
    if (intValue is String) {
      final parsed = int.tryParse(intValue);
      if (parsed != null) {
        if ((value['scale'] ?? value['integerScale']) != null) {
          final scale = int.tryParse('${value['scale'] ?? value['integerScale']}') ?? 0;
          return parsed / (scale == 0 ? 1 : pow(10, scale));
        }
        return parsed / 100.0;
      }
    }
    final doubleValue = value['doubleValue'];
    if (doubleValue is String) {
      final parsed = double.tryParse(doubleValue);
      if (parsed != null) return parsed;
    }
  }
  return fallback ?? 0.0;
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Beklemede';
      case OrderStatus.confirmed:
        return 'Onaylandı';
      case OrderStatus.processing:
        return 'İşleniyor';
      case OrderStatus.shipped:
        return 'Kargoya Verildi';
      case OrderStatus.delivered:
        return 'Teslim Edildi';
      case OrderStatus.cancelled:
        return 'İptal Edildi';
      case OrderStatus.refunded:
        return 'İade Edildi';
      case OrderStatus.disputed:
        return 'Anlaşmazlık';
    }
  }

  String get icon {
    switch (this) {
      case OrderStatus.pending:
        return '⏳';
      case OrderStatus.confirmed:
        return '✅';
      case OrderStatus.processing:
        return '🔄';
      case OrderStatus.shipped:
        return '📦';
      case OrderStatus.delivered:
        return '🎯';
      case OrderStatus.cancelled:
        return '❌';
      case OrderStatus.refunded:
        return '💰';
      case OrderStatus.disputed:
        return '⚠️';
    }
  }
}

extension DeliveryMethodExtension on DeliveryMethod {
  String get displayName {
    switch (this) {
      case DeliveryMethod.digital:
        return 'Dijital';
      case DeliveryMethod.mail:
        return 'Posta';
      case DeliveryMethod.pickup:
        return 'Teslim Alma';
      case DeliveryMethod.meetup:
        return 'Buluşma';
    }
  }

  IconData get icon {
    switch (this) {
      case DeliveryMethod.digital:
        return Icons.smartphone;
      case DeliveryMethod.mail:
        return Icons.mail;
      case DeliveryMethod.pickup:
        return Icons.store;
      case DeliveryMethod.meetup:
        return Icons.handshake;
    }
  }
}
