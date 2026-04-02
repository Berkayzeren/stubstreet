// lib/core/services/stubhub_service.dart

import 'package:dio/dio.dart';
import 'platform_manager.dart';

/// StubHub API service implementation
/// Bu service çekirdek marketplace işlevselliğini sağlar
class StubHubServiceImpl implements StubHubService {
  final Dio _dio;
  final String _apiKey;

  StubHubServiceImpl({
    required String apiKey,
  })  : _apiKey = apiKey,
        _dio = Dio() {
    _dio.options.headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  @override
  Future<List<UnifiedEvent>> getEvents({
    String? query,
    String? location,
    int limit = 20,
  }) async {
    try {
      // StubHub API çağrısı (şu anda mock data)
      // print('📞 Calling StubHub API for events...');
      
      // Gerçek API implementasyonu için:
      // final response = await _dio.get(
      //   '$_baseUrl/catalog/events/v3',
      //   queryParameters: {
      //     'q': query,
      //     'geoSearch': location,
      //     'limit': limit,
      //   },
      // );

      // Şimdilik mock data döndür
      return _getMockStubHubEvents(query: query, limit: limit);
    } catch (e) {
      // print('❌ StubHub API error: $e');
      return [];
    }
  }

  @override
  Future<bool> listTicket({
    required String eventId,
    required int quantity,
    required double price,
    required Map<String, dynamic> details,
  }) async {
    try {
      // print('📝 Listing ticket on StubHub...');
      // print('Event ID: $eventId, Quantity: $quantity, Price: $price');
      
      // Gerçek API implementasyonu için:
      // final response = await _dio.post(
      //   '$_baseUrl/accountmanagement/listings/v1',
      //   data: {
      //     'eventId': eventId,
      //     'quantity': quantity,
      //     'pricePerTicket': {
      //       'amount': price,
      //       'currency': 'USD',
      //     },
      //     'splitType': 'NONE',
      //     'ticketTraits': details,
      //   },
      // );

      // Mock success
      await Future.delayed(const Duration(seconds: 2));
      // print('✅ Ticket listed successfully on StubHub');
      return true;
    } catch (e) {
      // print('❌ StubHub listing error: $e');
      return false;
    }
  }

  @override
  Future<List<dynamic>> getUserListings(String userId) async {
    try {
      // print('👤 Getting user listings from StubHub...');
      
      // Gerçek API implementasyonu için:
      // final response = await _dio.get(
      //   '$_baseUrl/accountmanagement/listings/v1',
      //   queryParameters: {
      //     'sellerId': userId,
      //   },
      // );

      // Mock data
      return _getMockUserListings(userId);
    } catch (e) {
      // print('❌ StubHub user listings error: $e');
      return [];
    }
  }

  /// Mock StubHub etkinlikleri - Enhanced with more variety and realistic data
  /// This method generates diverse sample events across multiple categories to showcase the platform's capabilities
  List<UnifiedEvent> _getMockStubHubEvents({
    String? query,
    int limit = 20,
  }) {
    final mockEvents = [
      // Turkish Pop/Rock Concerts - High demand events
      UnifiedEvent(
        id: 'sh_1',
        platformId: 'stubhub_concert_123',
        platformType: PlatformType.stubhub.value,
        name: 'Sezen Aksu Konser',
        description: 'Efsanevi sanatçının muhteşem sahne performansı. 40 yıllık kariyerinin en güzel şarkıları.',
        dateTime: DateTime.now().add(const Duration(days: 15)),
        venueName: 'Volkswagen Arena',
        city: 'İstanbul',
        imageUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800&q=80',
        ticketUrl: 'https://stubhub.com/sezen-aksu-tickets',
        priceRange: const PriceRange(min: 150, max: 800, currency: 'TRY'),
        genre: 'Music',
        segment: 'Turkish Pop',
        isResellable: true,
        rawData: {'source': 'stubhub', 'popularity': 9.2},
      ),
      
      // Sports - Football Derby
      UnifiedEvent(
        id: 'sh_2',
        platformId: 'stubhub_sports_456',
        platformType: PlatformType.stubhub.value,
        name: 'Galatasaray vs Fenerbahçe',
        description: 'Türk futbolunun en büyük derbisi. Heyecan dolu 90 dakika bekliyor.',
        dateTime: DateTime.now().add(const Duration(days: 8)),
        venueName: 'Türk Telekom Stadyumu',
        city: 'İstanbul',
        imageUrl: 'https://images.unsplash.com/photo-1522778119026-d647f0596c20?w=800&q=80',
        ticketUrl: 'https://stubhub.com/galatasaray-tickets',
        priceRange: const PriceRange(min: 200, max: 1500, currency: 'TRY'),
        genre: 'Sports',
        segment: 'Football',
        isResellable: true,
        rawData: {'source': 'stubhub', 'popularity': 9.8},
      ),

      // International Pop Star Concert
      UnifiedEvent(
        id: 'sh_3',
        platformId: 'stubhub_intl_789',
        platformType: PlatformType.stubhub.value,
        name: 'Tarkan - Harbiye Konseri',
        description: 'Uluslararası süperstar Tarkan\'ın özel Harbiye konseri. Unutulmaz bir gece.',
        dateTime: DateTime.now().add(const Duration(days: 22)),
        venueName: 'Harbiye Cemil Topuzlu Açıkhava Tiyatrosu',
        city: 'İstanbul',
        imageUrl: 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=800&q=80',
        ticketUrl: 'https://stubhub.com/tarkan-tickets',
        priceRange: const PriceRange(min: 250, max: 1200, currency: 'TRY'),
        genre: 'Music',
        segment: 'International Pop',
        isResellable: true,
        rawData: {'source': 'stubhub', 'popularity': 9.5},
      ),

      // Theater - Cultural Event
      UnifiedEvent(
        id: 'sh_4',
        platformId: 'stubhub_theater_101',
        platformType: PlatformType.stubhub.value,
        name: 'Hamlet - Devlet Tiyatrosu',
        description: 'Shakespeare\'in ölümsüz eseri Hamlet, modern yorumuyla sahneye taşınıyor.',
        dateTime: DateTime.now().add(const Duration(days: 12)),
        venueName: 'İstanbul Devlet Tiyatrosu',
        city: 'İstanbul',
        imageUrl: 'https://images.unsplash.com/photo-1507924538820-ede94a04019d?w=800&q=80',
        ticketUrl: 'https://stubhub.com/hamlet-tickets',
        priceRange: const PriceRange(min: 80, max: 300, currency: 'TRY'),
        genre: 'Theater',
        segment: 'Drama',
        isResellable: true,
        rawData: {'source': 'stubhub', 'popularity': 7.8},
      ),

      // Electronic Music Festival
      UnifiedEvent(
        id: 'sh_5',
        platformId: 'stubhub_festival_202',
        platformType: PlatformType.stubhub.value,
        name: 'Elektronik Müzik Festivali',
        description: '3 gün sürecek elektronik müzik festivalinde dünyaca ünlü DJ\'ler sahne alacak.',
        dateTime: DateTime.now().add(const Duration(days: 35)),
        venueName: 'İstanbul Park',
        city: 'İstanbul',
        imageUrl: 'https://images.unsplash.com/photo-1429962714451-bb934ecdc4ec?w=800&q=80',
        ticketUrl: 'https://stubhub.com/electronic-festival-tickets',
        priceRange: const PriceRange(min: 400, max: 2000, currency: 'TRY'),
        genre: 'Music',
        segment: 'Electronic',
        isResellable: true,
        rawData: {'source': 'stubhub', 'popularity': 9.1},
      ),

      // Basketball Game
      UnifiedEvent(
        id: 'sh_6',
        platformId: 'stubhub_basketball_303',
        platformType: PlatformType.stubhub.value,
        name: 'Anadolu Efes vs Real Madrid',
        description: 'EuroLeague\'de heyecan verici mücadele. Şampiyonlar Ligi\'nde önemli maç.',
        dateTime: DateTime.now().add(const Duration(days: 18)),
        venueName: 'Sinan Erdem Spor Salonu',
        city: 'İstanbul',
        imageUrl: 'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800&q=80',
        ticketUrl: 'https://stubhub.com/anadolu-efes-tickets',
        priceRange: const PriceRange(min: 120, max: 600, currency: 'TRY'),
        genre: 'Sports',
        segment: 'Basketball',
        isResellable: true,
        rawData: {'source': 'stubhub', 'popularity': 8.2},
      ),

      // Opera - High Culture Event
      UnifiedEvent(
        id: 'sh_7',
        platformId: 'stubhub_opera_404',
        platformType: PlatformType.stubhub.value,
        name: 'La Traviata - İstanbul Opera',
        description: 'Verdi\'nin muhteşem operası La Traviata, unutulmaz bir sahne sunumuyla.',
        dateTime: DateTime.now().add(const Duration(days: 28)),
        venueName: 'İstanbul Devlet Opera ve Balesi',
        city: 'İstanbul',
        imageUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800&q=80',
        ticketUrl: 'https://stubhub.com/la-traviata-tickets',
        priceRange: const PriceRange(min: 100, max: 500, currency: 'TRY'),
        genre: 'Classical',
        segment: 'Opera',
        isResellable: true,
        rawData: {'source': 'stubhub', 'popularity': 7.5},
      ),

      // Stand-up Comedy
      UnifiedEvent(
        id: 'sh_8',
        platformId: 'stubhub_comedy_505',
        platformType: PlatformType.stubhub.value,
        name: 'Cem Yılmaz Stand-up Gösterisi',
        description: 'Cem Yılmaz\'ın en yeni stand-up gösterisi. Güldürmeye hazır olun!',
        dateTime: DateTime.now().add(const Duration(days: 20)),
        venueName: 'Jolly Joker Ankara',
        city: 'Ankara',
        imageUrl: 'https://images.unsplash.com/photo-1527224857830-43a7acc85260?w=800&q=80',
        ticketUrl: 'https://stubhub.com/cem-yilmaz-tickets',
        priceRange: const PriceRange(min: 180, max: 450, currency: 'TRY'),
        genre: 'Comedy',
        segment: 'Stand-up',
        isResellable: true,
        rawData: {'source': 'stubhub', 'popularity': 9.0},
      ),

      // Rock Concert
      UnifiedEvent(
        id: 'sh_9',
        platformId: 'stubhub_rock_606',
        platformType: PlatformType.stubhub.value,
        name: 'Duman Konseri',
        description: 'Türk rock\'ının efsane grubu Duman, büyüleyici sahne performansıyla.',
        dateTime: DateTime.now().add(const Duration(days: 25)),
        venueName: 'Küçükçiftlik Park',
        city: 'İstanbul',
        imageUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800&q=80',
        ticketUrl: 'https://stubhub.com/duman-tickets',
        priceRange: const PriceRange(min: 140, max: 600, currency: 'TRY'),
        genre: 'Music',
        segment: 'Rock',
        isResellable: true,
        rawData: {'source': 'stubhub', 'popularity': 8.7},
      ),

      // Tennis Tournament
      UnifiedEvent(
        id: 'sh_10',
        platformId: 'stubhub_tennis_707',
        platformType: PlatformType.stubhub.value,
        name: 'İstanbul Tennis Cup Finali',
        description: 'Uluslararası tenis turnuvasının heyecanlı final maçı.',
        dateTime: DateTime.now().add(const Duration(days: 30)),
        venueName: 'İstanbul Tenis Kulübü',
        city: 'İstanbul',
        imageUrl: 'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=800&q=80',
        ticketUrl: 'https://stubhub.com/tennis-cup-tickets',
        priceRange: const PriceRange(min: 150, max: 800, currency: 'TRY'),
        genre: 'Sports',
        segment: 'Tennis',
        isResellable: true,
        rawData: {'source': 'stubhub', 'popularity': 7.9},
      ),

      // Dance Performance
      UnifiedEvent(
        id: 'sh_11',
        platformId: 'stubhub_dance_808',
        platformType: PlatformType.stubhub.value,
        name: 'Modern Dans Topluluğu Gösterisi',
        description: 'Çağdaş dans sanatının en güzel örneklerini sunan özel gösteri.',
        dateTime: DateTime.now().add(const Duration(days: 40)),
        venueName: 'Zorlu PSM Studio',
        city: 'İstanbul',
        imageUrl: 'https://images.unsplash.com/photo-1508807526345-15e9b5f4eaff?w=800&q=80',
        ticketUrl: 'https://stubhub.com/modern-dance-tickets',
        priceRange: const PriceRange(min: 90, max: 350, currency: 'TRY'),
        genre: 'Dance',
        segment: 'Contemporary',
        isResellable: true,
        rawData: {'source': 'stubhub', 'popularity': 7.2},
      ),

      // International Pop Concert
      UnifiedEvent(
        id: 'sh_12',
        platformId: 'stubhub_intlpop_909',
        platformType: PlatformType.stubhub.value,
        name: 'Ajda Pekkan - Süperstar Konseri',
        description: 'Türk pop müziğinin süperstarı Ajda Pekkan\'ın büyük konseri.',
        dateTime: DateTime.now().add(const Duration(days: 45)),
        venueName: 'Volkswagen Arena',
        city: 'İstanbul',
        imageUrl: 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=800&q=80',
        ticketUrl: 'https://stubhub.com/ajda-pekkan-tickets',
        priceRange: const PriceRange(min: 200, max: 900, currency: 'TRY'),
        genre: 'Music',
        segment: 'Turkish Pop',
        isResellable: true,
        rawData: {'source': 'stubhub', 'popularity': 8.8},
      ),
    ];

    if (query != null && query.isNotEmpty) {
      return mockEvents
          .where((event) => 
              event.name.toLowerCase().contains(query.toLowerCase()) ||
              (event.description?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .take(limit)
          .toList();
    }

    return mockEvents.take(limit).toList();
  }

  /// Mock kullanıcı listeleri
  List<dynamic> _getMockUserListings(String userId) {
    return [
      {
        'id': 'listing_1',
        'eventName': 'Sezen Aksu Konser',
        'quantity': 2,
        'price': 350.0,
        'status': 'ACTIVE',
        'section': 'VIP',
        'row': '1',
        'listedDate': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      },
      {
        'id': 'listing_2',
        'eventName': 'Galatasaray vs Fenerbahçe',
        'quantity': 1,
        'price': 750.0,
        'status': 'SOLD',
        'section': 'Maraton',
        'row': '15',
        'listedDate': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      },
    ];
  }
}
