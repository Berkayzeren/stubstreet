// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorites_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$favoriteTicketsHash() => r'3108186da3f04267898692ecbaa0b5932724cfc3';

/// Favorite Tickets Provider - Retrieves user's favorite tickets
/// Fetches the complete ticket details for all tickets marked as favorites by the current user
/// This provider combines the user's favorite ticket IDs with the actual ticket data from Firestore
/// @param ref: Riverpod reference for dependency injection to access favorites and Firestore
/// @returns: List of complete Ticket objects that the user has marked as favorites
///
/// Copied from [favoriteTickets].
@ProviderFor(favoriteTickets)
final favoriteTicketsProvider =
    AutoDisposeFutureProvider<List<Ticket>>.internal(
      favoriteTickets,
      name: r'favoriteTicketsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$favoriteTicketsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FavoriteTicketsRef = AutoDisposeFutureProviderRef<List<Ticket>>;
String _$favoritesNotifierHash() => r'c880e91e08e908594e925e5d20640fa9911f1caf';

/// Favori biletleri yöneten provider
///
/// Copied from [FavoritesNotifier].
@ProviderFor(FavoritesNotifier)
final favoritesNotifierProvider =
    AutoDisposeAsyncNotifierProvider<FavoritesNotifier, Set<String>>.internal(
      FavoritesNotifier.new,
      name: r'favoritesNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$favoritesNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FavoritesNotifier = AutoDisposeAsyncNotifier<Set<String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
