// lib/features/payments/presentation/providers/payment_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stubstreet/features/auth/domain/entities/user.dart';
import 'package:stubstreet/features/orders/domain/entities/order.dart';
import 'package:stubstreet/features/payments/domain/entities/payment.dart';
import 'package:stubstreet/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:stubstreet/features/payments/domain/repositories/payment_repository.dart';

part 'payment_providers.g.dart';

// Services

@riverpod
PaymentRepository paymentRepository(Ref ref) {
  return PaymentRepositoryImpl();
}


// State providers
@riverpod
class PaymentState extends _$PaymentState {
  @override
  AsyncValue<List<Payment>> build(String userId) {
    return const AsyncValue.loading();
  }

  /// Load user payments
  Future<void> loadUserPayments(String userId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(paymentRepositoryProvider);
      final payments = await repository.getUserPayments(userId);
      state = AsyncValue.data(payments);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresh payments
  Future<void> refresh(String userId) async {
    await loadUserPayments(userId);
  }
}

@riverpod
class PaymentIntentState extends _$PaymentIntentState {
  @override
  AsyncValue<String?> build() {
    return const AsyncValue.data(null);
  }

  /// Create payment intent for order
  Future<String?> createPaymentIntent({
    required Order order,
    required User buyer,
    required User seller,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(paymentRepositoryProvider);
      final clientSecret = await repository.createPaymentIntent(
        order: order,
        buyer: buyer,
        seller: seller,
      );
      state = AsyncValue.data(clientSecret);
      return clientSecret;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

@riverpod
class PaymentProcessingState extends _$PaymentProcessingState {
  @override
  bool build() {
    return false;
  }

  /// Set processing state
  void setProcessing(bool isProcessing) {
    state = isProcessing;
  }
}

// Specific payment provider
@riverpod
Future<Payment?> paymentByIntentId(
  Ref ref,
  String intentId,
) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getPaymentByIntentId(intentId);
}

// Payment actions
@riverpod
class PaymentActions extends _$PaymentActions {
  @override
  void build() {
    // No initial state needed
  }

  /// Cancel a payment
  Future<bool> cancelPayment(String paymentId) async {
    try {
      final repository = ref.read(paymentRepositoryProvider);
      await repository.cancelPayment(paymentId);
      return true;
    } catch (error) {
      // Log error or show notification
      return false;
    }
  }

  /// Process webhook event
  Future<bool> processWebhookEvent({
    required String eventType,
    required Map<String, dynamic> eventData,
  }) async {
    try {
      final repository = ref.read(paymentRepositoryProvider);
      await repository.handleWebhookEvent(
        eventType: eventType,
        eventData: eventData,
      );
      return true;
    } catch (error) {
      // Log error
      return false;
    }
  }

  /// Refresh user payments after payment completion
  Future<void> refreshUserPayments(String userId) async {
    ref.read(paymentStateProvider(userId).notifier).refresh(userId);
  }
}
