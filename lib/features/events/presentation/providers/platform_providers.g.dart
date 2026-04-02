// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$stubhubServiceHash() => r'f165195ded732dba047ce68dcc1a3bc1502d7e00';

/// StubHub Service Provider
/// Creates and configures a StubHub service instance with the API key from environment variables
/// @param ref: Riverpod reference for dependency injection
/// @returns: Configured StubHubService instance for accessing StubHub's ticket marketplace
///
/// Copied from [stubhubService].
@ProviderFor(stubhubService)
final stubhubServiceProvider = AutoDisposeProvider<StubHubService>.internal(
  stubhubService,
  name: r'stubhubServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$stubhubServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StubhubServiceRef = AutoDisposeProviderRef<StubHubService>;
String _$seatgeekServiceHash() => r'7db960104725468f2cd0d70956ca97eab4aa2a73';

/// SeatGeek Service Provider
/// Creates and configures a SeatGeek service instance with the client ID from environment variables
/// @param ref: Riverpod reference for dependency injection
/// @returns: Configured SeatGeekService instance for accessing SeatGeek's event discovery API
///
/// Copied from [seatgeekService].
@ProviderFor(seatgeekService)
final seatgeekServiceProvider = AutoDisposeProvider<SeatGeekService>.internal(
  seatgeekService,
  name: r'seatgeekServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$seatgeekServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SeatgeekServiceRef = AutoDisposeProviderRef<SeatGeekService>;
String _$ticketmasterServiceHash() =>
    r'6611f9d9d130634723446c7bd58018103bb97c45';

/// Ticketmaster Service Provider
///
/// Copied from [ticketmasterService].
@ProviderFor(ticketmasterService)
final ticketmasterServiceProvider =
    AutoDisposeProvider<TicketmasterService>.internal(
      ticketmasterService,
      name: r'ticketmasterServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$ticketmasterServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TicketmasterServiceRef = AutoDisposeProviderRef<TicketmasterService>;
String _$platformManagerHash() => r'fac366c4a2fdbae5656ea55d1f7e75bf4538562e';

/// Platform Manager Provider - Hybrid service manager
/// Coordinates multiple ticket platform services (StubHub, SeatGeek) into a unified interface
/// This allows the app to search across all platforms simultaneously and aggregate results
/// @param ref: Riverpod reference for dependency injection to access individual platform services
/// @returns: Configured PlatformManager instance that orchestrates all ticket platforms
///
/// Copied from [platformManager].
@ProviderFor(platformManager)
final platformManagerProvider = AutoDisposeProvider<PlatformManager>.internal(
  platformManager,
  name: r'platformManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$platformManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlatformManagerRef = AutoDisposeProviderRef<PlatformManager>;
String _$hybridEventsHash() => r'c5eb8e250a77453ea2bd2cd6302afd13af200caa';

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

/// Hybrid Events Provider - Unified events from all platforms
/// Fetches and combines events from all available ticket platforms (StubHub, SeatGeek)
/// This provides a comprehensive search across the entire ticket marketplace ecosystem
/// @param ref: Riverpod reference for dependency injection
/// @param query: Optional search query to filter events by name/description
/// @param location: Optional location filter to find events in specific areas
/// @param limit: Maximum number of events to return (default: 24 for optimal performance)
/// @returns: List of UnifiedEvent objects aggregated from all platforms
///
/// Copied from [hybridEvents].
@ProviderFor(hybridEvents)
const hybridEventsProvider = HybridEventsFamily();

/// Hybrid Events Provider - Unified events from all platforms
/// Fetches and combines events from all available ticket platforms (StubHub, SeatGeek)
/// This provides a comprehensive search across the entire ticket marketplace ecosystem
/// @param ref: Riverpod reference for dependency injection
/// @param query: Optional search query to filter events by name/description
/// @param location: Optional location filter to find events in specific areas
/// @param limit: Maximum number of events to return (default: 24 for optimal performance)
/// @returns: List of UnifiedEvent objects aggregated from all platforms
///
/// Copied from [hybridEvents].
class HybridEventsFamily extends Family<AsyncValue<List<UnifiedEvent>>> {
  /// Hybrid Events Provider - Unified events from all platforms
  /// Fetches and combines events from all available ticket platforms (StubHub, SeatGeek)
  /// This provides a comprehensive search across the entire ticket marketplace ecosystem
  /// @param ref: Riverpod reference for dependency injection
  /// @param query: Optional search query to filter events by name/description
  /// @param location: Optional location filter to find events in specific areas
  /// @param limit: Maximum number of events to return (default: 24 for optimal performance)
  /// @returns: List of UnifiedEvent objects aggregated from all platforms
  ///
  /// Copied from [hybridEvents].
  const HybridEventsFamily();

  /// Hybrid Events Provider - Unified events from all platforms
  /// Fetches and combines events from all available ticket platforms (StubHub, SeatGeek)
  /// This provides a comprehensive search across the entire ticket marketplace ecosystem
  /// @param ref: Riverpod reference for dependency injection
  /// @param query: Optional search query to filter events by name/description
  /// @param location: Optional location filter to find events in specific areas
  /// @param limit: Maximum number of events to return (default: 24 for optimal performance)
  /// @returns: List of UnifiedEvent objects aggregated from all platforms
  ///
  /// Copied from [hybridEvents].
  HybridEventsProvider call({String? query, String? location, int limit = 24}) {
    return HybridEventsProvider(query: query, location: location, limit: limit);
  }

  @override
  HybridEventsProvider getProviderOverride(
    covariant HybridEventsProvider provider,
  ) {
    return call(
      query: provider.query,
      location: provider.location,
      limit: provider.limit,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'hybridEventsProvider';
}

/// Hybrid Events Provider - Unified events from all platforms
/// Fetches and combines events from all available ticket platforms (StubHub, SeatGeek)
/// This provides a comprehensive search across the entire ticket marketplace ecosystem
/// @param ref: Riverpod reference for dependency injection
/// @param query: Optional search query to filter events by name/description
/// @param location: Optional location filter to find events in specific areas
/// @param limit: Maximum number of events to return (default: 24 for optimal performance)
/// @returns: List of UnifiedEvent objects aggregated from all platforms
///
/// Copied from [hybridEvents].
class HybridEventsProvider
    extends AutoDisposeFutureProvider<List<UnifiedEvent>> {
  /// Hybrid Events Provider - Unified events from all platforms
  /// Fetches and combines events from all available ticket platforms (StubHub, SeatGeek)
  /// This provides a comprehensive search across the entire ticket marketplace ecosystem
  /// @param ref: Riverpod reference for dependency injection
  /// @param query: Optional search query to filter events by name/description
  /// @param location: Optional location filter to find events in specific areas
  /// @param limit: Maximum number of events to return (default: 24 for optimal performance)
  /// @returns: List of UnifiedEvent objects aggregated from all platforms
  ///
  /// Copied from [hybridEvents].
  HybridEventsProvider({String? query, String? location, int limit = 24})
    : this._internal(
        (ref) => hybridEvents(
          ref as HybridEventsRef,
          query: query,
          location: location,
          limit: limit,
        ),
        from: hybridEventsProvider,
        name: r'hybridEventsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$hybridEventsHash,
        dependencies: HybridEventsFamily._dependencies,
        allTransitiveDependencies:
            HybridEventsFamily._allTransitiveDependencies,
        query: query,
        location: location,
        limit: limit,
      );

  HybridEventsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
    required this.location,
    required this.limit,
  }) : super.internal();

  final String? query;
  final String? location;
  final int limit;

  @override
  Override overrideWith(
    FutureOr<List<UnifiedEvent>> Function(HybridEventsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HybridEventsProvider._internal(
        (ref) => create(ref as HybridEventsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
        location: location,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<UnifiedEvent>> createElement() {
    return _HybridEventsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HybridEventsProvider &&
        other.query == query &&
        other.location == location &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);
    hash = _SystemHash.combine(hash, location.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HybridEventsRef on AutoDisposeFutureProviderRef<List<UnifiedEvent>> {
  /// The parameter `query` of this provider.
  String? get query;

  /// The parameter `location` of this provider.
  String? get location;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _HybridEventsProviderElement
    extends AutoDisposeFutureProviderElement<List<UnifiedEvent>>
    with HybridEventsRef {
  _HybridEventsProviderElement(super.provider);

  @override
  String? get query => (origin as HybridEventsProvider).query;
  @override
  String? get location => (origin as HybridEventsProvider).location;
  @override
  int get limit => (origin as HybridEventsProvider).limit;
}

String _$stubhubMarketplaceHash() =>
    r'125853fc02e3484d764a4b5e9c84ff390afa8f73';

/// StubHub Marketplace Provider - Bilet listeleme işlemleri
///
/// Copied from [StubhubMarketplace].
@ProviderFor(StubhubMarketplace)
final stubhubMarketplaceProvider =
    AutoDisposeNotifierProvider<
      StubhubMarketplace,
      AsyncValue<String?>
    >.internal(
      StubhubMarketplace.new,
      name: r'stubhubMarketplaceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$stubhubMarketplaceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StubhubMarketplace = AutoDisposeNotifier<AsyncValue<String?>>;
String _$platformStatsHash() => r'815628c8dd67ecf971127e0f1ef7e369e5c56a2d';

/// Platform Statistics Provider - Platform performans metrikleri
///
/// Copied from [PlatformStats].
@ProviderFor(PlatformStats)
final platformStatsProvider =
    AutoDisposeNotifierProvider<PlatformStats, Map<String, dynamic>>.internal(
      PlatformStats.new,
      name: r'platformStatsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$platformStatsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PlatformStats = AutoDisposeNotifier<Map<String, dynamic>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
