// lib/features/auth/presentation/widgets/location_picker_dialog.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/data/location_data.dart';

class LocationPickerDialog extends StatefulWidget {
  const LocationPickerDialog({super.key});

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  GoogleMapController? mapController;
  LatLng selectedLocation = const LatLng(39.9334, 32.8597); // Ankara default
  Set<Marker> markers = {};
  String? selectedAddress;
  String? selectedCity;
  String? selectedCountry;
  String? selectedProvince; // Türkiye için il
  String? selectedDistrict; // Türkiye için ilçe
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _addMarker(selectedLocation);
  }

  void _addMarker(LatLng position) {
    setState(() {
      markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: position,
          draggable: true,
          onDragEnd: (newPosition) {
            _onLocationSelected(newPosition);
          },
        ),
      };
    });
  }

  Future<void> _onLocationSelected(LatLng position) async {
    setState(() {
      selectedLocation = position;
      isLoading = true;
      _addMarker(position);
    });

    try {
      // Koordinatları adrese çevir
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        
        // Adresi formatla
        final street = place.street ?? '';
        final subLocality = place.subLocality ?? '';
        final locality = place.locality ?? '';
        final administrativeArea = place.administrativeArea ?? '';
        final country = place.country ?? '';

        setState(() {
          selectedAddress = [
            street,
            subLocality,
            locality,
            administrativeArea,
            country,
          ].where((s) => s.isNotEmpty).join(', ');

          // Türkiye için özel işleme
          if (country == 'Turkey' || country == 'Türkiye') {
            selectedCountry = 'Türkiye';
            
            // İl bilgisini al
            selectedProvince = administrativeArea;
            if (!LocationData.getTurkeyProvinces().contains(selectedProvince)) {
              selectedProvince = _findNearestProvince(administrativeArea, locality);
            }
            
            // İlçe bilgisini al
            selectedDistrict = place.subAdministrativeArea ?? locality;
            if (selectedProvince != null && 
                !LocationData.getTurkeyDistricts(selectedProvince!).contains(selectedDistrict)) {
              // En yakın ilçeyi bul veya merkez olarak işaretle
              selectedDistrict = _findNearestDistrict(selectedProvince!, selectedDistrict ?? '');
            }
            
            // Eski uyumluluk için
            selectedCity = null;
          } else {
            // Diğer ülkeler için
            selectedCountry = _mapCountryName(country);
            selectedCity = locality.isNotEmpty ? locality : administrativeArea;
            selectedProvince = null;
            selectedDistrict = null;
          }
        });
      }
    } catch (e) {
      setState(() {
        selectedAddress = 'Adres alınamadı';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _mapCountryName(String country) {
    final countryMap = {
      'Turkey': 'Türkiye',
      'United States': 'Amerika Birleşik Devletleri',
      'Germany': 'Almanya',
      'United Kingdom': 'İngiltere',
      'France': 'Fransa',
    };
    
    return countryMap[country] ?? country;
  }

  String? _findNearestProvince(String area, String locality) {
    // Bazı yaygın eşleştirmeler
    final provinceMappings = {
      'İstanbul Province': 'İstanbul',
      'Istanbul': 'İstanbul',
      'Ankara Province': 'Ankara',
      'İzmir Province': 'İzmir',
      'Izmir': 'İzmir',
      'Konya Province': 'Konya',
      'Zonguldak Province': 'Zonguldak',
      // Diğer büyük şehirler eklenebilir
    };

    // Önce direkt eşleştirme dene
    if (provinceMappings.containsKey(area)) {
      return provinceMappings[area];
    }
    if (provinceMappings.containsKey(locality)) {
      return provinceMappings[locality];
    }

    // İl listesinde benzer isim ara
    final provinces = LocationData.getTurkeyProvinces();
    for (final province in provinces) {
      if (area.contains(province) || locality.contains(province) ||
          province.contains(area) || province.contains(locality)) {
        return province;
      }
    }

    return null;
  }

  String? _findNearestDistrict(String province, String districtHint) {
    final districts = LocationData.getTurkeyDistricts(province);
    
    // Önce tam eşleşme ara
    if (districts.contains(districtHint)) {
      return districtHint;
    }
    
    // Benzer isim ara
    for (final district in districts) {
      if (districtHint.contains(district) || district.contains(districtHint)) {
        return district;
      }
    }
    
    // Bulunamazsa merkez ilçeyi döndür
    if (districts.contains('Merkez')) {
      return 'Merkez';
    }
    
    // İl adıyla aynı ilçe varsa onu döndür
    if (districts.contains(province)) {
      return province;
    }
    
    // Son çare: ilk ilçeyi döndür
    return districts.isNotEmpty ? districts.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: constraints.maxWidth * 0.9,
            height: constraints.maxHeight * 0.8,
            constraints: const BoxConstraints(
              maxWidth: 600,
              maxHeight: 800,
            ),
        child: Column(
          children: [
            // Başlık
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.map,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Haritadan Konum Seç',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Harita
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: selectedLocation,
                      zoom: 12,
                    ),
                    markers: markers,
                    onMapCreated: (controller) {
                      mapController = controller;
                    },
                    onTap: (position) {
                      _onLocationSelected(position);
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                    mapType: MapType.normal,
                  ),
                  
                  // Yükleniyor göstergesi
                  if (isLoading)
                    Positioned(
                      top: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Adres alınıyor...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  // Bilgi kartı
                  if (selectedAddress != null)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Card(
                        elevation: 8,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Seçilen Konum:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                selectedAddress!,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (selectedCountry == 'Türkiye' && selectedProvince != null && selectedDistrict != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$selectedDistrict, $selectedProvince, Türkiye',
                                    style: TextStyle(
                                      color: theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ] else if (selectedCity != null && selectedCountry != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$selectedCity, $selectedCountry',
                                    style: TextStyle(
                                      color: theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Alt butonlar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: ((selectedCountry == 'Türkiye' && selectedProvince != null && selectedDistrict != null) ||
                               (selectedCountry != null && selectedCountry != 'Türkiye' && selectedCity != null))
                        ? () {
                            if (selectedCountry == 'Türkiye') {
                              Navigator.of(context).pop({
                                'country': 'Türkiye',
                                'province': selectedProvince,
                                'district': selectedDistrict,
                                'latitude': selectedLocation.latitude,
                                'longitude': selectedLocation.longitude,
                              });
                            } else {
                              Navigator.of(context).pop({
                                'city': selectedCity,
                                'country': selectedCountry,
                                'latitude': selectedLocation.latitude,
                                'longitude': selectedLocation.longitude,
                              });
                            }
                          }
                        : null,
                    child: const Text('Konumu Seç'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      },
    ),
  );
  }
}
