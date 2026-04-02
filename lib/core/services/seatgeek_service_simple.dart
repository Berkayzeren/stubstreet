// lib/core/services/seatgeek_service_simple.dart

import 'package:dio/dio.dart';
import 'platform_manager.dart';

/// Basit SeatGeek service implementasyonu
class SeatGeekServiceSimple implements SeatGeekService {
  final Dio _dio;
  final String _clientId;
  final String _baseUrl = 'https://api.seatgeek.com/2';

  SeatGeekServiceSimple({
    required String clientId,
  })  : _clientId = clientId,
        _dio = Dio();

  @override
  Future<List<UnifiedEvent>> getEvents({
    String? query,
    String? location,
    int limit = 20,
  }) async {
    try {
      // print('📞 SeatGeek API çağrısı yapılıyor...');
      // print('Client ID: ${_clientId.substring(0, 8)}...');
      
      final response = await _dio.get(
        '$_baseUrl/events',
        queryParameters: {
          'client_id': _clientId,
          if (query != null) 'q': query,
          'per_page': limit,
          'sort': 'datetime_utc.asc',
        },
      );
      
      // print('✅ SeatGeek API yanıtı alındı');
      final events = response.data['events'] as List? ?? [];
      // print('📊 SeatGeek\'den ${events.length} etkinlik bulundu');
      
      return events.map((eventData) => _parseEvent(eventData)).toList();
    } catch (e) {
      // print('❌ SeatGeek API hatası: $e');
      // Mock kullanımı devre dışı: gerçek veri yoksa boş döndür
      return [];
    }
  }

  UnifiedEvent _parseEvent(Map<String, dynamic> data) {
    final venue = data['venue'] as Map<String, dynamic>?;
    final performers = data['performers'] as List<dynamic>? ?? [];
    
    String? genre;
    String? segment;
    String? imageUrl;
    
    if (performers.isNotEmpty) {
      final performer = performers.first as Map<String, dynamic>;
      genre = performer['type'] as String?;
      imageUrl = performer['image'] as String?;
      
      final genreData = performer['genre'] as Map<String, dynamic>?;
      if (genreData != null) {
        segment = genreData['name'] as String?;
      }
    }

    return UnifiedEvent(
      id: 'sg_${data['id']}',
      platformId: data['id'].toString(),
      platformType: PlatformType.seatgeek.value,
      name: data['title'] ?? 'Unknown Event',
      description: data['short_title'],
      dateTime: data['datetime_utc'] != null 
          ? DateTime.parse(data['datetime_utc'])
          : null,
      venueName: venue?['name'],
      city: venue?['display_location'],
      imageUrl: imageUrl,
      ticketUrl: data['url'],
      priceRange: _parsePriceRange(data['stats']),
      genre: genre,
      segment: segment,
      isResellable: false,
      rawData: data,
    );
  }

  PriceRange? _parsePriceRange(dynamic stats) {
    if (stats == null) return null;
    
    final statsMap = stats as Map<String, dynamic>;
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }
    
    // SeatGeek 'stats' için olası alanlar: lowest_price, highest_price, average_price,
    // median_price, lowest_sg_base_price, highest_sg_base_price
    final min = toDouble(statsMap['lowest_price'])
        ?? toDouble(statsMap['lowest_sg_base_price'])
        ?? toDouble(statsMap['average_price'])
        ?? toDouble(statsMap['median_price']);
    final max = toDouble(statsMap['highest_price'])
        ?? toDouble(statsMap['highest_sg_base_price'])
        ?? min;
    
    if (min != null || max != null) {
      return PriceRange(
        min: min,
        max: max,
        currency: 'USD',
      );
    }
    
    return null;
  }

  // Mock verisi kaldırıldı
}
