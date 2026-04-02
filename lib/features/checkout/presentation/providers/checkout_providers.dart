// lib/features/checkout/presentation/providers/checkout_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/checkout_service.dart';
import '../../../tickets/data/services/ticket_lock_service.dart';
import '../../../orders/data/services/order_service.dart';
import '../../../../core/services/authorization_service.dart';

part 'checkout_providers.g.dart';

// Firebase Firestore provider
@riverpod
FirebaseFirestore firestore(Ref ref) {
  return FirebaseFirestore.instance;
}

// Service providers
@riverpod
TicketLockService ticketLockService(Ref ref) {
  final firestore = ref.watch(firestoreProvider);
  return TicketLockService(firestore);
}

@riverpod
OrderService orderService(Ref ref) {
  final firestore = ref.watch(firestoreProvider);
  return OrderService(firestore);
}


@riverpod
AuthorizationService authorizationService(Ref ref) {
  final firestore = ref.watch(firestoreProvider);
  return AuthorizationService(firestore);
}

// Main checkout service provider
@riverpod
CheckoutService checkoutService(Ref ref) {
  final firestore = ref.watch(firestoreProvider);
  // final ticketLockService = ref.watch(ticketLockServiceProvider);
  // final authorizationService = ref.watch(authorizationServiceProvider);

  return CheckoutService(
    firestore,
    // ticketLockService,
    // authorizationService,
  );
}

// State providers for checkout flow
@riverpod
class CheckoutState extends _$CheckoutState {
  @override
  AsyncValue<String?> build() {
    return const AsyncValue.data(null);
  }

  Future<void> initiateCheckout({
    required String ticketId,
    required String buyerId,
    required String paymentMethod,
    String? promoCode,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Implementation will be added when needed
      state = const AsyncValue.data('checkout_session_id');
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}
