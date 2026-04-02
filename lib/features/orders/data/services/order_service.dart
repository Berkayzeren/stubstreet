// lib/features/orders/data/services/order_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/order.dart' as order_entity;
import '../../../tickets/domain/entities/ticket.dart';

/// Service for managing order processing, including confirmation and refund
class OrderService {
  final FirebaseFirestore _firestore;

  OrderService(this._firestore);

  CollectionReference get _ordersCollection => _firestore.collection('orders');
  CollectionReference get _ticketsCollection =>
      _firestore.collection('tickets');

  /// Creates an order with proper transaction handling
  /// Locks ticket → Creates order → Updates ticket status
  Future<String> createOrder({
    required String ticketId,
    required String buyerId,
    required String sellerId,
    required String buyerName,
    required String sellerName,
    required String buyerEmail,
    required String sellerEmail,
    required double ticketPrice,
    required double serviceFee,
    required String currency,
    required order_entity.DeliveryMethod deliveryMethod,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      return await _firestore.runTransaction<String>((transaction) async {
        // First, check and lock the ticket
        final ticketDoc = _ticketsCollection.doc(ticketId);
        final ticketSnapshot = await transaction.get(ticketDoc);

        if (!ticketSnapshot.exists) {
          throw Exception('Ticket not found');
        }

        final ticket = Ticket.fromFirestore(ticketSnapshot);
        final now = DateTime.now();

        // Verify ticket availability
        if (ticket.status != TicketStatus.available &&
            !(ticket.status == TicketStatus.reserved &&
                ticket.buyerId == buyerId &&
                ticket.lockUntil != null &&
                ticket.lockUntil!.isAfter(now))) {
          throw Exception('Ticket is not available for purchase');
        }

        // Create the order
        final order = order_entity.Order(
          id: '', // Will be set by Firestore
          ticketId: ticketId,
          buyerId: buyerId,
          sellerId: sellerId,
          buyerName: buyerName,
          sellerName: sellerName,
          buyerEmail: buyerEmail,
          sellerEmail: sellerEmail,
          status: order_entity.OrderStatus.pending,
          type: order_entity.OrderType.purchase,
          deliveryMethod: deliveryMethod,
          ticketPrice: ticketPrice,
          serviceFee: serviceFee,
          totalAmount: ticketPrice + serviceFee,
          currency: currency,
          createdAt: now,
          updatedAt: now,
          notes: notes,
          metadata: metadata,
        );

        // Add order to collection
        final orderRef = _ordersCollection.doc();
        transaction.set(orderRef, order.toFirestore());

        // Update ticket status to reserved
        transaction.update(ticketDoc, {
          'status': TicketStatus.reserved.name,
          'buyerId': buyerId,
          'lockUntil': Timestamp.fromDate(
            now.add(const Duration(hours: 1)),
          ), // 1 hour lock
        });

        return orderRef.id;
      });
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Confirms an order after successful payment
  /// Updates order status → Updates ticket status to sold
  Future<void> confirmOrder(String orderId, String paymentIntentId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final orderDoc = _ordersCollection.doc(orderId);
        final orderSnapshot = await transaction.get(orderDoc);

        if (!orderSnapshot.exists) {
          throw Exception('Order not found');
        }

        final order = order_entity.Order.fromFirestore(orderSnapshot);

        if (order.status != order_entity.OrderStatus.pending) {
          throw Exception(
            'Order cannot be confirmed. Current status: ${order.status.name}',
          );
        }

        // Update order status
        transaction.update(orderDoc, {
          'status': order_entity.OrderStatus.confirmed.name,
          'confirmedAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'metadata': {...?order.metadata, 'paymentIntentId': paymentIntentId},
        });

        // Update ticket status to sold
        final ticketDoc = _ticketsCollection.doc(order.ticketId);
        transaction.update(ticketDoc, {
          'status': TicketStatus.sold.name,
          'soldDate': Timestamp.now(),
          'lockUntil': FieldValue.delete(), // Remove lock
        });
      });
    } catch (e) {
      throw Exception('Failed to confirm order: $e');
    }
  }

  /// Cancels an order and releases the ticket lock
  Future<void> cancelOrder(
    String orderId,
    String reason, {
    String? cancelledBy,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final orderDoc = _ordersCollection.doc(orderId);
        final orderSnapshot = await transaction.get(orderDoc);

        if (!orderSnapshot.exists) {
          throw Exception('Order not found');
        }

        final order = order_entity.Order.fromFirestore(orderSnapshot);

        if (!order.canBeCancelled) {
          throw Exception(
            'Order cannot be cancelled. Current status: ${order.status.name}',
          );
        }

        // Update order status
        transaction.update(orderDoc, {
          'status': order_entity.OrderStatus.cancelled.name,
          'cancelledAt': Timestamp.now(),
          'cancellationReason': reason,
          'updatedAt': Timestamp.now(),
          'metadata': {...?order.metadata, 'cancelledBy': cancelledBy},
        });

        // Release ticket lock - make it available again
        final ticketDoc = _ticketsCollection.doc(order.ticketId);
        transaction.update(ticketDoc, {
          'status': TicketStatus.available.name,
          'buyerId': FieldValue.delete(),
          'lockUntil': FieldValue.delete(),
        });
      });
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  /// Processes a refund for a confirmed order
  Future<void> processRefund({
    required String orderId,
    required String reason,
    required String refundedBy,
    double? refundAmount,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final orderDoc = _ordersCollection.doc(orderId);
        final orderSnapshot = await transaction.get(orderDoc);

        if (!orderSnapshot.exists) {
          throw Exception('Order not found');
        }

        final order = order_entity.Order.fromFirestore(orderSnapshot);

        if (order.status != order_entity.OrderStatus.confirmed &&
            order.status != order_entity.OrderStatus.delivered) {
          throw Exception(
            'Refund only allowed for confirmed or delivered orders',
          );
        }

        // Update order status
        transaction.update(orderDoc, {
          'status': order_entity.OrderStatus.refunded.name,
          'cancellationReason': reason,
          'cancelledAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'metadata': {
            ...?order.metadata,
            'refundedBy': refundedBy,
            'refundAmount': refundAmount ?? order.totalAmount,
          },
        });

        // Make ticket available again if refund is processed early
        if (order.status == order_entity.OrderStatus.confirmed) {
          final ticketDoc = _ticketsCollection.doc(order.ticketId);
          transaction.update(ticketDoc, {
            'status': TicketStatus.available.name,
            'buyerId': FieldValue.delete(),
            'soldDate': FieldValue.delete(),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to process refund: $e');
    }
  }

  /// Handles dispute resolution
  Future<void> handleDispute({
    required String orderId,
    required String resolution,
    required String resolvedBy,
    order_entity.OrderStatus? finalStatus,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final orderDoc = _ordersCollection.doc(orderId);
        final orderSnapshot = await transaction.get(orderDoc);

        if (!orderSnapshot.exists) {
          throw Exception('Order not found');
        }

        final order = order_entity.Order.fromFirestore(orderSnapshot);

        // Update order with dispute resolution
        transaction.update(orderDoc, {
          'status': (finalStatus ?? order_entity.OrderStatus.disputed).name,
          'updatedAt': Timestamp.now(),
          'notes': resolution,
          'metadata': {
            ...?order.metadata,
            'disputeResolvedBy': resolvedBy,
            'disputeResolvedAt': Timestamp.now().toDate().toIso8601String(),
            'disputeResolution': resolution,
          },
        });

        // If dispute results in refund, handle ticket status
        if (finalStatus == order_entity.OrderStatus.refunded) {
          final ticketDoc = _ticketsCollection.doc(order.ticketId);
          transaction.update(ticketDoc, {
            'status': TicketStatus.available.name,
            'buyerId': FieldValue.delete(),
            'soldDate': FieldValue.delete(),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to handle dispute: $e');
    }
  }

  /// Updates order delivery status
  Future<void> updateDeliveryStatus({
    required String orderId,
    required order_entity.OrderStatus newStatus,
    String? trackingNumber,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': newStatus.name,
        'updatedAt': Timestamp.now(),
      };

      if (newStatus == order_entity.OrderStatus.shipped) {
        updateData['shippedAt'] = Timestamp.now();
        if (trackingNumber != null) {
          updateData['trackingNumber'] = trackingNumber;
        }
      } else if (newStatus == order_entity.OrderStatus.delivered) {
        updateData['deliveredAt'] = Timestamp.now();
      }

      if (notes != null) {
        updateData['notes'] = notes;
      }

      await _ordersCollection.doc(orderId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update delivery status: $e');
    }
  }

  /// Gets order by ID with authorization check
  Future<order_entity.Order?> getOrderById(
    String orderId,
    String userId,
  ) async {
    try {
      final doc = await _ordersCollection.doc(orderId).get();

      if (!doc.exists) {
        return null;
      }

      final order = order_entity.Order.fromFirestore(doc);

      // Authorization check - only buyer or seller can access
      if (order.buyerId != userId && order.sellerId != userId) {
        throw Exception('Unauthorized access to order');
      }

      return order;
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  /// Gets orders for a user (as buyer or seller)
  Future<List<order_entity.Order>> getOrdersForUser(String userId) async {
    try {
      final buyerOrders = await _ordersCollection
          .where('buyerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final sellerOrders = await _ordersCollection
          .where('sellerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final allOrders = [
        ...buyerOrders.docs,
        ...sellerOrders.docs,
      ].map((doc) => order_entity.Order.fromFirestore(doc)).toList();

      // Sort by creation date
      allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return allOrders;
    } catch (e) {
      throw Exception('Failed to get orders for user: $e');
    }
  }
}
