import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

/// Enhanced Map Service for StubStreet
/// 
/// This service provides centralized map functionality including:
/// - Custom map styling for better visual appeal
/// - Location services with permission handling
/// - Map utilities for common operations
/// - Performance optimizations
class MapService {
  // Singleton pattern for efficient resource management
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  /// Custom map style for a modern, clean appearance
  /// This style removes unnecessary UI elements and provides a professional look
  /// Must be a valid JSON array string as required by Google Maps SDK.
  static const String _customMapStyle = '''[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#bdbdbd"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#ffffff"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#dadada"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#c9c9c9"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  }
]''';

  /// Default map style for the application
  /// Returns the custom map style string for consistent appearance
  String get customMapStyle => _customMapStyle;

  /// Default camera position for Istanbul, Turkey
  /// This provides a good starting point for Turkish users
  static const CameraPosition defaultCameraPosition = CameraPosition(
    target: LatLng(41.0082, 28.9784), // Istanbul coordinates
    zoom: 10.0,
  );

  /// Default zoom levels for different map contexts
  static const Map<String, double> zoomLevels = {
    'city': 10.0,      // City-wide view
    'district': 13.0,   // District/neighborhood view
    'venue': 16.0,      // Venue/specific location view
    'street': 18.0,     // Street level view
  };

  /// Check if location services are enabled
  /// Returns true if location services are available and enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('Error checking location service: $e');
      return false;
    }
  }

  /// Request location permission from the user
  /// Returns the permission status after user interaction
  Future<LocationPermission> requestLocationPermission() async {
    try {
      // First check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // Request permission if not granted
        permission = await Geolocator.requestPermission();
      }
      
      return permission;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Get current user location with permission handling
  /// Returns the current position or null if unavailable
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return null;
      }

      // Check and request permission
      LocationPermission permission = await requestLocationPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied');
        return null;
      }

      // Get current position with high accuracy
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  /// Calculate distance between two points in kilometers
  /// Useful for showing event proximity to user location
  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    ) / 1000; // Convert meters to kilometers
  }

  /// Format distance for display (e.g., "2.5 km" or "500 m")
  /// Provides user-friendly distance representation
  String formatDistance(double distanceInKm) {
    if (distanceInKm < 1.0) {
      return '${(distanceInKm * 1000).round()} m';
    } else {
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
  }

  /// Create a custom marker icon with specified color
  /// Returns a BitmapDescriptor for consistent marker styling
  Future<BitmapDescriptor> createCustomMarkerIcon({
    Color color = Colors.red,
    String? label,
  }) async {
    // For now, return default marker with custom hue
    // In a production app, you could create custom marker images
    return BitmapDescriptor.defaultMarkerWithHue(
      _colorToHue(color),
    );
  }

  /// Convert Color to BitmapDescriptor hue value
  /// Maps common colors to appropriate hue values for markers
  double _colorToHue(Color color) {
    if (color == Colors.red) return BitmapDescriptor.hueRed;
    if (color == Colors.blue) return BitmapDescriptor.hueBlue;
    if (color == Colors.green) return BitmapDescriptor.hueGreen;
    if (color == Colors.yellow) return BitmapDescriptor.hueYellow;
    if (color == Colors.orange) return BitmapDescriptor.hueOrange;
    if (color == Colors.purple) return BitmapDescriptor.hueViolet;
    if (color == Colors.pink) return BitmapDescriptor.hueRose;
    return BitmapDescriptor.hueRed; // Default to red
  }



  /// Animate camera to specific location with smooth transition
  /// Provides smooth user experience when navigating to locations
  Future<void> animateToLocation(
    GoogleMapController controller,
    LatLng target,
    {double zoom = 16.0, Duration duration = const Duration(milliseconds: 500)}
  ) async {
    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: target,
            zoom: zoom,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error animating camera: $e');
    }
  }

  /// Get nearby venues within specified radius
  /// Useful for showing events near user location
  List<LatLng> getNearbyVenues(LatLng center, double radiusKm) {
    // This is a placeholder implementation
    // In a real app, you would integrate with a venue database or API
    return [];
  }

  /// Validate coordinates are within reasonable bounds
  /// Prevents invalid coordinates from causing map errors
  bool isValidCoordinate(LatLng coordinate) {
    return coordinate.latitude >= -90 && coordinate.latitude <= 90 &&
           coordinate.longitude >= -180 && coordinate.longitude <= 180;
  }

  /// Get map type based on user preference or context
  /// Provides different map views for different use cases
  MapType getMapType(String context) {
    switch (context.toLowerCase()) {
      case 'satellite':
        return MapType.satellite;
      case 'terrain':
        return MapType.terrain;
      case 'hybrid':
        return MapType.hybrid;
      default:
        return MapType.normal;
    }
  }
}
