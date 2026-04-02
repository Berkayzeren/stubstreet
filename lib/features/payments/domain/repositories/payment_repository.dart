// lib/features/payments/domain/repositories/payment_repository.dart

import 'package:stubstreet/features/auth/domain/entities/user.dart';
import 'package:stubstreet/features/orders/domain/entities/order.dart';
import 'package:stubstreet/features/payments/domain/entities/payment.dart';

abstract class PaymentRepository {
  /// Create a payment intent for an order
  /// Returns the client secret for payment processing
  Future<String> createPaymentIntent({
    required Order order,
    required User buyer,
    required User seller,
  });

  /// Handle payment webhook events
  Future<void> handleWebhookEvent({
    required String eventType,
    required Map<String, dynamic> eventData,
  });

  /// Get payment by PaymentIntent ID
  Future<Payment?> getPaymentByIntentId(String intentId);

  /// Get all payments for a user
  Future<List<Payment>> getUserPayments(String userId);

  /// Cancel a payment
  Future<void> cancelPayment(String paymentId);
}
