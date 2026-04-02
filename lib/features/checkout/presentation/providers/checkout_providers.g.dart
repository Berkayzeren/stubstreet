// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firestoreHash() => r'0e25e335c5657f593fc1baf3d9fd026e70bca7fa';

/// See also [firestore].
@ProviderFor(firestore)
final firestoreProvider = AutoDisposeProvider<FirebaseFirestore>.internal(
  firestore,
  name: r'firestoreProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$firestoreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirestoreRef = AutoDisposeProviderRef<FirebaseFirestore>;
String _$ticketLockServiceHash() => r'7a0af67ce9cb1b3b8b426dae3f2a6e3a3bc7b160';

/// See also [ticketLockService].
@ProviderFor(ticketLockService)
final ticketLockServiceProvider =
    AutoDisposeProvider<TicketLockService>.internal(
      ticketLockService,
      name: r'ticketLockServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$ticketLockServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TicketLockServiceRef = AutoDisposeProviderRef<TicketLockService>;
String _$orderServiceHash() => r'3a84234c7fcecfc3480434e8b50dd1594d2d679b';

/// See also [orderService].
@ProviderFor(orderService)
final orderServiceProvider = AutoDisposeProvider<OrderService>.internal(
  orderService,
  name: r'orderServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$orderServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OrderServiceRef = AutoDisposeProviderRef<OrderService>;
String _$authorizationServiceHash() =>
    r'b947dc829872aa0c8ec6cd3fb26889ab58b3ea22';

/// See also [authorizationService].
@ProviderFor(authorizationService)
final authorizationServiceProvider =
    AutoDisposeProvider<AuthorizationService>.internal(
      authorizationService,
      name: r'authorizationServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$authorizationServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthorizationServiceRef = AutoDisposeProviderRef<AuthorizationService>;
String _$checkoutServiceHash() => r'64cad928aa9ecdc79792155fe6039cf608e2ad6e';

/// See also [checkoutService].
@ProviderFor(checkoutService)
final checkoutServiceProvider = AutoDisposeProvider<CheckoutService>.internal(
  checkoutService,
  name: r'checkoutServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$checkoutServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CheckoutServiceRef = AutoDisposeProviderRef<CheckoutService>;
String _$checkoutStateHash() => r'df6a7f7ddd8c45011abbe87b8c794601fe55c8b0';

/// See also [CheckoutState].
@ProviderFor(CheckoutState)
final checkoutStateProvider =
    AutoDisposeNotifierProvider<CheckoutState, AsyncValue<String?>>.internal(
      CheckoutState.new,
      name: r'checkoutStateProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$checkoutStateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CheckoutState = AutoDisposeNotifier<AsyncValue<String?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
