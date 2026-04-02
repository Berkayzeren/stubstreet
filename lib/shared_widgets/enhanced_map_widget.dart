import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../core/services/map_service.dart';

/// Enhanced Map Widget for StubStreet
/// 
/// This widget provides an improved map experience with:
/// - Custom map styling for better visual appeal
/// - Location services integration
/// - Smooth animations and transitions
/// - User-friendly controls and feedback
class EnhancedMapWidget extends StatefulWidget {
  /// Initial camera position for the map
  final CameraPosition? initialCameraPosition;
  
  /// List of markers to display on the map
  final Set<Marker>? markers;
  
  /// Whether to show user's current location
  final bool showMyLocation;
  
  /// Whether to show location button
  final bool showLocationButton;
  
  /// Whether to show zoom controls
  final bool showZoomControls;
  
  /// Whether to show map toolbar
  final bool showMapToolbar;
  
  /// Map type to display
  final MapType mapType;
  
  /// Callback when map is created
  final Function(GoogleMapController)? onMapCreated;
  
  /// Callback when camera position changes
  final Function(CameraPosition)? onCameraMove;
  
  /// Callback when map is tapped
  final Function(LatLng)? onMapTap;
  
  /// Height of the map widget
  final double? height;
  
  /// Width of the map widget
  final double? width;
  
  /// Border radius for the map container
  final double borderRadius;
  
  /// Whether to show a loading indicator
  final bool showLoadingIndicator;

  const EnhancedMapWidget({
    super.key,
    this.initialCameraPosition,
    this.markers,
    this.showMyLocation = true,
    this.showLocationButton = true,
    this.showZoomControls = false,
    this.showMapToolbar = false,
    this.mapType = MapType.normal,
    this.onMapCreated,
    this.onCameraMove,
    this.onMapTap,
    this.height,
    this.width,
    this.borderRadius = 12.0,
    this.showLoadingIndicator = true,
  });

  @override
  State<EnhancedMapWidget> createState() => _EnhancedMapWidgetState();
}

class _EnhancedMapWidgetState extends State<EnhancedMapWidget> {
  GoogleMapController? _mapController;
  final MapService _mapService = MapService();
  bool _isLoading = true;
  bool _hasLocationPermission = false;
  bool _isMapBuilt = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    
    // Reduce Maps SDK logging on Android/iOS to minimize ProxyAndroidLoggerBackend warnings
    _configureMapsLogging();
  }
  
  /// Configure Maps logging to reduce verbose output
  void _configureMapsLogging() {
    // This helps reduce ProxyAndroidLoggerBackend warnings from Google Maps SDK
    // The warnings are primarily due to excessive logging from the Maps native layer
    try {
      // Note: There's no direct Flutter API to control Google Maps SDK logging
      // The logging level is controlled at the native platform level
      // This method serves as a placeholder for future native channel communication
      // if needed to control logging verbosity
      debugPrint('Maps logging configured');
    } catch (e) {
      debugPrint('Maps logging configuration warning: $e');
    }
  }

  @override
  void dispose() {
    // Only dispose the controller if it's been created and the map is built
    if (_mapController != null && _isMapBuilt) {
      try {
        // Check if the controller is still valid before disposing
        if (mounted) {
          // Add a small delay to ensure the map is fully initialized
          Future.delayed(const Duration(milliseconds: 100), () {
            try {
              _mapController?.dispose();
            } catch (e) {
              // Ignore disposal errors on web as they can occur during hot reload
              debugPrint('Map controller disposal warning: $e');
            }
          });
        }
      } catch (e) {
        // Ignore disposal errors on web as they can occur during hot reload
        debugPrint('Map controller disposal warning: $e');
      } finally {
        _mapController = null;
        _isMapBuilt = false;
      }
    }
    super.dispose();
  }

  /// Initialize map with location services and permissions
  Future<void> _initializeMap() async {
    try {
      // Check location permission
      final permission = await _mapService.requestLocationPermission();
      _hasLocationPermission = permission == LocationPermission.whileInUse || 
                              permission == LocationPermission.always;
      
      // Get current location if permission granted
      if (_hasLocationPermission) {
        _currentPosition = await _mapService.getCurrentLocation();
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing map: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Handle map creation and apply custom styling
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _isMapBuilt = true;
    
    // Call user callback if provided
    widget.onMapCreated?.call(controller);
    
    // Only animate to current location if no initial camera position was provided
    // This ensures that when showing event locations, the map stays centered on the marker
    if (_currentPosition != null && 
        widget.showMyLocation && 
        widget.initialCameraPosition == null) {
      _animateToCurrentLocation();
    } else if (widget.initialCameraPosition != null && widget.markers?.isNotEmpty == true) {
      // If we have an initial position and markers, animate to ensure the marker is visible
      // This helps fix any rendering issues where the map might not center properly
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_mapController != null && mounted) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(widget.initialCameraPosition!),
          );
        }
      });
    }
  }

  /// Animate map to user's current location
  Future<void> _animateToCurrentLocation() async {
    if (_mapController != null && _isMapBuilt && _currentPosition != null) {
      final target = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      await _mapService.animateToLocation(
        _mapController!,
        target,
        zoom: MapService.zoomLevels['venue']!,
      );
    }
  }

  /// Get current location and animate to it
  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final position = await _mapService.getCurrentLocation();
      if (position != null) {
        _currentPosition = position;
        await _animateToCurrentLocation();
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error getting current location: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Konum alınamadı. Lütfen tekrar deneyin.'),
            action: SnackBarAction(
              label: 'Tamam',
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  /// Show location permission dialog
  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konum İzni Gerekli'),
        content: const Text(
          'Haritada mevcut konumunuzu gösterebilmek için konum iznine ihtiyacımız var. '
          'Bu izin, size yakındaki etkinlikleri göstermek için kullanılır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _requestLocationPermission();
            },
            child: const Text('İzin Ver'),
          ),
        ],
      ),
    );
  }

  /// Request location permission from user
  Future<void> _requestLocationPermission() async {
    final permission = await _mapService.requestLocationPermission();
    if (permission == LocationPermission.whileInUse || 
        permission == LocationPermission.always) {
      setState(() {
        _hasLocationPermission = true;
      });
      await _getCurrentLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determine initial camera position
    final initialPosition = widget.initialCameraPosition ?? 
                           (_currentPosition != null 
                             ? CameraPosition(
                                 target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                 zoom: MapService.zoomLevels['venue']!,
                               )
                             : MapService.defaultCameraPosition);

    return Container(
      height: widget.height,
      width: widget.width,
              decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Main map widget
          GoogleMap(
            initialCameraPosition: initialPosition,
            markers: widget.markers ?? {},
            onMapCreated: _onMapCreated,
            onCameraMove: widget.onCameraMove,
            onTap: widget.onMapTap,
            
            // Map configuration
            mapType: widget.mapType,
            myLocationEnabled: widget.showMyLocation && _hasLocationPermission,
            myLocationButtonEnabled: false, // We'll create a custom one
            zoomControlsEnabled: widget.showZoomControls,
            mapToolbarEnabled: widget.showMapToolbar,
            
            // Custom map styling
            // On web, ensure the Google Maps JS API is loaded via web/index.html
            // Otherwise, google_maps_flutter_web may throw `Cannot read properties of undefined (reading 'maps')`.
            style: _mapService.customMapStyle,
            
            // Gesture settings for better UX
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
            
            // Performance optimizations
            compassEnabled: true,
            trafficEnabled: false,
            buildingsEnabled: true,
            indoorViewEnabled: true,
          ),
          
          // Custom zoom controls
          if (!widget.showZoomControls)
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                children: [
                  FloatingActionButton(
                    heroTag: 'zoom_in',
                    mini: true,
                    backgroundColor: theme.colorScheme.surface,
                    foregroundColor: theme.colorScheme.onSurface,
                    onPressed: () {
                      if (_mapController != null && _isMapBuilt) {
                        _mapController!.animateCamera(
                          CameraUpdate.zoomIn(),
                        );
                      }
                    },
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'zoom_out',
                    mini: true,
                    backgroundColor: theme.colorScheme.surface,
                    foregroundColor: theme.colorScheme.onSurface,
                    onPressed: () {
                      if (_mapController != null && _isMapBuilt) {
                        _mapController!.animateCamera(
                          CameraUpdate.zoomOut(),
                        );
                      }
                    },
                    child: const Icon(Icons.remove),
                  ),
                ],
              ),
            ),
          
          // Custom location button - position at top right to avoid overlap with zoom controls
          if (widget.showLocationButton)
            Positioned(
              right: 16,
              top: 16,
              child: FloatingActionButton(
                heroTag: 'location_button',
                mini: true,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                onPressed: _hasLocationPermission 
                    ? _getCurrentLocation 
                    : _showLocationPermissionDialog,
                child: Icon(
                  _hasLocationPermission ? Icons.my_location : Icons.location_disabled,
                ),
              ),
            ),
          
          // Loading indicator
          if (_isLoading && widget.showLoadingIndicator)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          
          // Location permission banner
          if (!_hasLocationPermission && widget.showMyLocation)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
                              child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 16,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Konum izni gerekli',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _requestLocationPermission,
                      child: const Text('İzin Ver'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
