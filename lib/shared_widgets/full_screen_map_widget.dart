import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../features/tickets/domain/entities/ticket.dart';
import 'enhanced_map_widget.dart';

/// Tam ekran harita widget'ı
/// Bilet konumunu tam ekranda gösterir ve Google Maps'e yönlendirme seçeneği sunar
class FullScreenMapWidget extends StatefulWidget {
  final Ticket ticket;

  const FullScreenMapWidget({
    super.key,
    required this.ticket,
  });

  @override
  State<FullScreenMapWidget> createState() => _FullScreenMapWidgetState();
}

class _FullScreenMapWidgetState extends State<FullScreenMapWidget> {
  // GoogleMapController'ı gerektiğinde kullanmak için saklıyoruz
  // ignore: unused_field
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (widget.ticket.latitude == null || widget.ticket.longitude == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Konum Bilgisi'),
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Bu bilet için konum bilgisi bulunmuyor',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ticket.title),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          // Google Maps'te aç butonu
          IconButton(
            onPressed: _openInGoogleMaps,
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Google Maps\'te Aç',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Tam ekran harita
          EnhancedMapWidget(
            height: double.infinity,
            width: double.infinity,
            borderRadius: 0,
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.ticket.latitude!, widget.ticket.longitude!),
              zoom: 16,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('event_location'),
                position: LatLng(widget.ticket.latitude!, widget.ticket.longitude!),
                infoWindow: InfoWindow(
                  title: widget.ticket.title,
                  snippet: widget.ticket.locationName ?? widget.ticket.venue,
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue,
                ),
              ),
            },
            showMyLocation: true,
            showLocationButton: true,
            showZoomControls: true,
            showMapToolbar: true,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
          ),
          
          // Alt bilgi kartı
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.ticket.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.ticket.locationName ?? 
                            '${widget.ticket.venue}, ${widget.ticket.city}',
                            style: theme.textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openInGoogleMaps,
                            icon: const Icon(Icons.directions),
                            label: const Text('Yol Tarifi Al'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _shareLocation,
                            icon: const Icon(Icons.share),
                            label: const Text('Konumu Paylaş'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Google Maps'te konumu açar
  Future<void> _openInGoogleMaps() async {
    final lat = widget.ticket.latitude!;
    final lng = widget.ticket.longitude!;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng'
    );
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          _showErrorSnackBar('Google Maps açılamadı');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Harita açılırken hata oluştu: $e');
      }
    }
  }

  /// Konumu paylaşır
  Future<void> _shareLocation() async {
    final lat = widget.ticket.latitude!;
    final lng = widget.ticket.longitude!;

    try {
      // Share+ package kullanarak paylaş
      // Bu kısım share_plus package'ı gerektirir
      // Şimdilik basit bir yaklaşım kullanacağız
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konum bilgisi: $lat, $lng'),
            action: SnackBarAction(
              label: 'Tamam',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Konum paylaşılırken hata oluştu: $e');
      }
    }
  }

  /// Hata mesajı gösterir
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
