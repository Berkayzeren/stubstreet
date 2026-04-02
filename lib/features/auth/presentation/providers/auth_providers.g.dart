// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firebaseAuthHash() => r'912368c3df3f72e4295bf7a8cda93b9c5749d923';

/// See also [firebaseAuth].
@ProviderFor(firebaseAuth)
final firebaseAuthProvider = AutoDisposeProvider<FirebaseAuth>.internal(
  firebaseAuth,
  name: r'firebaseAuthProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$firebaseAuthHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirebaseAuthRef = AutoDisposeProviderRef<FirebaseAuth>;
String _$authRepositoryHash() => r'3a723e34e8f0950a5e5ba88000eacf0b61082153';

/// See also [authRepository].
@ProviderFor(authRepository)
final authRepositoryProvider = AutoDisposeProvider<AuthRepository>.internal(
  authRepository,
  name: r'authRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthRepositoryRef = AutoDisposeProviderRef<AuthRepository>;
String _$authStateChangesHash() => r'187b9d525130c19a336891007b84a5e1b94abae0';

/// See also [authStateChanges].
@ProviderFor(authStateChanges)
final authStateChangesProvider =
    AutoDisposeStreamProvider<domain_user.User?>.internal(
      authStateChanges,
      name: r'authStateChangesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$authStateChangesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthStateChangesRef = AutoDisposeStreamProviderRef<domain_user.User?>;
String _$currentUserHash() => r'59a37cdd0de60154cecaf07d36979eee2b878ff6';

/// See also [currentUser].
@ProviderFor(currentUser)
final currentUserProvider =
    AutoDisposeFutureProvider<domain_user.User?>.internal(
      currentUser,
      name: r'currentUserProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentUserHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserRef = AutoDisposeFutureProviderRef<domain_user.User?>;
String _$userProfileHash() => r'7fdebb70e2d1e757a410097d8cbac6b44f2e9a6f';

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

/// See also [userProfile].
@ProviderFor(userProfile)
const userProfileProvider = UserProfileFamily();

/// See also [userProfile].
class UserProfileFamily extends Family<AsyncValue<UserProfile>> {
  /// See also [userProfile].
  const UserProfileFamily();

  /// See also [userProfile].
  UserProfileProvider call(String userId) {
    return UserProfileProvider(userId);
  }

  @override
  UserProfileProvider getProviderOverride(
    covariant UserProfileProvider provider,
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
  String? get name => r'userProfileProvider';
}

/// See also [userProfile].
class UserProfileProvider extends AutoDisposeFutureProvider<UserProfile> {
  /// See also [userProfile].
  UserProfileProvider(String userId)
    : this._internal(
        (ref) => userProfile(ref as UserProfileRef, userId),
        from: userProfileProvider,
        name: r'userProfileProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$userProfileHash,
        dependencies: UserProfileFamily._dependencies,
        allTransitiveDependencies: UserProfileFamily._allTransitiveDependencies,
        userId: userId,
      );

  UserProfileProvider._internal(
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
    FutureOr<UserProfile> Function(UserProfileRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserProfileProvider._internal(
        (ref) => create(ref as UserProfileRef),
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
  AutoDisposeFutureProviderElement<UserProfile> createElement() {
    return _UserProfileProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserProfileProvider && other.userId == userId;
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
mixin UserProfileRef on AutoDisposeFutureProviderRef<UserProfile> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserProfileProviderElement
    extends AutoDisposeFutureProviderElement<UserProfile>
    with UserProfileRef {
  _UserProfileProviderElement(super.provider);

  @override
  String get userId => (origin as UserProfileProvider).userId;
}

String _$signInNotifierHash() => r'62adc454bac8631a50975881a93e5178fcd88841';

/// See also [SignInNotifier].
@ProviderFor(SignInNotifier)
final signInNotifierProvider =
    AutoDisposeNotifierProvider<
      SignInNotifier,
      AsyncValue<domain_user.User?>
    >.internal(
      SignInNotifier.new,
      name: r'signInNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$signInNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SignInNotifier = AutoDisposeNotifier<AsyncValue<domain_user.User?>>;
String _$signUpNotifierHash() => r'0e2766320633e1d7530ba98e542fa1555a100844';

/// See also [SignUpNotifier].
@ProviderFor(SignUpNotifier)
final signUpNotifierProvider =
    AutoDisposeNotifierProvider<
      SignUpNotifier,
      AsyncValue<domain_user.User?>
    >.internal(
      SignUpNotifier.new,
      name: r'signUpNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$signUpNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SignUpNotifier = AutoDisposeNotifier<AsyncValue<domain_user.User?>>;
String _$profileUpdateNotifierHash() =>
    r'1e98a27e577046d0c8d1ae1a34345f61c38e539c';

/// See also [ProfileUpdateNotifier].
@ProviderFor(ProfileUpdateNotifier)
final profileUpdateNotifierProvider =
    AutoDisposeNotifierProvider<
      ProfileUpdateNotifier,
      AsyncValue<void>
    >.internal(
      ProfileUpdateNotifier.new,
      name: r'profileUpdateNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$profileUpdateNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ProfileUpdateNotifier = AutoDisposeNotifier<AsyncValue<void>>;
String _$reviewSubmissionNotifierHash() =>
    r'c9a16c00e42ea7f7b089f7a2264f46b1019d094b';

/// See also [ReviewSubmissionNotifier].
@ProviderFor(ReviewSubmissionNotifier)
final reviewSubmissionNotifierProvider =
    AutoDisposeNotifierProvider<
      ReviewSubmissionNotifier,
      AsyncValue<void>
    >.internal(
      ReviewSubmissionNotifier.new,
      name: r'reviewSubmissionNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$reviewSubmissionNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ReviewSubmissionNotifier = AutoDisposeNotifier<AsyncValue<void>>;
String _$usernameAvailabilityNotifierHash() =>
    r'a2fd43d018dd7517518653f325e9c74dee16b399';

/// See also [UsernameAvailabilityNotifier].
@ProviderFor(UsernameAvailabilityNotifier)
final usernameAvailabilityNotifierProvider =
    AutoDisposeNotifierProvider<
      UsernameAvailabilityNotifier,
      AsyncValue<bool?>
    >.internal(
      UsernameAvailabilityNotifier.new,
      name: r'usernameAvailabilityNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$usernameAvailabilityNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$UsernameAvailabilityNotifier = AutoDisposeNotifier<AsyncValue<bool?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
