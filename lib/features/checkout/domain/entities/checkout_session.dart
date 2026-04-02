// lib/features/checkout/domain/entities/checkout_session.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../orders/domain/entities/order.dart' as order_entity;

enum CheckoutStatus {
  initiated,
  processing,
  completed,
  cancelled,
  expired,
  failed,
}

class CheckoutSession {
  final String id;
  final String ticketId;
  final String buyerId;
  final String sellerId;
  final String buyerEmail;
  final String sellerEmail;
  final double ticketPrice;
  final double serviceFee;
  final double discount;
  final double totalAmount;
  final String currency;
  final String paymentMethod;
  final order_entity.DeliveryMethod deliveryMethod;
  final CheckoutStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime expiresAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? paymentIntentId;
  final String? clientSecret;
  final String? orderId;
  final Map<String, dynamic>? metadata;

  const CheckoutSession({
    required this.id,
    required this.ticketId,
    required this.buyerId,
    required this.sellerId,
    required this.buyerEmail,
    required this.sellerEmail,
    required this.ticketPrice,
    required this.serviceFee,
    required this.discount,
    required this.totalAmount,
    required this.currency,
    required this.paymentMethod,
    required this.deliveryMethod,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.updatedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.paymentIntentId,
    this.clientSecret,
    this.orderId,
    this.metadata,
  });

  CheckoutSession copyWith({
    String? id,
    String? ticketId,
    String? buyerId,
    String? sellerId,
    String? buyerEmail,
    String? sellerEmail,
    double? ticketPrice,
    double? serviceFee,
    double? discount,
    double? totalAmount,
    String? currency,
    String? paymentMethod,
    order_entity.DeliveryMethod? deliveryMethod,
    CheckoutStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    String? paymentIntentId,
    String? clientSecret,
    String? orderId,
    Map<String, dynamic>? metadata,
  }) {
    return CheckoutSession(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      buyerEmail: buyerEmail ?? this.buyerEmail,
      sellerEmail: sellerEmail ?? this.sellerEmail,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      serviceFee: serviceFee ?? this.serviceFee,
      discount: discount ?? this.discount,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      clientSecret: clientSecret ?? this.clientSecret,
      orderId: orderId ?? this.orderId,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActive => status == CheckoutStatus.initiated && !isExpired;
  bool get isCompleted => status == CheckoutStatus.completed;
  bool get isCancelled => status == CheckoutStatus.cancelled;

  Duration get timeRemaining => expiresAt.difference(DateTime.now());

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'ticketId': ticketId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'buyerEmail': buyerEmail,
      'sellerEmail': sellerEmail,
      'ticketPrice': ticketPrice,
      'serviceFee': serviceFee,
      'discount': discount,
      'totalAmount': totalAmount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'deliveryMethod': deliveryMethod.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'cancelledAt': cancelledAt != null
          ? Timestamp.fromDate(cancelledAt!)
          : null,
      'cancellationReason': cancellationReason,
      'paymentIntentId': paymentIntentId,
      'clientSecret': clientSecret,
      'orderId': orderId,
      'metadata': metadata,
    };
  }

  // Create from Firestore document
  factory CheckoutSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CheckoutSession(
      id: doc.id,
      ticketId: data['ticketId'] ?? '',
      buyerId: data['buyerId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      buyerEmail: data['buyerEmail'] ?? '',
      sellerEmail: data['sellerEmail'] ?? '',
      ticketPrice: (data['ticketPrice'] ?? 0.0).toDouble(),
      serviceFee: (data['serviceFee'] ?? 0.0).toDouble(),
      discount: (data['discount'] ?? 0.0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'TRY',
      paymentMethod: data['paymentMethod'] ?? '',
      deliveryMethod: order_entity.DeliveryMethod.values.firstWhere(
        (e) => e.name == data['deliveryMethod'],
        orElse: () => order_entity.DeliveryMethod.digital,
      ),
      status: CheckoutStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => CheckoutStatus.initiated,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
      cancellationReason: data['cancellationReason'],
      paymentIntentId: data['paymentIntentId'],
      clientSecret: data['clientSecret'],
      orderId: data['orderId'],
      metadata: data['metadata'],
    );
  }
}

extension CheckoutStatusExtension on CheckoutStatus {
  String get displayName {
    switch (this) {
      case CheckoutStatus.initiated:
        return 'Başlatıldı';
      case CheckoutStatus.processing:
        return 'İşleniyor';
      case CheckoutStatus.completed:
        return 'Tamamlandı';
      case CheckoutStatus.cancelled:
        return 'İptal Edildi';
      case CheckoutStatus.expired:
        return 'Süresi Doldu';
      case CheckoutStatus.failed:
        return 'Başarısız';
    }
  }

  String get icon {
    switch (this) {
      case CheckoutStatus.initiated:
        return '🚀';
      case CheckoutStatus.processing:
        return '⏳';
      case CheckoutStatus.completed:
        return '✅';
      case CheckoutStatus.cancelled:
        return '❌';
      case CheckoutStatus.expired:
        return '⏰';
      case CheckoutStatus.failed:
        return '💥';
    }
  }
}
