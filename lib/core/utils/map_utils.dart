import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

/// Map Utilities for StubStreet
/// 
/// This utility class provides common map operations and helper functions:
/// - Marker creation and styling
/// - Map bounds calculations
/// - Distance and proximity calculations
/// - Map interaction helpers
class MapUtils {
  /// Create a custom marker with consistent styling
  /// 
  /// @param id: Unique identifier for the marker
  /// @param position: Geographic coordinates for the marker
  /// @param title: Title to display in info window
  /// @param snippet: Additional information to display
  /// @param color: Color theme for the marker (defaults to blue)
  /// @param onTap: Callback when marker is tapped
  /// 
  /// @returns: Configured Marker widget
  static Marker createMarker({
    required String id,
    required LatLng position,
    required String title,
    String? snippet,
    Color color = Colors.blue,
    VoidCallback? onTap,
  }) {
    return Marker(
      markerId: MarkerId(id),
      position: position,
      infoWindow: InfoWindow(
        title: title,
        snippet: snippet,
        onTap: onTap,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        _colorToHue(color),
      ),
      // Enable marker interaction
      consumeTapEvents: true,
      // Add subtle animation
      flat: false,
      // Ensure marker is visible
      visible: true,
    );
  }

  /// Create a venue marker for events and locations
  /// 
  /// @param id: Unique identifier for the venue
  /// @param position: Geographic coordinates for the venue
  /// @param name: Name of the venue
  /// @param address: Address or location description
  /// @param eventCount: Number of events at this venue (optional)
  /// 
  /// @returns: Configured venue Marker widget
  static Marker createVenueMarker({
    required String id,
    required LatLng position,
    required String name,
    String? address,
    int? eventCount,
  }) {
    String snippet = address ?? 'Konum bilgisi mevcut değil';
    if (eventCount != null && eventCount > 0) {
      snippet += ' • $eventCount etkinlik';
    }

    return createMarker(
      id: id,
      position: position,
      title: name,
      snippet: snippet,
      color: Colors.red, // Red for venues
    );
  }

  /// Create an event marker for specific events
  /// 
  /// @param id: Unique identifier for the event
  /// @param position: Geographic coordinates for the event
  /// @param title: Event title
  /// @param venue: Venue name
  /// @param date: Event date (optional)
  /// @param price: Event price (optional)
  /// 
  /// @returns: Configured event Marker widget
  static Marker createEventMarker({
    required String id,
    required LatLng position,
    required String title,
    required String venue,
    String? date,
    String? price,
  }) {
    String snippet = venue;
    if (date != null) snippet += ' • $date';
    if (price != null) snippet += ' • $price';

    return createMarker(
      id: id,
      position: position,
      title: title,
      snippet: snippet,
      color: Colors.green, // Green for events
    );
  }

  /// Convert Color to BitmapDescriptor hue value
  /// 
  /// @param color: Flutter Color object
  /// @returns: Appropriate hue value for map markers
  static double _colorToHue(Color color) {
    if (color == Colors.red) return BitmapDescriptor.hueRed;
    if (color == Colors.blue) return BitmapDescriptor.hueBlue;
    if (color == Colors.green) return BitmapDescriptor.hueGreen;
    if (color == Colors.yellow) return BitmapDescriptor.hueYellow;
    if (color == Colors.orange) return BitmapDescriptor.hueOrange;
    if (color == Colors.purple) return BitmapDescriptor.hueViolet;
    if (color == Colors.pink) return BitmapDescriptor.hueRose;
    if (color == Colors.cyan) return BitmapDescriptor.hueCyan;
    if (color == Colors.teal) return BitmapDescriptor.hueAzure;
    return BitmapDescriptor.hueRed; // Default to red
  }

  /// Calculate bounds that encompass all markers
  /// 
  /// @param markers: Set of markers to calculate bounds for
  /// @param padding: Additional padding around the bounds (in degrees)
  /// @returns: LatLngBounds that contains all markers
  static LatLngBounds calculateBounds(
    Set<Marker> markers, {
    double padding = 0.01, // Approximately 1km at equator
  }) {
    if (markers.isEmpty) {
      // Default to Istanbul if no markers
      return LatLngBounds(
        southwest: const LatLng(40.8, 28.5),
        northeast: const LatLng(41.2, 29.5),
      );
    }

    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;

    for (final marker in markers) {
      final position = marker.position;
      minLat = min(minLat, position.latitude);
      maxLat = max(maxLat, position.latitude);
      minLng = min(minLng, position.longitude);
      maxLng = max(maxLng, position.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );
  }

  /// Calculate optimal zoom level for given bounds
  /// 
  /// @param bounds: Geographic bounds to fit
  /// @param screenSize: Size of the map container
  /// @returns: Optimal zoom level (0.0 to 20.0)
  static double calculateOptimalZoom(
    LatLngBounds bounds,
    Size screenSize,
  ) {
    final latDiff = (bounds.northeast.latitude - bounds.southwest.latitude).abs();
    final lngDiff = (bounds.northeast.longitude - bounds.southwest.longitude).abs();
    
    // Calculate zoom based on the larger dimension
    final maxDiff = max(latDiff, lngDiff);
    
    // Convert difference to zoom level
    // This is an approximation - in practice, you might want to use
    // Google Maps' built-in bounds fitting
    if (maxDiff > 10.0) return 5.0;
    if (maxDiff > 5.0) return 6.0;
    if (maxDiff > 2.0) return 7.0;
    if (maxDiff > 1.0) return 8.0;
    if (maxDiff > 0.5) return 9.0;
    if (maxDiff > 0.2) return 10.0;
    if (maxDiff > 0.1) return 11.0;
    if (maxDiff > 0.05) return 12.0;
    if (maxDiff > 0.02) return 13.0;
    if (maxDiff > 0.01) return 14.0;
    if (maxDiff > 0.005) return 15.0;
    if (maxDiff > 0.002) return 16.0;
    if (maxDiff > 0.001) return 17.0;
    return 18.0;
  }

  /// Calculate distance between two points in kilometers
  /// 
  /// @param point1: First geographic point
  /// @param point2: Second geographic point
  /// @returns: Distance in kilometers
  static double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    ) / 1000; // Convert meters to kilometers
  }

  /// Format distance for user-friendly display
  /// 
  /// @param distanceInKm: Distance in kilometers
  /// @returns: Formatted distance string (e.g., "2.5 km" or "500 m")
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1.0) {
      return '${(distanceInKm * 1000).round()} m';
    } else if (distanceInKm < 10.0) {
      return '${distanceInKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceInKm.round()} km';
    }
  }

  /// Check if a location is nearby (within specified radius)
  /// 
  /// @param center: Center point for proximity check
  /// @param target: Target point to check
  /// @param radiusKm: Radius in kilometers (default: 5.0)
  /// @returns: True if target is within the specified radius
  static bool isNearby(
    LatLng center,
    LatLng target, {
    double radiusKm = 5.0,
  }) {
    final distance = calculateDistance(center, target);
    return distance <= radiusKm;
  }

  /// Get nearby locations from a list
  /// 
  /// @param center: Center point for proximity check
  /// @param locations: List of locations to check
  /// @param radiusKm: Radius in kilometers (default: 5.0)
  /// @returns: List of locations within the specified radius
  static List<LatLng> getNearbyLocations(
    LatLng center,
    List<LatLng> locations, {
    double radiusKm = 5.0,
  }) {
    return locations.where((location) => 
      isNearby(center, location, radiusKm: radiusKm)
    ).toList();
  }

  /// Validate geographic coordinates
  /// 
  /// @param coordinate: Coordinate to validate
  /// @returns: True if coordinates are within valid bounds
  static bool isValidCoordinate(LatLng coordinate) {
    return coordinate.latitude >= -90 && coordinate.latitude <= 90 &&
           coordinate.longitude >= -180 && coordinate.longitude <= 180;
  }

  /// Get map type based on context or user preference
  /// 
  /// @param context: Context string (e.g., 'satellite', 'terrain')
  /// @returns: Appropriate MapType for the context
  static MapType getMapType(String context) {
    switch (context.toLowerCase()) {
      case 'satellite':
        return MapType.satellite;
      case 'terrain':
        return MapType.terrain;
      case 'hybrid':
        return MapType.hybrid;
      case 'normal':
      default:
        return MapType.normal;
    }
  }

  /// Create a camera update to fit bounds
  /// 
  /// @param bounds: Geographic bounds to fit
  /// @param padding: Padding around the bounds (in pixels)
  /// @returns: CameraUpdate that will fit the bounds
  static CameraUpdate fitBounds(
    LatLngBounds bounds, {
    double padding = 50.0,
  }) {
    return CameraUpdate.newLatLngBounds(bounds, padding);
  }

  /// Create a camera update to animate to a location
  /// 
  /// @param target: Target location
  /// @param zoom: Zoom level (default: 15.0)
  /// @returns: CameraUpdate that will animate to the target
  static CameraUpdate animateToLocation(
    LatLng target, {
    double zoom = 15.0,
  }) {
    return CameraUpdate.newCameraPosition(
      CameraPosition(
        target: target,
        zoom: zoom,
      ),
    );
  }

  /// Get default camera position for Turkey (Istanbul)
  /// 
  /// @returns: Default camera position centered on Istanbul
  static CameraPosition getDefaultCameraPosition() {
    return const CameraPosition(
      target: LatLng(41.0082, 28.9784), // Istanbul
      zoom: 10.0,
    );
  }

  /// Get zoom levels for different contexts
  /// 
  /// @returns: Map of context names to zoom levels
  static Map<String, double> getZoomLevels() {
    return {
      'country': 6.0,      // Country-wide view
      'region': 8.0,       // Regional view
      'city': 10.0,        // City-wide view
      'district': 13.0,    // District/neighborhood view
      'venue': 16.0,       // Venue/specific location view
      'street': 18.0,      // Street level view
      'building': 20.0,    // Building level view
    };
  }
}
