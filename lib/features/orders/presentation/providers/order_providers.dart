// lib/features/orders/presentation/providers/order_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../domain/entities/order.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../domain/repositories/order_repository.dart';

// Repository provider
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(FirebaseFirestore.instance);
});

// Order detail provider
final orderDetailProvider = FutureProvider.family<Order?, String>((ref, orderId) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getOrderById(orderId);
});

// User orders provider
final userOrdersProvider = FutureProvider.family<List<Order>, String>((ref, userId) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getUserOrders(userId);
});

// Seller orders provider
final sellerOrdersProvider = FutureProvider.family<List<Order>, String>((ref, sellerId) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getSellerOrders(sellerId);
});

// Stream provider for real-time orders
final userOrdersStreamProvider = StreamProvider.family<List<Order>, String>((ref, userId) {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.watchUserOrders(userId);
});
