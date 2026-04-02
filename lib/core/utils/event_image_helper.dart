// lib/core/utils/event_image_helper.dart

/// Helper class to provide relevant placeholder images for events
/// This ensures events have appropriate images based on their category/genre
class EventImageHelper {
  // Private constructor to prevent instantiation
  EventImageHelper._();

  // Category-based image mappings using high-quality Unsplash images
  static const Map<String, List<String>> _categoryImages = {
    // Music events
    'Music': [
      'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800&q=80', // Concert crowd
      'https://images.unsplash.com/photo-1506157786151-b8491531f063?w=800&q=80', // Music festival
      'https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?w=800&q=80', // Concert stage
      'https://images.unsplash.com/photo-1524368535928-5b5e00ddc76b?w=800&q=80', // DJ performance
      'https://images.unsplash.com/photo-1514320291840-2e0a9bf2a9ae?w=800&q=80', // Live music
    ],
    'Sports': [
      'https://images.unsplash.com/photo-1522778119026-d647f0596c20?w=800&q=80', // Football stadium
      'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800&q=80', // Basketball
      'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800&q=80', // Soccer match
      'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=800&q=80', // Tennis (updated)
      'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&q=80', // Sports arena (updated)
    ],
    'Theatre': [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&q=80', // Theatre stage
      'https://images.unsplash.com/photo-1503095396549-807759245b35?w=800&q=80', // Theatre curtains
      'https://images.unsplash.com/photo-1547887538-e3a2f32cb1cc?w=800&q=80', // Theatre interior
    ],
    'Comedy': [
      'https://images.unsplash.com/photo-1527224857830-43a7acc85260?w=800&q=80', // Microphone
      'https://images.unsplash.com/photo-1607734834519-d8576ae60ea6?w=800&q=80', // Comedy club
    ],
    'Festival': [
      'https://images.unsplash.com/photo-1506157786151-b8491531f063?w=800&q=80', // Festival crowd
      'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=800&q=80', // Festival lights
      'https://images.unsplash.com/photo-1527529482837-4698179dc6ce?w=800&q=80', // Outdoor festival
    ],
  };

  // Segment-based fallbacks
  static const Map<String, String> _segmentImages = {
    'Football': 'https://images.unsplash.com/photo-1522778119026-d647f0596c20?w=800&q=80',
    'Basketball': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800&q=80',
    'Turkish Pop': 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800&q=80',
    'Rock': 'https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?w=800&q=80',
    'Classical': 'https://images.unsplash.com/photo-1519683109079-d5f539e1542f?w=800&q=80',
  };

  // Default fallback image for events
  static const String _defaultEventImage = 
      'https://images.unsplash.com/photo-1531058020387-3be344556be6?w=800&q=80'; // Generic event

  /// Get a relevant placeholder image based on event genre and segment
  /// Returns a high-quality, contextually appropriate image URL
  static String getRelevantImage({
    String? genre,
    String? segment,
    String? name,
  }) {
    // First, try to match by genre
    if (genre != null && _categoryImages.containsKey(genre)) {
      final images = _categoryImages[genre]!;
      // Use name hash to consistently select same image for same event
      final index = (name?.hashCode ?? 0).abs() % images.length;
      return images[index];
    }

    // Then, try to match by segment
    if (segment != null && _segmentImages.containsKey(segment)) {
      return _segmentImages[segment]!;
    }

    // Try to infer from event name
    if (name != null) {
      final lowerName = name.toLowerCase();
      
      // Check for sports keywords
      if (lowerName.contains('futbol') || lowerName.contains('football') || 
          lowerName.contains('maç') || lowerName.contains('derbi')) {
        return _segmentImages['Football']!;
      }
      
      // Check for music keywords
      if (lowerName.contains('konser') || lowerName.contains('concert') || 
          lowerName.contains('müzik') || lowerName.contains('music')) {
        final musicImages = _categoryImages['Music']!;
        return musicImages[lowerName.hashCode.abs() % musicImages.length];
      }
      
      // Check for festival keywords
      if (lowerName.contains('festival') || lowerName.contains('fest')) {
        final festivalImages = _categoryImages['Festival']!;
        return festivalImages[lowerName.hashCode.abs() % festivalImages.length];
      }
    }

    // Return default event image
    return _defaultEventImage;
  }

  /// Check if an image URL is valid or a placeholder
  /// Returns true if the image is likely to be relevant
  static bool isValidEventImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return false;
    
    // Check if it's a random placeholder
    if (imageUrl.contains('picsum.photos') && imageUrl.contains('random')) {
      return false;
    }
    
    // Check if it's a Lorem Picsum placeholder
    if (imageUrl.contains('picsum.photos/id/')) {
      return false;
    }
    
    // Check if it's a placeholder.com image
    if (imageUrl.contains('placeholder.com')) {
      return false;
    }
    
    return true;
  }
}
