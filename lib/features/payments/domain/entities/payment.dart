// lib/features/payments/domain/entities/payment.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus { pending, successful, failed, refunded, disputed }

class Payment {
  final String id;
  final String orderId;
  final String payerId;
  final String payeeId;
  final String paymentMethod;
  final double amount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final DateTime? refundedAt;
  final String? refundReason;
  final String currency;
  final PaymentStatus status;
  final Map<String, dynamic>? metadata;
  final List<String> attachments;
  // Payment provider specific fields
  final String? paymentIntentId;
  final String? transactionId;
  final double? applicationFee;
  final double? sellerAmount;

  const Payment({
    required this.id,
    required this.orderId,
    required this.payerId,
    required this.payeeId,
    required this.paymentMethod,
    required this.amount,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.refundedAt,
    this.refundReason,
    required this.currency,
    required this.status,
    this.metadata,
    this.attachments = const [],
    this.paymentIntentId,
    this.transactionId,
    this.applicationFee,
    this.sellerAmount,
  });

  Payment copyWith({
    String? id,
    String? orderId,
    String? payerId,
    String? payeeId,
    String? paymentMethod,
    double? amount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? refundedAt,
    String? refundReason,
    String? currency,
    PaymentStatus? status,
    Map<String, dynamic>? metadata,
    List<String>? attachments,
    String? paymentIntentId,
    String? transactionId,
    double? applicationFee,
    double? sellerAmount,
  }) {
    return Payment(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      payerId: payerId ?? this.payerId,
      payeeId: payeeId ?? this.payeeId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      refundedAt: refundedAt ?? this.refundedAt,
      refundReason: refundReason ?? this.refundReason,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      attachments: attachments ?? this.attachments,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      transactionId: transactionId ?? this.transactionId,
      applicationFee: applicationFee ?? this.applicationFee,
      sellerAmount: sellerAmount ?? this.sellerAmount,
    );
  }

  bool get isPending => status == PaymentStatus.pending;
  bool get isSuccessful => status == PaymentStatus.successful;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isRefunded => status == PaymentStatus.refunded;
  bool get isDisputed => status == PaymentStatus.disputed;

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'orderId': orderId,
      'payerId': payerId,
      'payeeId': payeeId,
      'paymentMethod': paymentMethod,
      'amount': amount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'refundedAt': refundedAt != null ? Timestamp.fromDate(refundedAt!) : null,
      'refundReason': refundReason,
      'currency': currency,
      'status': status.name,
      'metadata': metadata,
      'attachments': attachments,
      'paymentIntentId': paymentIntentId,
      'transactionId': transactionId,
      'applicationFee': applicationFee,
      'sellerAmount': sellerAmount,
    };
  }

  // Create from Firestore document
  factory Payment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Payment(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      payerId: data['payerId'] ?? '',
      payeeId: data['payeeId'] ?? '',
      paymentMethod: data['paymentMethod'] ?? 'unknown',
      amount: (data['amount'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      refundedAt: data['refundedAt'] != null
          ? (data['refundedAt'] as Timestamp).toDate()
          : null,
      refundReason: data['refundReason'],
      currency: data['currency'] ?? 'TRY',
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PaymentStatus.pending,
      ),
      metadata: data['metadata'],
      attachments: List<String>.from(data['attachments'] ?? []),
      paymentIntentId: data['paymentIntentId'],
      transactionId: data['transactionId'],
      applicationFee: data['applicationFee']?.toDouble(),
      sellerAmount: data['sellerAmount']?.toDouble(),
    );
  }
}

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Beklemede';
      case PaymentStatus.successful:
        return 'Başarılı';
      case PaymentStatus.failed:
        return 'Başarısız';
      case PaymentStatus.refunded:
        return 'İade Edildi';
      case PaymentStatus.disputed:
        return 'Anlaşmazlık';
    }
  }

  String get icon {
    switch (this) {
      case PaymentStatus.pending:
        return '⏳';
      case PaymentStatus.successful:
        return '✅';
      case PaymentStatus.failed:
        return '❌';
      case PaymentStatus.refunded:
        return '💰';
      case PaymentStatus.disputed:
        return '⚠️';
    }
  }
}
