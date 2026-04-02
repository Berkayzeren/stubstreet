// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simple_message_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$simpleConversationMessagesHash() =>
    r'3e79324b24fbf872ab613e295ff459590a16b328';

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

/// Basit mesaj provider'ı - Sadece Firebase Firestore kullanır
/// Websocket olmadan, direkt real-time stream'ler
///
/// Copied from [simpleConversationMessages].
@ProviderFor(simpleConversationMessages)
const simpleConversationMessagesProvider = SimpleConversationMessagesFamily();

/// Basit mesaj provider'ı - Sadece Firebase Firestore kullanır
/// Websocket olmadan, direkt real-time stream'ler
///
/// Copied from [simpleConversationMessages].
class SimpleConversationMessagesFamily
    extends Family<AsyncValue<List<Message>>> {
  /// Basit mesaj provider'ı - Sadece Firebase Firestore kullanır
  /// Websocket olmadan, direkt real-time stream'ler
  ///
  /// Copied from [simpleConversationMessages].
  const SimpleConversationMessagesFamily();

  /// Basit mesaj provider'ı - Sadece Firebase Firestore kullanır
  /// Websocket olmadan, direkt real-time stream'ler
  ///
  /// Copied from [simpleConversationMessages].
  SimpleConversationMessagesProvider call(String conversationId) {
    return SimpleConversationMessagesProvider(conversationId);
  }

  @override
  SimpleConversationMessagesProvider getProviderOverride(
    covariant SimpleConversationMessagesProvider provider,
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
  String? get name => r'simpleConversationMessagesProvider';
}

/// Basit mesaj provider'ı - Sadece Firebase Firestore kullanır
/// Websocket olmadan, direkt real-time stream'ler
///
/// Copied from [simpleConversationMessages].
class SimpleConversationMessagesProvider
    extends AutoDisposeStreamProvider<List<Message>> {
  /// Basit mesaj provider'ı - Sadece Firebase Firestore kullanır
  /// Websocket olmadan, direkt real-time stream'ler
  ///
  /// Copied from [simpleConversationMessages].
  SimpleConversationMessagesProvider(String conversationId)
    : this._internal(
        (ref) => simpleConversationMessages(
          ref as SimpleConversationMessagesRef,
          conversationId,
        ),
        from: simpleConversationMessagesProvider,
        name: r'simpleConversationMessagesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$simpleConversationMessagesHash,
        dependencies: SimpleConversationMessagesFamily._dependencies,
        allTransitiveDependencies:
            SimpleConversationMessagesFamily._allTransitiveDependencies,
        conversationId: conversationId,
      );

  SimpleConversationMessagesProvider._internal(
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
    Stream<List<Message>> Function(SimpleConversationMessagesRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SimpleConversationMessagesProvider._internal(
        (ref) => create(ref as SimpleConversationMessagesRef),
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
  AutoDisposeStreamProviderElement<List<Message>> createElement() {
    return _SimpleConversationMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SimpleConversationMessagesProvider &&
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
mixin SimpleConversationMessagesRef
    on AutoDisposeStreamProviderRef<List<Message>> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _SimpleConversationMessagesProviderElement
    extends AutoDisposeStreamProviderElement<List<Message>>
    with SimpleConversationMessagesRef {
  _SimpleConversationMessagesProviderElement(super.provider);

  @override
  String get conversationId =>
      (origin as SimpleConversationMessagesProvider).conversationId;
}

String _$simpleUserConversationsHash() =>
    r'47f526e4b6ee4754bdcf9e762df001f6df1a3736';

/// Kullanıcının konuşmalarını getir
///
/// Copied from [simpleUserConversations].
@ProviderFor(simpleUserConversations)
const simpleUserConversationsProvider = SimpleUserConversationsFamily();

/// Kullanıcının konuşmalarını getir
///
/// Copied from [simpleUserConversations].
class SimpleUserConversationsFamily
    extends Family<AsyncValue<List<Conversation>>> {
  /// Kullanıcının konuşmalarını getir
  ///
  /// Copied from [simpleUserConversations].
  const SimpleUserConversationsFamily();

  /// Kullanıcının konuşmalarını getir
  ///
  /// Copied from [simpleUserConversations].
  SimpleUserConversationsProvider call(String userId) {
    return SimpleUserConversationsProvider(userId);
  }

  @override
  SimpleUserConversationsProvider getProviderOverride(
    covariant SimpleUserConversationsProvider provider,
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
  String? get name => r'simpleUserConversationsProvider';
}

/// Kullanıcının konuşmalarını getir
///
/// Copied from [simpleUserConversations].
class SimpleUserConversationsProvider
    extends AutoDisposeStreamProvider<List<Conversation>> {
  /// Kullanıcının konuşmalarını getir
  ///
  /// Copied from [simpleUserConversations].
  SimpleUserConversationsProvider(String userId)
    : this._internal(
        (ref) =>
            simpleUserConversations(ref as SimpleUserConversationsRef, userId),
        from: simpleUserConversationsProvider,
        name: r'simpleUserConversationsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$simpleUserConversationsHash,
        dependencies: SimpleUserConversationsFamily._dependencies,
        allTransitiveDependencies:
            SimpleUserConversationsFamily._allTransitiveDependencies,
        userId: userId,
      );

  SimpleUserConversationsProvider._internal(
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
  Override overrideWith(
    Stream<List<Conversation>> Function(SimpleUserConversationsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SimpleUserConversationsProvider._internal(
        (ref) => create(ref as SimpleUserConversationsRef),
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
  AutoDisposeStreamProviderElement<List<Conversation>> createElement() {
    return _SimpleUserConversationsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SimpleUserConversationsProvider && other.userId == userId;
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
mixin SimpleUserConversationsRef
    on AutoDisposeStreamProviderRef<List<Conversation>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _SimpleUserConversationsProviderElement
    extends AutoDisposeStreamProviderElement<List<Conversation>>
    with SimpleUserConversationsRef {
  _SimpleUserConversationsProviderElement(super.provider);

  @override
  String get userId => (origin as SimpleUserConversationsProvider).userId;
}

String _$simpleMessageSenderHash() =>
    r'4d7ea7912047e87e5701a9e9b074f7324f3910ea';

/// Basit mesaj gönderme provider'ı
///
/// Copied from [SimpleMessageSender].
@ProviderFor(SimpleMessageSender)
final simpleMessageSenderProvider =
    AutoDisposeNotifierProvider<SimpleMessageSender, AsyncValue<void>>.internal(
      SimpleMessageSender.new,
      name: r'simpleMessageSenderProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$simpleMessageSenderHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SimpleMessageSender = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
