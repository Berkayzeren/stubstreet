// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'real_time_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$realTimeServiceHash() => r'f5227be00acd045702412d481373227f05fcf268';

/// See also [realTimeService].
@ProviderFor(realTimeService)
final realTimeServiceProvider =
    AutoDisposeProvider<FirebaseRealtimeService>.internal(
      realTimeService,
      name: r'realTimeServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$realTimeServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RealTimeServiceRef = AutoDisposeProviderRef<FirebaseRealtimeService>;
String _$connectionStatusHash() => r'182a647ddcd679e4504cec27fd08a3081931e0de';

/// See also [connectionStatus].
@ProviderFor(connectionStatus)
final connectionStatusProvider = AutoDisposeStreamProvider<bool>.internal(
  connectionStatus,
  name: r'connectionStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$connectionStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConnectionStatusRef = AutoDisposeStreamProviderRef<bool>;
String _$conversationMessagesHash() =>
    r'4fd3d0cce939174de619001624d307fa0e4e7677';

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

/// See also [conversationMessages].
@ProviderFor(conversationMessages)
const conversationMessagesProvider = ConversationMessagesFamily();

/// See also [conversationMessages].
class ConversationMessagesFamily extends Family<AsyncValue<List<msg.Message>>> {
  /// See also [conversationMessages].
  const ConversationMessagesFamily();

  /// See also [conversationMessages].
  ConversationMessagesProvider call(String conversationId) {
    return ConversationMessagesProvider(conversationId);
  }

  @override
  ConversationMessagesProvider getProviderOverride(
    covariant ConversationMessagesProvider provider,
  ) {
    return call(provider.conversationId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'conversationMessagesProvider';
}

/// See also [conversationMessages].
class ConversationMessagesProvider
    extends AutoDisposeStreamProvider<List<msg.Message>> {
  /// See also [conversationMessages].
  ConversationMessagesProvider(String conversationId)
    : this._internal(
        (ref) => conversationMessages(
          ref as ConversationMessagesRef,
          conversationId,
        ),
        from: conversationMessagesProvider,
        name: r'conversationMessagesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$conversationMessagesHash,
        dependencies: ConversationMessagesFamily._dependencies,
        allTransitiveDependencies:
            ConversationMessagesFamily._allTransitiveDependencies,
        conversationId: conversationId,
      );

  ConversationMessagesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
  }) : super.internal();

  final String conversationId;

  @override
  Override overrideWith(
    Stream<List<msg.Message>> Function(ConversationMessagesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ConversationMessagesProvider._internal(
        (ref) => create(ref as ConversationMessagesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<msg.Message>> createElement() {
    return _ConversationMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationMessagesProvider &&
        other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ConversationMessagesRef
    on AutoDisposeStreamProviderRef<List<msg.Message>> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _ConversationMessagesProviderElement
    extends AutoDisposeStreamProviderElement<List<msg.Message>>
    with ConversationMessagesRef {
  _ConversationMessagesProviderElement(super.provider);

  @override
  String get conversationId =>
      (origin as ConversationMessagesProvider).conversationId;
}

String _$orderUpdatesHash() => r'a2e36bd8b29880084e559d06aa448490f69876c3';

/// See also [orderUpdates].
@ProviderFor(orderUpdates)
const orderUpdatesProvider = OrderUpdatesFamily();

/// See also [orderUpdates].
class OrderUpdatesFamily extends Family<AsyncValue<order_entity.Order?>> {
  /// See also [orderUpdates].
  const OrderUpdatesFamily();

  /// See also [orderUpdates].
  OrderUpdatesProvider call(String orderId) {
    return OrderUpdatesProvider(orderId);
  }

  @override
  OrderUpdatesProvider getProviderOverride(
    covariant OrderUpdatesProvider provider,
  ) {
    return call(provider.orderId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'orderUpdatesProvider';
}

/// See also [orderUpdates].
class OrderUpdatesProvider
    extends AutoDisposeStreamProvider<order_entity.Order?> {
  /// See also [orderUpdates].
  OrderUpdatesProvider(String orderId)
    : this._internal(
        (ref) => orderUpdates(ref as OrderUpdatesRef, orderId),
        from: orderUpdatesProvider,
        name: r'orderUpdatesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$orderUpdatesHash,
        dependencies: OrderUpdatesFamily._dependencies,
        allTransitiveDependencies:
            OrderUpdatesFamily._allTransitiveDependencies,
        orderId: orderId,
      );

  OrderUpdatesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.orderId,
  }) : super.internal();

  final String orderId;

  @override
  Override overrideWith(
    Stream<order_entity.Order?> Function(OrderUpdatesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: OrderUpdatesProvider._internal(
        (ref) => create(ref as OrderUpdatesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        orderId: orderId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<order_entity.Order?> createElement() {
    return _OrderUpdatesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OrderUpdatesProvider && other.orderId == orderId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, orderId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin OrderUpdatesRef on AutoDisposeStreamProviderRef<order_entity.Order?> {
  /// The parameter `orderId` of this provider.
  String get orderId;
}

class _OrderUpdatesProviderElement
    extends AutoDisposeStreamProviderElement<order_entity.Order?>
    with OrderUpdatesRef {
  _OrderUpdatesProviderElement(super.provider);

  @override
  String get orderId => (origin as OrderUpdatesProvider).orderId;
}

String _$typingIndicatorHash() => r'a3f6c95587a369a3b880f4a1140e133cb053b7b5';

/// See also [TypingIndicator].
@ProviderFor(TypingIndicator)
final typingIndicatorProvider =
    AutoDisposeNotifierProvider<TypingIndicator, Map<String, bool>>.internal(
      TypingIndicator.new,
      name: r'typingIndicatorProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$typingIndicatorHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TypingIndicator = AutoDisposeNotifier<Map<String, bool>>;
String _$messageSenderHash() => r'7f8c3469b196cbd8bbc78e3130929c51de4caa95';

/// See also [MessageSender].
@ProviderFor(MessageSender)
final messageSenderProvider =
    AutoDisposeNotifierProvider<MessageSender, AsyncValue<void>>.internal(
      MessageSender.new,
      name: r'messageSenderProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$messageSenderHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MessageSender = AutoDisposeNotifier<AsyncValue<void>>;
String _$orderStatusUpdaterHash() =>
    r'6e34c91bb888a49ea8382266b7aa9edb8dc4f4fa';

/// See also [OrderStatusUpdater].
@ProviderFor(OrderStatusUpdater)
final orderStatusUpdaterProvider =
    AutoDisposeNotifierProvider<OrderStatusUpdater, AsyncValue<void>>.internal(
      OrderStatusUpdater.new,
      name: r'orderStatusUpdaterProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$orderStatusUpdaterHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$OrderStatusUpdater = AutoDisposeNotifier<AsyncValue<void>>;
String _$connectionIndicatorHash() =>
    r'449c76619a424413726105c54669d79d2993b4a0';

/// See also [ConnectionIndicator].
@ProviderFor(ConnectionIndicator)
final connectionIndicatorProvider =
    AutoDisposeNotifierProvider<ConnectionIndicator, String>.internal(
      ConnectionIndicator.new,
      name: r'connectionIndicatorProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$connectionIndicatorHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ConnectionIndicator = AutoDisposeNotifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
