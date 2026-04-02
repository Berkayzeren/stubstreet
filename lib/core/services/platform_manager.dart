// lib/core/services/platform_manager.dart

import '../../features/events/domain/entities/event.dart';
import '../utils/event_image_helper.dart';

/// Hibrit platform yöneticisi: StubHub + SeatGeek
/// Bu service, çoklu API'leri yönetir ve normalize edilmiş veri sağlar

enum PlatformType {
  stubhub('stubhub'),
  seatgeek('seatgeek'),
  ticketmaster('ticketmaster');

  const PlatformType(this.value);
  final String value;
}

/// Platformlar arası normalize edilmiş etkinlik modeli
class UnifiedEvent {
  final String id;
  final String platformId; // Hangi platformdan geldiği
  final String platformType;
  final String name;
  final String? description;
  final DateTime? dateTime;
  final String? venueName;
  final String? city;
  final String? imageUrl;
  final String? ticketUrl;
  final PriceRange? priceRange;
  final String? genre;
  final String? segment;
  final bool isResellable; // StubHub'da satılabilir mi?
  final Map<String, dynamic> rawData; // Orijinal platform datası

  const UnifiedEvent({
    required this.id,
    required this.platformId,
    required this.platformType,
    required this.name,
    this.description,
    this.dateTime,
    this.venueName,
    this.city,
    this.imageUrl,
    this.ticketUrl,
    this.priceRange,
    this.genre,
    this.segment,
    this.isResellable = false,
    this.rawData = const {},
  });

  /// Mevcut EventItem'dan UnifiedEvent'e dönüştürme
  factory UnifiedEvent.fromEventItem(EventItem eventItem) {
    return UnifiedEvent(
      id: 'sg_${eventItem.id}',
      platformId: eventItem.id,
                          platformType: PlatformType.seatgeek.value,
      name: eventItem.name,
      description: eventItem.description,
      dateTime: eventItem.dateTime,
      venueName: eventItem.venueName,
      city: eventItem.city,
      imageUrl: eventItem.imageUrl,
      ticketUrl: eventItem.ticketUrl,
      priceRange: eventItem.priceRange != null 
          ? PriceRange.fromString(eventItem.priceRange!)
          : null,
      genre: eventItem.genre,
      segment: eventItem.segment,
      isResellable: true, // SeatGeek etkinlikleri genelde resellable
    );
  }

  /// EventItem'a geri dönüştürme (geriye uyumluluk için)
  EventItem toEventItem() {
    // Only use real image URLs. Do NOT fallback to Unsplash.
    final realImageUrl = EventImageHelper.isValidEventImage(imageUrl)
        ? imageUrl
        : null;

    return EventItem(
      id: platformId,
      name: name,
      dateTime: dateTime,
      venueName: venueName,
      city: city,
      imageUrl: realImageUrl,
      description: description,
      priceRange: priceRange?.toString(),
      ticketUrl: ticketUrl,
      genre: genre,
      segment: segment,
      likeCount: 0,
      isLiked: false,
    );
  }
}

/// Normalize edilmiş fiyat aralığı
class PriceRange {
  final double? min;
  final double? max;
  final String currency;

  const PriceRange({
    this.min,
    this.max,
    this.currency = 'TRY',
  });

  factory PriceRange.fromString(String priceStr) {
    // "100-500 TRY" formatından parse et
    final parts = priceStr.split(' ');
    final currency = parts.length > 1 ? parts[1] : 'TRY';
    final range = parts[0];
    
    if (range.contains('-')) {
      final prices = range.split('-');
      return PriceRange(
        min: double.tryParse(prices[0]),
        max: double.tryParse(prices[1]),
        currency: currency,
      );
    } else if (range.contains('+')) {
      return PriceRange(
        min: double.tryParse(range.replaceAll('+', '')),
        currency: currency,
      );
    }
    
    return PriceRange(
      min: double.tryParse(range),
      currency: currency,
    );
  }

  @override
  String toString() {
    if (min != null && max != null) {
      return '$min-$max $currency';
    } else if (min != null) {
      return '$min+ $currency';
    }
    return currency;
  }
}

/// Platform manager - çoklu API'leri yönetir
class PlatformManager {
  final StubHubService _stubhubService;
  final SeatGeekService _seatgeekService;
  final TicketmasterService _ticketmasterService;

  PlatformManager({
    required StubHubService stubhubService,
    required SeatGeekService seatgeekService,
    required TicketmasterService ticketmasterService,
  })  : _stubhubService = stubhubService,
        _seatgeekService = seatgeekService,
        _ticketmasterService = ticketmasterService;

  /// Tüm platformlardan birleşik etkinlik listesi
  Future<List<UnifiedEvent>> getUnifiedEvents({
    String? query,
    String? location,
    int limit = 20,
  }) async {
    final List<UnifiedEvent> unifiedEvents = [];

    try {
      // Paralel olarak tüm platformlardan veri çek
      // StubHub devre dışı (mock kullanımı kaldırıldı)
      final futures = await Future.wait([
        _getSeatGeekEvents(query: query, location: location, limit: limit ~/ 2),
        _getTicketmasterEvents(query: query, location: location, limit: limit - (limit ~/ 2)),
      ]);

      // Sonuçları birleştir
      for (final platformEvents in futures) {
        unifiedEvents.addAll(platformEvents);
      }

      // Tarih ve popülerlik bazında sırala
      unifiedEvents.sort((a, b) {
        if (a.dateTime == null && b.dateTime == null) return 0;
        if (a.dateTime == null) return 1;
        if (b.dateTime == null) return -1;
        return a.dateTime!.compareTo(b.dateTime!);
      });

      return unifiedEvents.take(limit).toList();
    } catch (e) {
      // print('❌ Error fetching unified events: $e');
      return [];
    }
  }

  // StubHub fetch devre dışı

  /// SeatGeek'den etkinlikleri al (placeholder - gerçek implementasyon gerekli)
  Future<List<UnifiedEvent>> _getSeatGeekEvents({
    String? query,
    String? location,
    int limit = 10,
  }) async {
    try {
      final events = await _seatgeekService.getEvents(
        query: query,
        location: location,
        limit: limit,
      );
      return events;
    } catch (e) {
      // print('⚠️ SeatGeek fetch error: $e');
      return [];
    }
  }

  /// Ticketmaster'dan etkinlikleri al
  Future<List<UnifiedEvent>> _getTicketmasterEvents({
    String? query,
    String? location,
    int limit = 10,
  }) async {
    try {
      final events = await _ticketmasterService.getEvents(
        query: query,
        location: location,
        limit: limit,
      );
      return events;
    } catch (e) {
      // print('⚠️ Ticketmaster fetch error: $e');
      return [];
    }
  }

  /// StubHub üzerinden bilet listele (çekirdek marketplace işlevi)
  Future<bool> listTicketOnStubHub({
    required String eventId,
    required int quantity,
    required double price,
    required Map<String, dynamic> ticketDetails,
  }) async {
    try {
      return await _stubhubService.listTicket(
        eventId: eventId,
        quantity: quantity,
        price: price,
        details: ticketDetails,
      );
    } catch (e) {
      // print('❌ StubHub listing error: $e');
      return false;
    }
  }

  /// Kullanıcının StubHub listelerini getir
  Future<List<dynamic>> getUserListings(String userId) async {
    try {
      return await _stubhubService.getUserListings(userId);
    } catch (e) {
      // print('❌ StubHub user listings error: $e');
      return [];
    }
  }
}

/// StubHub Service (çekirdek marketplace)
abstract class StubHubService {
  Future<List<UnifiedEvent>> getEvents({
    String? query,
    String? location,
    int limit = 20,
  });

  Future<bool> listTicket({
    required String eventId,
    required int quantity,
    required double price,
    required Map<String, dynamic> details,
  });

  Future<List<dynamic>> getUserListings(String userId);
}

/// SeatGeek Service (etkinlik zenginleştirme)
abstract class SeatGeekService {
  Future<List<UnifiedEvent>> getEvents({
    String? query,
    String? location,
    int limit = 20,
  });
}

/// Ticketmaster Service (etkinlik keşfi)
abstract class TicketmasterService {
  Future<List<UnifiedEvent>> getEvents({
    String? query,
    String? location,
    int limit = 20,
  });
}
