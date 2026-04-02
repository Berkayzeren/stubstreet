// lib/core/services/ticketmaster_service.dart

import 'package:dio/dio.dart';
import 'platform_manager.dart';
import 'package:stubstreet/features/events/domain/entities/event.dart';

/// Ticketmaster Discovery API service implementation
class TicketmasterServiceImpl implements TicketmasterService {
  final Dio _dio;
  final String _apiKey;
  final String _baseUrl = 'https://app.ticketmaster.com/discovery/v2';

  TicketmasterServiceImpl({
    required String apiKey,
  })  : _apiKey = apiKey,
        _dio = Dio();

  @override
  Future<List<UnifiedEvent>> getEvents({
    String? query,
    String? location,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/events.json',
        queryParameters: {
          'apikey': _apiKey,
          if (query != null && query.isNotEmpty) 'keyword': query,
          // Bölge filtresi: Türkiye (countryCode TR)
          'countryCode': 'TR',
          'size': limit,
          'sort': 'date,asc',
          // location parametresi için opsiyonel: geoPoint, latlong veya city uygulanabilir
        },
      );

      final data = response.data as Map<String, dynamic>;
      final embedded = data['_embedded'] as Map<String, dynamic>?;
      final events = embedded != null ? embedded['events'] as List<dynamic>? : null;
      if (events == null || events.isEmpty) return [];

      return events.map((e) => _parseEvent(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  UnifiedEvent _parseEvent(Map<String, dynamic> json) {
    final item = _toEventItem(json);
    return UnifiedEvent(
      id: 'tm_${item.id}',
      platformId: item.id,
      platformType: PlatformType.ticketmaster.value,
      name: item.name,
      description: item.description,
      dateTime: item.dateTime,
      venueName: item.venueName,
      city: item.city,
      imageUrl: item.imageUrl,
      ticketUrl: item.ticketUrl,
      priceRange: item.priceRange != null ? PriceRange.fromString(item.priceRange!) : null,
      genre: item.genre,
      segment: item.segment,
      isResellable: false,
      rawData: json,
    );
  }

  EventItem _toEventItem(Map<String, dynamic> json) {
    return EventItem.fromTicketmasterJson(json);
  }
}


