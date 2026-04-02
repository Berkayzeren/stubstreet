// lib/features/payments/data/repositories/payment_repository_impl.dart

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:stubstreet/features/auth/domain/entities/user.dart';
import 'package:stubstreet/features/orders/domain/entities/order.dart'
    as order_entity;
import 'package:stubstreet/features/payments/domain/entities/payment.dart';
import 'package:stubstreet/features/payments/domain/repositories/payment_repository.dart';

/// Implementation of PaymentRepository that handles payment processing
/// without relying on any specific payment provider
class PaymentRepositoryImpl implements PaymentRepository {
  final FirebaseFirestore _firestore;

  PaymentRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> createPaymentIntent({
    required order_entity.Order order,
    required User buyer,
    required User seller,
  }) async {
    try {
      // For now, we'll create a placeholder payment intent
      // In a real implementation, this would integrate with payment providers like PayTR, iyzico, etc.
      
      final paymentId = _firestore.collection('payments').doc().id;
      
      // Create payment record in Firestore
      final payment = Payment(
        id: paymentId,
        orderId: order.id,
        payerId: buyer.id,
        payeeId: seller.id,
        paymentMethod: 'placeholder', // Will be replaced with actual payment method
        amount: order.totalAmount,
        createdAt: DateTime.now(),
        currency: order.currency,
        status: PaymentStatus.pending,
        paymentIntentId: 'intent_$paymentId',
        transactionId: null,
        applicationFee: order.totalAmount * 0.05, // 5% platform fee
        sellerAmount: order.totalAmount * 0.95,
        metadata: {
          'order_id': order.id,
          'buyer_id': buyer.id,
          'seller_id': seller.id,
        },
      );

      await _firestore
          .collection('payments')
          .doc(paymentId)
          .set(payment.toFirestore());

      log('Payment intent created: $paymentId', name: 'PaymentRepository');
      return 'client_secret_$paymentId'; // Placeholder client secret
    } catch (e) {
      log('Error creating payment intent: $e', name: 'PaymentRepository');
      rethrow;
    }
  }

  @override
  Future<void> handleWebhookEvent({
    required String eventType,
    required Map<String, dynamic> eventData,
  }) async {
    try {
      log('Handling webhook event: $eventType', name: 'PaymentRepository');
      
      // Placeholder implementation for webhook handling
      // In a real implementation, this would handle various payment provider webhooks
      
      switch (eventType) {
        case 'payment.succeeded':
          await _handlePaymentSucceeded(eventData);
          break;
        case 'payment.failed':
          await _handlePaymentFailed(eventData);
          break;
        default:
          log('Unhandled event type: $eventType', name: 'PaymentRepository');
      }
    } catch (e) {
      log('Error handling webhook event: $e', name: 'PaymentRepository');
      rethrow;
    }
  }

  @override
  Future<Payment?> getPaymentByIntentId(String intentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('payments')
          .where('paymentIntentId', isEqualTo: intentId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return Payment.fromFirestore(doc);
    } catch (e) {
      log('Error getting payment by intent ID: $e', name: 'PaymentRepository');
      rethrow;
    }
  }

  @override
  Future<List<Payment>> getUserPayments(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('payments')
          .where('payerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Payment.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error getting user payments: $e', name: 'PaymentRepository');
      rethrow;
    }
  }

  @override
  Future<void> cancelPayment(String paymentId) async {
    try {
      await _firestore
          .collection('payments')
          .doc(paymentId)
          .update({
        'status': PaymentStatus.failed.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      log('Payment cancelled: $paymentId', name: 'PaymentRepository');
    } catch (e) {
      log('Error cancelling payment: $e', name: 'PaymentRepository');
      rethrow;
    }
  }

  /// Handle successful payment webhook
  Future<void> _handlePaymentSucceeded(Map<String, dynamic> eventData) async {
    try {
      final paymentIntentId = eventData['paymentIntentId'] as String?;
      if (paymentIntentId == null) return;

      final payment = await getPaymentByIntentId(paymentIntentId);
      if (payment == null) return;

      await _firestore
          .collection('payments')
          .doc(payment.id)
          .update({
        'status': PaymentStatus.successful.name,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      log('Payment succeeded: ${payment.id}', name: 'PaymentRepository');
    } catch (e) {
      log('Error handling payment succeeded: $e', name: 'PaymentRepository');
    }
  }

  /// Handle failed payment webhook
  Future<void> _handlePaymentFailed(Map<String, dynamic> eventData) async {
    try {
      final paymentIntentId = eventData['paymentIntentId'] as String?;
      if (paymentIntentId == null) return;

      final payment = await getPaymentByIntentId(paymentIntentId);
      if (payment == null) return;

      await _firestore
          .collection('payments')
          .doc(payment.id)
          .update({
        'status': PaymentStatus.failed.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      log('Payment failed: ${payment.id}', name: 'PaymentRepository');
    } catch (e) {
      log('Error handling payment failed: $e', name: 'PaymentRepository');
    }
  }
}