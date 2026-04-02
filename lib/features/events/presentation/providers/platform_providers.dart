// lib/features/events/presentation/providers/platform_providers.dart

import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/services/platform_manager.dart';
import '../../../../core/services/stubhub_service.dart';
import '../../../../core/services/seatgeek_service_simple.dart';
import '../../../../core/services/ticketmaster_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

part 'platform_providers.g.dart';

/// StubHub Service Provider
/// Creates and configures a StubHub service instance with the API key from environment variables
/// @param ref: Riverpod reference for dependency injection
/// @returns: Configured StubHubService instance for accessing StubHub's ticket marketplace
@riverpod
StubHubService stubhubService(Ref ref) {
  // Gerçek implementasyonda StubHub API key'i environment'dan alınacak
  // StubHub devre dışı: provider yine de döner ancak kullanılmayacak
  const apiKey = 'disabled_stubhub';
  return StubHubServiceImpl(apiKey: apiKey);
}

/// SeatGeek Service Provider
/// Creates and configures a SeatGeek service instance with the client ID from environment variables
/// @param ref: Riverpod reference for dependency injection
/// @returns: Configured SeatGeekService instance for accessing SeatGeek's event discovery API
@riverpod
SeatGeekService seatgeekService(Ref ref) {
  // Gerçek implementasyonda SeatGeek client ID environment'dan alınacak
  final clientId = dotenv.env['SEATGEEK_CLIENT_ID'] ?? '';
  return SeatGeekServiceSimple(clientId: clientId);
}

/// Ticketmaster Service Provider
@riverpod
TicketmasterService ticketmasterService(Ref ref) {
  final apiKey = dotenv.env['TICKETMASTER_API_KEY'] ?? '';
  return TicketmasterServiceImpl(apiKey: apiKey);
}

/// Platform Manager Provider - Hybrid service manager
/// Coordinates multiple ticket platform services (StubHub, SeatGeek) into a unified interface
/// This allows the app to search across all platforms simultaneously and aggregate results
/// @param ref: Riverpod reference for dependency injection to access individual platform services
/// @returns: Configured PlatformManager instance that orchestrates all ticket platforms
@riverpod
PlatformManager platformManager(Ref ref) {
  final stubhubService = ref.watch(stubhubServiceProvider);
  final seatgeekService = ref.watch(seatgeekServiceProvider);
  final tmService = ref.watch(ticketmasterServiceProvider);

  return PlatformManager(
    stubhubService: stubhubService,
    seatgeekService: seatgeekService,
    ticketmasterService: tmService,
  );
}

/// Hybrid Events Provider - Unified events from all platforms
/// Fetches and combines events from all available ticket platforms (StubHub, SeatGeek)
/// This provides a comprehensive search across the entire ticket marketplace ecosystem
/// @param ref: Riverpod reference for dependency injection
/// @param query: Optional search query to filter events by name/description
/// @param location: Optional location filter to find events in specific areas
/// @param limit: Maximum number of events to return (default: 24 for optimal performance)
/// @returns: List of UnifiedEvent objects aggregated from all platforms
@riverpod
Future<List<UnifiedEvent>> hybridEvents(Ref ref, {
  String? query,
  String? location,
  int limit = 24,
}) async {
  final platformManager = ref.watch(platformManagerProvider);
  
  developer.log('🔄 Fetching events from all platforms...', name: 'PlatformProviders');
  developer.log('Query: $query, Location: $location, Limit: $limit', name: 'PlatformProviders');
  
  try {
    final events = await platformManager.getUnifiedEvents(
      query: query,
      location: location,
      limit: limit,
    );
    
    developer.log('✅ Fetched ${events.length} unified events', name: 'PlatformProviders');
    for (final event in events.take(3)) {
      developer.log('📅 ${event.name} - ${event.platformType} - ${event.dateTime?.day}/${event.dateTime?.month}', name: 'PlatformProviders');
    }
    
    return events;
  } catch (e) {
    developer.log('❌ Error fetching hybrid events: $e', name: 'PlatformProviders', error: e);
    return [];
  }
}

/// StubHub Marketplace Provider - Bilet listeleme işlemleri
@riverpod
class StubhubMarketplace extends _$StubhubMarketplace {
  @override
  AsyncValue<String?> build() {
    return const AsyncValue.data(null);
  }

  /// StubHub'da bilet listele
  Future<void> listTicket({
    required String eventId,
    required int quantity,
    required double price,
    required Map<String, dynamic> ticketDetails,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final platformManager = ref.read(platformManagerProvider);
      
      developer.log('📝 Listing ticket on StubHub marketplace...', name: 'StubhubMarketplace');
      developer.log('Event: $eventId, Qty: $quantity, Price: \$$price', name: 'StubhubMarketplace');
      
      final success = await platformManager.listTicketOnStubHub(
        eventId: eventId,
        quantity: quantity,
        price: price,
        ticketDetails: ticketDetails,
      );
      
      if (success) {
        state = const AsyncValue.data('Bilet başarıyla StubHub\'da listelendi!');
        developer.log('✅ Ticket listed successfully', name: 'StubhubMarketplace');
      } else {
        state = AsyncValue.error('Bilet listeleme başarısız', StackTrace.current);
        developer.log('❌ Ticket listing failed', name: 'StubhubMarketplace');
      }
    } catch (error, stackTrace) {
      developer.log('❌ StubHub listing error: $error', name: 'StubhubMarketplace', error: error);
      state = AsyncValue.error('Beklenmeyen hata: $error', stackTrace);
    }
  }

  /// Kullanıcının StubHub listelerini getir
  Future<List<dynamic>> getUserListings(String userId) async {
    try {
      final platformManager = ref.read(platformManagerProvider);
      return await platformManager.getUserListings(userId);
    } catch (e) {
      developer.log('❌ Error getting user listings: $e', name: 'StubhubMarketplace', error: e);
      return [];
    }
  }
}

/// Platform Statistics Provider - Platform performans metrikleri
@riverpod
class PlatformStats extends _$PlatformStats {
  @override
  Map<String, dynamic> build() {
    return {
      'total_events': 0,
      'seatgeek_events': 0,
      'ticketmaster_events': 0,
      'last_updated': DateTime.now(),
    };
  }

  void updateStats(List<UnifiedEvent> events) {
    try {
      final stats = <String, dynamic>{
        'total_events': events.length,
        'seatgeek_events': events.where((e) => e.platformType == PlatformType.seatgeek.value).length,
        'ticketmaster_events': events.where((e) => e.platformType == PlatformType.ticketmaster.value).length,
        'last_updated': DateTime.now(),
      };
      
      state = stats;
      
      developer.log('📊 Platform Stats Updated:', name: 'PlatformStats');
      developer.log('  📱 Total: ${stats['total_events']}', name: 'PlatformStats');
      developer.log('  🎭 SeatGeek: ${stats['seatgeek_events']}', name: 'PlatformStats');
      developer.log('  🎟️ Ticketmaster: ${stats['ticketmaster_events']}', name: 'PlatformStats');
    } catch (e) {
      developer.log('⚠️ Platform stats update error: $e', name: 'PlatformStats', error: e);
      // Silent fail - stats güncellenmesi kritik değil
    }
  }
}
