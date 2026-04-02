// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$paymentRepositoryHash() => r'861a5ee205fa64771adad1b9dd541b7b5c8ba31f';

/// See also [paymentRepository].
@ProviderFor(paymentRepository)
final paymentRepositoryProvider =
    AutoDisposeProvider<PaymentRepository>.internal(
      paymentRepository,
      name: r'paymentRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$paymentRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PaymentRepositoryRef = AutoDisposeProviderRef<PaymentRepository>;
String _$paymentByIntentIdHash() => r'ac3959e4de536131e8f2973f6c0f3752b3c7f40d';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [paymentByIntentId].
@ProviderFor(paymentByIntentId)
const paymentByIntentIdProvider = PaymentByIntentIdFamily();

/// See also [paymentByIntentId].
class PaymentByIntentIdFamily extends Family<AsyncValue<Payment?>> {
  /// See also [paymentByIntentId].
  const PaymentByIntentIdFamily();

  /// See also [paymentByIntentId].
  PaymentByIntentIdProvider call(String intentId) {
    return PaymentByIntentIdProvider(intentId);
  }

  @override
  PaymentByIntentIdProvider getProviderOverride(
    covariant PaymentByIntentIdProvider provider,
  ) {
    return call(provider.intentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'paymentByIntentIdProvider';
}

/// See also [paymentByIntentId].
class PaymentByIntentIdProvider extends AutoDisposeFutureProvider<Payment?> {
  /// See also [paymentByIntentId].
  PaymentByIntentIdProvider(String intentId)
    : this._internal(
        (ref) => paymentByIntentId(ref as PaymentByIntentIdRef, intentId),
        from: paymentByIntentIdProvider,
        name: r'paymentByIntentIdProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$paymentByIntentIdHash,
        dependencies: PaymentByIntentIdFamily._dependencies,
        allTransitiveDependencies:
            PaymentByIntentIdFamily._allTransitiveDependencies,
        intentId: intentId,
      );

  PaymentByIntentIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.intentId,
  }) : super.internal();

  final String intentId;

  @override
  Override overrideWith(
    FutureOr<Payment?> Function(PaymentByIntentIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PaymentByIntentIdProvider._internal(
        (ref) => create(ref as PaymentByIntentIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        intentId: intentId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Payment?> createElement() {
    return _PaymentByIntentIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PaymentByIntentIdProvider && other.intentId == intentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, intentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PaymentByIntentIdRef on AutoDisposeFutureProviderRef<Payment?> {
  /// The parameter `intentId` of this provider.
  String get intentId;
}

class _PaymentByIntentIdProviderElement
    extends AutoDisposeFutureProviderElement<Payment?>
    with PaymentByIntentIdRef {
  _PaymentByIntentIdProviderElement(super.provider);

  @override
  String get intentId => (origin as PaymentByIntentIdProvider).intentId;
}

String _$paymentStateHash() => r'7418d4c0e6139f0a17f472c46466f60db3667b3c';

abstract class _$PaymentState
    extends BuildlessAutoDisposeNotifier<AsyncValue<List<Payment>>> {
  late final String userId;

  AsyncValue<List<Payment>> build(String userId);
}

/// See also [PaymentState].
@ProviderFor(PaymentState)
const paymentStateProvider = PaymentStateFamily();

/// See also [PaymentState].
class PaymentStateFamily extends Family<AsyncValue<List<Payment>>> {
  /// See also [PaymentState].
  const PaymentStateFamily();

  /// See also [PaymentState].
  PaymentStateProvider call(String userId) {
    return PaymentStateProvider(userId);
  }

  @override
  PaymentStateProvider getProviderOverride(
    covariant PaymentStateProvider provider,
  ) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'paymentStateProvider';
}

/// See also [PaymentState].
class PaymentStateProvider
    extends
        AutoDisposeNotifierProviderImpl<
          PaymentState,
          AsyncValue<List<Payment>>
        > {
  /// See also [PaymentState].
  PaymentStateProvider(String userId)
    : this._internal(
        () => PaymentState()..userId = userId,
        from: paymentStateProvider,
        name: r'paymentStateProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$paymentStateHash,
        dependencies: PaymentStateFamily._dependencies,
        allTransitiveDependencies:
            PaymentStateFamily._allTransitiveDependencies,
        userId: userId,
      );

  PaymentStateProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  AsyncValue<List<Payment>> runNotifierBuild(covariant PaymentState notifier) {
    return notifier.build(userId);
  }

  @override
  Override overrideWith(PaymentState Function() create) {
    return ProviderOverride(
      origin: this,
      override: PaymentStateProvider._internal(
        () => create()..userId = userId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<PaymentState, AsyncValue<List<Payment>>>
  createElement() {
    return _PaymentStateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PaymentStateProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PaymentStateRef
    on AutoDisposeNotifierProviderRef<AsyncValue<List<Payment>>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _PaymentStateProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          PaymentState,
          AsyncValue<List<Payment>>
        >
    with PaymentStateRef {
  _PaymentStateProviderElement(super.provider);

  @override
  String get userId => (origin as PaymentStateProvider).userId;
}

String _$paymentIntentStateHash() =>
    r'f127bcf5a192e71f821f6c80b110ca9b1f8d68c3';

/// See also [PaymentIntentState].
@ProviderFor(PaymentIntentState)
final paymentIntentStateProvider =
    AutoDisposeNotifierProvider<
      PaymentIntentState,
      AsyncValue<String?>
    >.internal(
      PaymentIntentState.new,
      name: r'paymentIntentStateProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$paymentIntentStateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PaymentIntentState = AutoDisposeNotifier<AsyncValue<String?>>;
String _$paymentProcessingStateHash() =>
    r'17677ebdd2e0402268435a1bfb9904d56af069ba';

/// See also [PaymentProcessingState].
@ProviderFor(PaymentProcessingState)
final paymentProcessingStateProvider =
    AutoDisposeNotifierProvider<PaymentProcessingState, bool>.internal(
      PaymentProcessingState.new,
      name: r'paymentProcessingStateProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$paymentProcessingStateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PaymentProcessingState = AutoDisposeNotifier<bool>;
String _$paymentActionsHash() => r'5baa3a5ab235969a9d7e62b82ec5b80c926a5f5c';

/// See also [PaymentActions].
@ProviderFor(PaymentActions)
final paymentActionsProvider =
    AutoDisposeNotifierProvider<PaymentActions, void>.internal(
      PaymentActions.new,
      name: r'paymentActionsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$paymentActionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PaymentActions = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
