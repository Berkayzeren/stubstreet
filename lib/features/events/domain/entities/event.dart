// lib/features/events/domain/entities/event.dart

class EventItem {
  final String id;
  final String name;
  final DateTime? dateTime;
  final String? venueName;
  final String? city;
  final String? imageUrl;
  final String? description;
  final String? priceRange;
  final String? ticketUrl;
  final String? genre;
  final String? segment;
  final int likeCount;
  final bool isLiked;

  const EventItem({
    required this.id,
    required this.name,
    this.dateTime,
    this.venueName,
    this.city,
    this.imageUrl,
    this.description,
    this.priceRange,
    this.ticketUrl,
    this.genre,
    this.segment,
    this.likeCount = 0,
    this.isLiked = false,
  });

  factory EventItem.fromTicketmasterJson(Map<String, dynamic> json) {
    final dates = json['dates'] as Map<String, dynamic>?;
    final start = dates != null ? dates['start'] as Map<String, dynamic>? : null;
    final dateTimeString = start != null ? (start['dateTime'] as String?) : null;
    final parsedDateTime = dateTimeString != null ? DateTime.tryParse(dateTimeString) : null;

    final embedded = json['_embedded'] as Map<String, dynamic>?;
    final venues = embedded != null ? embedded['venues'] as List<dynamic>? : null;
    final firstVenue = (venues != null && venues.isNotEmpty) ? venues.first as Map<String, dynamic> : null;
    final venueName = firstVenue != null ? firstVenue['name'] as String? : null;
    final venueCityMap = firstVenue != null ? firstVenue['city'] as Map<String, dynamic>? : null;
    final venueCity = venueCityMap != null ? venueCityMap['name'] as String? : null;

    String? selectedImageUrl;
    final images = json['images'] as List<dynamic>?;
    if (images != null && images.isNotEmpty) {
      // Prefer medium sized image if available
      final medium = images.cast<Map<String, dynamic>?>().firstWhere(
            (img) => (img?['width'] as int? ?? 0) >= 600 && (img?['width'] as int? ?? 0) <= 1200,
            orElse: () => images.first as Map<String, dynamic>?,
          );
      selectedImageUrl = medium?['url'] as String?;
    }

    // Extract additional information
    final info = json['info'] as String?;
    final pleaseNote = json['pleaseNote'] as String?;
    final description = info ?? pleaseNote ?? '';
    
    // Extract price range
    final priceRanges = json['priceRanges'] as List<dynamic>?;
    String? priceRange;
    if (priceRanges != null && priceRanges.isNotEmpty) {
      final firstRange = priceRanges.first as Map<String, dynamic>;
      final min = firstRange['min'] as num?;
      final max = firstRange['max'] as num?;
      final currency = firstRange['currency'] as String? ?? 'TRY';
      if (min != null && max != null) {
        priceRange = '$min-$max $currency';
      } else if (min != null) {
        priceRange = '$min+ $currency';
      }
    }
    
    // Extract ticket URL
    final ticketUrl = json['url'] as String?;
    
    // Extract classifications (genre/segment)
    final classifications = json['classifications'] as List<dynamic>?;
    String? genre, segment;
    if (classifications != null && classifications.isNotEmpty) {
      final firstClass = classifications.first as Map<String, dynamic>;
      final genreMap = firstClass['genre'] as Map<String, dynamic>?;
      final segmentMap = firstClass['segment'] as Map<String, dynamic>?;
      genre = genreMap?['name'] as String?;
      segment = segmentMap?['name'] as String?;
    }

    return EventItem(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Event',
      dateTime: parsedDateTime,
      venueName: venueName,
      city: venueCity,
      imageUrl: selectedImageUrl,
      description: description.isNotEmpty ? description : null,
      priceRange: priceRange,
      ticketUrl: ticketUrl,
      genre: genre,
      segment: segment,
      likeCount: 0, // API'den gelmeyen veriler için varsayılan değerler
      isLiked: false,
    );
  }
}


