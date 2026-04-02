// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'typing_indicator_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$typingUsersHash() => r'80377c0d2ce9760ff5c43705abb452f66c611386';

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

/// Provider to get typing users for a specific conversation
///
/// Copied from [typingUsers].
@ProviderFor(typingUsers)
const typingUsersProvider = TypingUsersFamily();

/// Provider to get typing users for a specific conversation
///
/// Copied from [typingUsers].
class TypingUsersFamily extends Family<Map<String, bool>> {
  /// Provider to get typing users for a specific conversation
  ///
  /// Copied from [typingUsers].
  const TypingUsersFamily();

  /// Provider to get typing users for a specific conversation
  ///
  /// Copied from [typingUsers].
  TypingUsersProvider call(String conversationId) {
    return TypingUsersProvider(conversationId);
  }

  @override
  TypingUsersProvider getProviderOverride(
    covariant TypingUsersProvider provider,
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
  String? get name => r'typingUsersProvider';
}

/// Provider to get typing users for a specific conversation
///
/// Copied from [typingUsers].
class TypingUsersProvider extends AutoDisposeProvider<Map<String, bool>> {
  /// Provider to get typing users for a specific conversation
  ///
  /// Copied from [typingUsers].
  TypingUsersProvider(String conversationId)
    : this._internal(
        (ref) => typingUsers(ref as TypingUsersRef, conversationId),
        from: typingUsersProvider,
        name: r'typingUsersProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$typingUsersHash,
        dependencies: TypingUsersFamily._dependencies,
        allTransitiveDependencies: TypingUsersFamily._allTransitiveDependencies,
        conversationId: conversationId,
      );

  TypingUsersProvider._internal(
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
    Map<String, bool> Function(TypingUsersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TypingUsersProvider._internal(
        (ref) => create(ref as TypingUsersRef),
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
  AutoDisposeProviderElement<Map<String, bool>> createElement() {
    return _TypingUsersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TypingUsersProvider &&
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
mixin TypingUsersRef on AutoDisposeProviderRef<Map<String, bool>> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _TypingUsersProviderElement
    extends AutoDisposeProviderElement<Map<String, bool>>
    with TypingUsersRef {
  _TypingUsersProviderElement(super.provider);

  @override
  String get conversationId => (origin as TypingUsersProvider).conversationId;
}

String _$typingIndicatorHash() => r'36add9f006478e24c6c3bc420916bc32a5d07e15';

/// Typing indicator provider that manages real-time typing status
///
/// This provider handles:
/// - Starting and stopping typing indicators
/// - Real-time synchronization across devices
/// - Automatic timeout for stuck typing indicators
/// - Multiple user typing status in conversations
/// - Memory cleanup and optimization
///
/// Copied from [TypingIndicator].
@ProviderFor(TypingIndicator)
final typingIndicatorProvider =
    AutoDisposeNotifierProvider<
      TypingIndicator,
      Map<String, Map<String, bool>>
    >.internal(
      TypingIndicator.new,
      name: r'typingIndicatorProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$typingIndicatorHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TypingIndicator = AutoDisposeNotifier<Map<String, Map<String, bool>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
