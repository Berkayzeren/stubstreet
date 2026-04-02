// lib/features/orders/data/repositories/order_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/foundation.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final FirebaseFirestore _firestore;

  OrderRepositoryImpl(this._firestore);

  CollectionReference get _ordersCollection => _firestore.collection('orders');

  @override
  Future<Order> createOrder(Order order) async {
    try {
      final docRef = await _ordersCollection.add(order.toFirestore());
      final createdOrder = order.copyWith(id: docRef.id);
      
      debugPrint('✅ Order created successfully: ${docRef.id}');
      return createdOrder;
    } catch (e) {
      debugPrint('❌ Error creating order: $e');
      rethrow;
    }
  }

  @override
  Future<Order?> getOrderById(String orderId) async {
    try {
      final doc = await _ordersCollection.doc(orderId).get();
      
      if (!doc.exists) {
        debugPrint('⚠️ Order not found: $orderId');
        return null;
      }
      
      return Order.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ Error fetching order: $e');
      rethrow;
    }
  }

  @override
  Future<List<Order>> getUserOrders(String userId) async {
    try {
      final snapshot = await _ordersCollection
          .where('buyerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ Error fetching user orders: $e');
      rethrow;
    }
  }

  @override
  Future<List<Order>> getSellerOrders(String sellerId) async {
    try {
      final snapshot = await _ordersCollection
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ Error fetching seller orders: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _ordersCollection.doc(orderId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Order status updated: $orderId -> ${status.name}');
    } catch (e) {
      debugPrint('❌ Error updating order status: $e');
      rethrow;
    }
  }

  @override
  Stream<List<Order>> watchUserOrders(String userId) {
    return _ordersCollection
        .where('buyerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList());
  }
}
