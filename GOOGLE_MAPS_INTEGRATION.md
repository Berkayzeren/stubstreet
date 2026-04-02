# Google Maps Integration Guide

## Overview

StubStreet now includes comprehensive Google Maps integration to enhance the user experience with location-based features. This integration provides:

- **Interactive Maps**: Display event locations, venues, and user proximity
- **Location Services**: Get user's current location with permission handling
- **Custom Styling**: Modern, clean map appearance optimized for the app
- **Enhanced UX**: Smooth animations, custom controls, and intuitive interactions

## Configuration

### API Key Setup

The app is configured with the following Google Maps API key:
```
AIzaSyB-o1FgG4Hn7uVmnxlhrryBC1BfJAmhFFI
```

### Platform Configuration

#### Android
- **File**: `android/app/src/main/AndroidManifest.xml`
- **API Key**: Added via `<meta-data>` tag
- **Permissions**: Location permissions for enhanced functionality
- **Google Play Services**: Enabled for better performance

#### iOS
- **File**: `ios/Runner/Info.plist`
- **API Key**: Added via `GMSApiKey` key
- **Permissions**: Location usage descriptions in Turkish

## Architecture

### Core Components

#### 1. MapService (`lib/core/services/map_service.dart`)
Centralized service for map operations:
- Custom map styling
- Location permission handling
- Distance calculations
- Map utilities

#### 2. EnhancedMapWidget (`lib/shared_widgets/enhanced_map_widget.dart`)
Reusable map widget with enhanced UX:
- Custom styling and controls
- Location services integration
- Permission handling
- Loading states and error handling

#### 3. LocationProvider (`lib/core/providers/location_provider.dart`)
Riverpod provider for location state management:
- Permission status
- Current location
- Service availability
- Error handling

#### 4. MapUtils (`lib/core/utils/map_utils.dart`)
Utility functions for common map operations:
- Marker creation
- Bounds calculations
- Distance formatting
- Map interactions

## Features

### Custom Map Styling
The app uses a custom map style that provides:
- Clean, modern appearance
- Reduced visual clutter
- Professional look and feel
- Consistent branding

### Location Services
- **Permission Handling**: Graceful permission requests
- **Current Location**: Get user's location with high accuracy
- **Proximity Detection**: Calculate distances between locations
- **Nearby Events**: Show events within specified radius

### Enhanced User Experience
- **Smooth Animations**: Camera transitions and zoom effects
- **Custom Controls**: Location button, zoom controls, and map toolbar
- **Responsive Design**: Adapts to different screen sizes
- **Loading States**: Visual feedback during operations
- **Error Handling**: User-friendly error messages

## Usage Examples

### Basic Map Display
```dart
EnhancedMapWidget(
  height: 200,
  width: double.infinity,
  borderRadius: 12,
  initialCameraPosition: CameraPosition(
    target: LatLng(41.0082, 28.9784), // Istanbul
    zoom: 15,
  ),
  markers: markers,
  showMyLocation: true,
  showLocationButton: true,
)
```

### Full-Screen Map
```dart
EnhancedMapWidget(
  borderRadius: 0, // Full screen
  showMyLocation: true,
  showLocationButton: true,
  showZoomControls: true,
  showMapToolbar: true,
)
```

### Custom Markers
```dart
// Create venue marker
final venueMarker = MapUtils.createVenueMarker(
  id: 'venue_1',
  position: LatLng(lat, lng),
  name: 'Vodafone Park',
  address: 'Beşiktaş, İstanbul',
  eventCount: 5,
);

// Create event marker
final eventMarker = MapUtils.createEventMarker(
  id: 'event_1',
  position: LatLng(lat, lng),
  title: 'Beşiktaş vs Galatasaray',
  venue: 'Vodafone Park',
  date: '15 Mart 2024',
  price: '₺150',
);
```

## Location Permission Flow

1. **Initial Check**: App checks location service availability
2. **Permission Request**: User is prompted for location permission
3. **Permission Handling**: App handles granted/denied permissions
4. **Location Access**: If granted, app accesses current location
5. **User Feedback**: Clear feedback on permission status

## Performance Optimizations

- **Lazy Loading**: Maps load only when needed
- **Efficient Markers**: Optimized marker rendering
- **Memory Management**: Proper disposal of map controllers
- **Caching**: Location data caching for better performance

## Error Handling

The integration includes comprehensive error handling:
- **Network Issues**: Graceful fallbacks for map loading failures
- **Permission Denied**: User-friendly permission request dialogs
- **Location Unavailable**: Clear messaging when location can't be obtained
- **Map Errors**: Fallback to default map behavior

## Testing

### Test Scenarios
- [ ] Map loads correctly with API key
- [ ] Location permissions work on both platforms
- [ ] Markers display correctly
- [ ] Map interactions (zoom, pan, tap) work
- [ ] Location services function properly
- [ ] Error handling works for various failure scenarios

### Test Commands
```bash
# Run tests
flutter test

# Run integration tests
flutter test integration_test/

# Check for linting issues
flutter analyze
```

## Troubleshooting

### Common Issues

#### 1. Maps Not Loading
- Verify API key is correct
- Check internet connectivity
- Ensure Google Play Services are updated (Android)
- Verify bundle ID matches Google Cloud Console

#### 2. Location Not Working
- Check location permissions in device settings
- Ensure location services are enabled
- Verify app has location permission
- Check if location is enabled in app settings

#### 3. Performance Issues
- Reduce number of markers
- Optimize map bounds
- Use appropriate zoom levels
- Implement marker clustering for large datasets

### Debug Information
Enable debug logging by setting:
```dart
if (kDebugMode) {
  debugPrint('Map debug info: $info');
}
```

## Future Enhancements

### Planned Features
- **Marker Clustering**: Group nearby markers for better performance
- **Custom Map Themes**: Multiple map style options
- **Offline Maps**: Cache map data for offline use
- **Route Planning**: Directions and navigation features
- **Heat Maps**: Visualize event density by location

### Integration Opportunities
- **Analytics**: Track map usage and user interactions
- **A/B Testing**: Test different map configurations
- **User Preferences**: Save user's map preferences
- **Social Features**: Share locations and routes

## Security Considerations

- **API Key Protection**: API key is embedded in app configuration
- **Permission Handling**: Only request necessary permissions
- **Data Privacy**: Location data is not stored unnecessarily
- **User Control**: Users can revoke location permissions

## Support

For issues related to Google Maps integration:
1. Check this documentation
2. Review Google Maps Flutter plugin documentation
3. Check platform-specific configuration
4. Verify API key and billing setup

## Dependencies

The integration uses the following packages:
- `google_maps_flutter: ^2.5.0` - Core map functionality
- `geolocator: ^10.1.0` - Location services
- `flutter_riverpod: ^2.6.1` - State management

## License

This integration follows the same license as the main StubStreet application.
