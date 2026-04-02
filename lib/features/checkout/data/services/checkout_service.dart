// lib/features/checkout/data/services/checkout_service.dart
// Clean checkout service without Stripe dependencies

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/checkout_session.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../orders/domain/entities/order.dart' as order_entity;
import '../../../auth/domain/entities/user.dart';
import '../../../../core/services/fraud_detection_service.dart';
import '../../../../core/services/fraud_detection_types.dart';
import 'dart:developer' as developer;
// import '../../../tickets/data/services/ticket_lock_service.dart';
// import '../../../../core/services/authorization_service.dart';

/// Clean checkout service for production use
/// This replaces the Stripe-dependent checkout service
class CheckoutService {
  final FirebaseFirestore _firestore;
  final FraudDetectionService _fraudDetectionService;
  // final TicketLockService _ticketLockService;
  // final AuthorizationService _authorizationService;

  CheckoutService(
    this._firestore,
    [FraudDetectionService? fraudDetectionService]
    // this._ticketLockService,
    // this._authorizationService,
  ) : _fraudDetectionService = fraudDetectionService ?? FraudDetectionService(_firestore);

  CollectionReference get _checkoutSessionsCollection =>
      _firestore.collection('checkout_sessions');

  /// Simplified checkout process with fraud detection
  Future<CheckoutSession> initiateCheckout({
    required String ticketId,
    required User buyer,
    required String paymentMethod,
    String? promoCode,
    Map<String, dynamic>? billingAddress,
    order_entity.DeliveryMethod deliveryMethod =
        order_entity.DeliveryMethod.digital,
    String? deviceId,
    String? ipAddress,
    Map<String, dynamic>? userAgent,
  }) async {
    try {
      // 1. Get ticket and validate
      final ticketDoc = await _firestore
          .collection('tickets')
          .doc(ticketId)
          .get();

      if (!ticketDoc.exists) {
        throw Exception('Ticket not found');
      }

      final ticket = Ticket.fromFirestore(ticketDoc);

      // 2. Basic validation
      if (ticket.status != TicketStatus.available) {
        throw Exception('Ticket is not available');
      }

      if (ticket.sellerId == buyer.id) {
        throw Exception('Kullanıcı kendi oluşturduğu bileti satın alamaz.');
      }

      // 3. Fraud detection analysis
      developer.log('Starting fraud detection for checkout', name: 'CheckoutService');
      
      final fraudResult = await _fraudDetectionService.analyzePurchase(
        userId: buyer.id,
        ticketId: ticketId,
        amount: ticket.sellingPrice * 1.05, // Including service fee
        currency: 'TRY',
        paymentMethod: paymentMethod,
        deviceId: deviceId,
        ipAddress: ipAddress,
        userAgent: userAgent,
      );

      developer.log(
        'Fraud analysis completed: Risk Level: ${fraudResult.riskLevel.name}, Score: ${fraudResult.riskScore}',
        name: 'CheckoutService',
      );

      // 4. Check if transaction should be blocked
      if (fraudResult.shouldBlock) {
        developer.log(
          'Transaction blocked due to fraud risk: ${fraudResult.riskFactors.join(', ')}',
          name: 'CheckoutService',
        );
        throw Exception('İşlem güvenlik nedeniyle engellenmiştir. Lütfen müşteri hizmetleri ile iletişime geçin.');
      }

      // 5. Log high-risk transactions for manual review
      if (fraudResult.riskLevel == FraudRiskLevel.high) {
        developer.log(
          'High-risk transaction detected - manual review recommended: ${fraudResult.riskFactors.join(', ')}',
          name: 'CheckoutService',
        );
      }

      // 6. Create checkout session with fraud analysis data
      final session = CheckoutSession(
        id: '', // Will be set by Firestore
        buyerId: buyer.id,
        sellerId: ticket.sellerId,
        ticketId: ticketId,
        buyerEmail: buyer.email,
        sellerEmail: ticket.sellerName, // Using sellerName as fallback
        ticketPrice: ticket.sellingPrice,
        serviceFee: ticket.sellingPrice * 0.05, // 5% service fee
        discount: 0.0,
        totalAmount: ticket.sellingPrice * 1.05,
        currency: 'TRY',
        status: CheckoutStatus.initiated,
        paymentMethod: paymentMethod,
        deliveryMethod: deliveryMethod,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        clientSecret: 'mock_client_secret_${DateTime.now().millisecondsSinceEpoch}',
        paymentIntentId: 'mock_payment_intent_${DateTime.now().millisecondsSinceEpoch}',
        metadata: {
          'buyerEmail': buyer.email,
          'ticketTitle': ticket.title,
          'fraudAnalysis': fraudResult.toFirestore(),
          'deviceId': deviceId,
          'ipAddress': ipAddress,
          'userAgent': userAgent,
        },
      );

      final sessionRef = await _checkoutSessionsCollection.add(session.toFirestore());
      return session.copyWith(id: sessionRef.id);
    } catch (e) {
      throw Exception('Failed to initiate checkout: $e');
    }
  }

  /// Simplified checkout confirmation
  Future<order_entity.Order> confirmCheckout({
    required String checkoutSessionId,
    required String paymentIntentId,
  }) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final sessionRef = _checkoutSessionsCollection.doc(checkoutSessionId);
        final sessionSnapshot = await transaction.get(sessionRef);

        if (!sessionSnapshot.exists) {
          throw Exception('Checkout session not found');
        }

        final session = CheckoutSession.fromFirestore(sessionSnapshot);

        if (session.status == CheckoutStatus.completed) {
          if (session.orderId != null) {
            final existingOrderRef = _firestore.collection('orders').doc(session.orderId!);
            final existingOrderSnapshot = await transaction.get(existingOrderRef);

            if (existingOrderSnapshot.exists) {
              return order_entity.Order.fromFirestore(existingOrderSnapshot);
            }
          }

          throw Exception('Checkout session already completed');
        }

        if (session.status == CheckoutStatus.cancelled || session.isExpired) {
          throw Exception('Checkout session is no longer valid');
        }

        final ticketRef = _firestore.collection('tickets').doc(session.ticketId);
        final ticketSnapshot = await transaction.get(ticketRef);

        if (!ticketSnapshot.exists) {
          throw Exception('Ticket not found');
        }

        final ticketData = ticketSnapshot.data() as Map<String, dynamic>;
        final currentStatus = ticketData['status'] as String? ?? TicketStatus.available.name;

        if (currentStatus == TicketStatus.sold.name) {
          throw Exception('Ticket is already sold');
        }

        if (currentStatus == TicketStatus.reserved.name && ticketData['buyerId'] != session.buyerId) {
          throw Exception('Ticket is reserved by another buyer');
        }

        final now = DateTime.now();
        final orderRef = _firestore.collection('orders').doc();

        final metadata = <String, dynamic>{
          ...?session.metadata,
          'paymentIntentId': paymentIntentId,
        };

        final order = order_entity.Order(
          id: orderRef.id,
          buyerId: session.buyerId,
          sellerId: session.sellerId,
          ticketId: session.ticketId,
          buyerName: session.buyerEmail, // Using email as fallback
          sellerName: session.sellerEmail, // Using email as fallback
          buyerEmail: session.buyerEmail,
          sellerEmail: session.sellerEmail,
          ticketPrice: session.ticketPrice,
          serviceFee: session.serviceFee,
          totalAmount: session.totalAmount,
          currency: session.currency,
          status: order_entity.OrderStatus.confirmed,
          type: order_entity.OrderType.purchase,
          deliveryMethod: session.deliveryMethod,
          createdAt: now,
          updatedAt: now,
          confirmedAt: now,
          notes: 'Order created via simplified checkout',
          attachments: const [],
          metadata: metadata,
        );

        transaction.set(orderRef, order.toFirestore());

        transaction.update(ticketRef, {
          'status': TicketStatus.sold.name,
          'buyerId': session.buyerId,
          'soldDate': Timestamp.fromDate(now),
          'lockUntil': FieldValue.delete(),
        });

        transaction.update(sessionRef, {
          'status': CheckoutStatus.completed.name,
          'orderId': orderRef.id,
          'paymentIntentId': paymentIntentId,
          'updatedAt': Timestamp.fromDate(now),
          'completedAt': Timestamp.fromDate(now),
        });

        return order;
      });
    } catch (e) {
      throw Exception('Failed to confirm checkout: $e');
    }
  }

  /// Cancel checkout session
  Future<void> cancelCheckout(String checkoutSessionId) async {
    try {
      await _checkoutSessionsCollection
          .doc(checkoutSessionId)
          .update({
        'status': CheckoutStatus.cancelled.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel checkout: $e');
    }
  }
}
