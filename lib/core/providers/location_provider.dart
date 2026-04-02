import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/map_service.dart';

/// Location State class to hold location-related data
/// 
/// This class encapsulates all location-related state including:
/// - Current user position
/// - Permission status
/// - Service availability
/// - Loading states
class LocationState {
  final Position? currentPosition;
  final LocationPermission permission;
  final bool isServiceEnabled;
  final bool isLoading;
  final String? errorMessage;

  const LocationState({
    this.currentPosition,
    this.permission = LocationPermission.denied,
    this.isServiceEnabled = false,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Create a copy of this state with updated values
  LocationState copyWith({
    Position? currentPosition,
    LocationPermission? permission,
    bool? isServiceEnabled,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LocationState(
      currentPosition: currentPosition ?? this.currentPosition,
      permission: permission ?? this.permission,
      isServiceEnabled: isServiceEnabled ?? this.isServiceEnabled,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Check if location permission is granted
  bool get hasPermission => 
      permission == LocationPermission.whileInUse || 
      permission == LocationPermission.always;

  /// Check if location services are available
  bool get isAvailable => isServiceEnabled && hasPermission;

  /// Get current location as LatLng for map usage
  LatLng? get currentLatLng {
    if (currentPosition == null) return null;
    return LatLng(currentPosition!.latitude, currentPosition!.longitude);
  }
}

/// Location Provider for managing location state across the app
/// 
/// This provider handles:
/// - Location permission requests
/// - Current location updates
/// - Service availability checks
/// - Error handling and user feedback
class LocationNotifier extends StateNotifier<LocationState> {
  final MapService _mapService = MapService();

  LocationNotifier() : super(const LocationState()) {
    _initializeLocation();
  }

  /// Initialize location services and check current status
  Future<void> _initializeLocation() async {
    try {
      state = state.copyWith(isLoading: true);
      
      // Check if location services are enabled
      final isEnabled = await _mapService.isLocationServiceEnabled();
      
      // Check current permission status
      final permission = await _mapService.requestLocationPermission();
      
      state = state.copyWith(
        isServiceEnabled: isEnabled,
        permission: permission,
        isLoading: false,
      );
      
      // If we have permission, get current location
      if (state.hasPermission) {
        await getCurrentLocation();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Konum servisleri başlatılamadı: $e',
      );
    }
  }

  /// Request location permission from the user
  Future<void> requestPermission() async {
    try {
      state = state.copyWith(isLoading: true);
      
      final permission = await _mapService.requestLocationPermission();
      
      state = state.copyWith(
        permission: permission,
        isLoading: false,
      );
      
      // If permission granted, get current location
      if (state.hasPermission) {
        await getCurrentLocation();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Konum izni alınamadı: $e',
      );
    }
  }

  /// Get current user location
  Future<void> getCurrentLocation() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final position = await _mapService.getCurrentLocation();
      
      if (position != null) {
        state = state.copyWith(
          currentPosition: position,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Konum alınamadı',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Konum alınırken hata oluştu: $e',
      );
    }
  }

  /// Refresh location data
  Future<void> refreshLocation() async {
    await getCurrentLocation();
  }

  /// Clear current location data
  void clearLocation() {
    state = state.copyWith(
      currentPosition: null,
      errorMessage: null,
    );
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Calculate distance from current location to a target
  double? calculateDistanceTo(LatLng target) {
    if (state.currentLatLng == null) return null;
    
    return _mapService.calculateDistance(
      state.currentLatLng!,
      target,
    );
  }

  /// Format distance for display
  String? formatDistanceTo(LatLng target) {
    final distance = calculateDistanceTo(target);
    if (distance == null) return null;
    
    return _mapService.formatDistance(distance);
  }

  /// Check if a location is nearby (within specified radius)
  bool isNearby(LatLng target, {double radiusKm = 5.0}) {
    final distance = calculateDistanceTo(target);
    if (distance == null) return false;
    
    return distance <= radiusKm;
  }
}

/// Provider for location state management
/// 
/// This provider gives access to the LocationNotifier throughout the app
final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) => LocationNotifier(),
);

/// Provider for current location as LatLng
/// 
/// Convenience provider that returns just the current location coordinates
final currentLocationProvider = Provider<LatLng?>((ref) {
  final locationState = ref.watch(locationProvider);
  return locationState.currentLatLng;
});

/// Provider for location permission status
/// 
/// Convenience provider that returns just the permission status
final locationPermissionProvider = Provider<LocationPermission>((ref) {
  final locationState = ref.watch(locationProvider);
  return locationState.permission;
});

/// Provider for checking if location is available
/// 
/// Convenience provider that returns whether location services are available
final isLocationAvailableProvider = Provider<bool>((ref) {
  final locationState = ref.watch(locationProvider);
  return locationState.isAvailable;
});
