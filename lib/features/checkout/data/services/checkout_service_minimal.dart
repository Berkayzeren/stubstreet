// lib/features/checkout/data/services/checkout_service_minimal.dart
// Minimal checkout service without Stripe dependencies

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/checkout_session.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../orders/domain/entities/order.dart' as order_entity;
import '../../../auth/domain/entities/user.dart';
// import '../../../tickets/data/services/ticket_lock_service.dart';
// import '../../../../core/services/authorization_service.dart';

/// Minimal checkout service for payment processing
/// This replaces the Stripe-dependent checkout service
class CheckoutServiceMinimal {
  final FirebaseFirestore _firestore;
  // final TicketLockService _ticketLockService;
  // final AuthorizationService _authorizationService;

  CheckoutServiceMinimal(
    this._firestore,
    // this._ticketLockService,
    // this._authorizationService,
  );

  CollectionReference get _checkoutSessionsCollection =>
      _firestore.collection('checkout_sessions');

  /// Simplified checkout process without payment provider
  Future<CheckoutSession> initiateCheckout({
    required String ticketId,
    required User buyer,
    required String paymentMethod,
    String? promoCode,
    Map<String, dynamic>? billingAddress,
    order_entity.DeliveryMethod deliveryMethod =
        order_entity.DeliveryMethod.digital,
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

      // 3. Create checkout session
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
      // Get checkout session
      final sessionDoc = await _checkoutSessionsCollection
          .doc(checkoutSessionId)
          .get();

      if (!sessionDoc.exists) {
        throw Exception('Checkout session not found');
      }

      final session = CheckoutSession.fromFirestore(sessionDoc);

      // Create order
      final order = order_entity.Order(
        id: '', // Will be set by Firestore
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
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: 'Order created via simplified checkout',
        attachments: [],
        metadata: session.metadata,
      );

      final orderRef = await _firestore.collection('orders').add(order.toFirestore());
      
      // Update session status
      await _checkoutSessionsCollection
          .doc(checkoutSessionId)
          .update({
        'status': CheckoutStatus.completed.name,
        'orderId': orderRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return order.copyWith(id: orderRef.id);
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
