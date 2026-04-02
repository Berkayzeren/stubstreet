// lib/features/orders/domain/repositories/order_repository.dart

import '../entities/order.dart';

abstract class OrderRepository {
  Future<Order> createOrder(Order order);
  Future<Order?> getOrderById(String orderId);
  Future<List<Order>> getUserOrders(String userId);
  Future<List<Order>> getSellerOrders(String sellerId);
  Future<void> updateOrderStatus(String orderId, OrderStatus status);
  Stream<List<Order>> watchUserOrders(String userId);
}