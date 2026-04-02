// lib/features/auth/presentation/widgets/location_picker_widget.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/data/location_data.dart';
import 'location_picker_dialog.dart';

class LocationPickerWidget extends StatefulWidget {
  final String? initialLocation;
  final Function(String location) onLocationSelected;
  final bool allowMapSelection;

  const LocationPickerWidget({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
    this.allowMapSelection = true,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  String? selectedCountry;
  String? selectedProvince; // Türkiye için il
  String? selectedDistrict; // Türkiye için ilçe
  String? selectedCity; // Diğer ülkeler için şehir
  bool isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  void _initializeLocation() {
    final parsed = LocationData.parseLocation(widget.initialLocation);
    if (parsed != null) {
      setState(() {
        selectedCountry = parsed['country'];
        
        if (selectedCountry == 'Türkiye') {
          selectedProvince = parsed['province'];
          selectedDistrict = parsed['district'];
        } else {
          selectedCity = parsed['city'];
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoadingLocation = true;
    });

    try {
      // Konum izni kontrolü
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Konum izni reddedildi'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konum izni kalıcı olarak reddedildi. Lütfen ayarlardan izin verin.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Mevcut konumu al
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Koordinatları adrese çevir
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        
        // Türkiye'deki bir konum mu kontrol et
        if (place.country == 'Turkey' || place.country == 'Türkiye') {
          setState(() {
            selectedCountry = 'Türkiye';
            // İl ve ilçeyi bul
            final province = place.administrativeArea ?? '';
            final district = place.subAdministrativeArea ?? place.locality ?? '';
            
            if (LocationData.getTurkeyProvinces().contains(province)) {
              selectedProvince = province;
              if (LocationData.getTurkeyDistricts(province).contains(district)) {
                selectedDistrict = district;
                widget.onLocationSelected(
                  LocationData.formatLocation(district, 'Türkiye', province: province)
                );
              }
            }
          });
        } else {
          // Diğer ülkeler için
          final country = _findCountryInList(place.country ?? '');
          if (country != null) {
            setState(() {
              selectedCountry = country;
              selectedCity = place.locality ?? place.administrativeArea;
              if (selectedCity != null) {
                widget.onLocationSelected(LocationData.formatLocation(selectedCity!, country));
              }
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konum alınamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isLoadingLocation = false;
      });
    }
  }

  String? _findCountryInList(String countryName) {
    // İngilizce ülke adlarını Türkçe karşılıklarıyla eşleştir
    final countryMap = {
      'Turkey': 'Türkiye',
      'United States': 'Amerika Birleşik Devletleri',
      'Germany': 'Almanya',
      'United Kingdom': 'İngiltere',
      'France': 'Fransa',
    };

    return countryMap[countryName] ?? 
           LocationData.countries.firstWhere(
             (c) => c.toLowerCase() == countryName.toLowerCase(),
             orElse: () => '',
           );
  }

  Future<void> _selectFromMap() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const LocationPickerDialog(),
    );

    if (result != null) {
      setState(() {
        selectedCountry = result['country'];
        
        if (selectedCountry == 'Türkiye') {
          selectedProvince = result['province'];
          selectedDistrict = result['district'];
          selectedCity = null;
        } else {
          selectedCity = result['city'];
          selectedProvince = null;
          selectedDistrict = null;
        }
      });
      
      if (selectedCountry == 'Türkiye' && selectedProvince != null && selectedDistrict != null) {
        widget.onLocationSelected(
          LocationData.formatLocation(selectedDistrict!, 'Türkiye', province: selectedProvince!)
        );
      } else if (selectedCity != null && selectedCountry != null) {
        widget.onLocationSelected(
          LocationData.formatLocation(selectedCity!, selectedCountry!)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Konum',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // Ülke seçimi
        DropdownButtonFormField<String>(
          key: ValueKey('country-$selectedCountry'),
          initialValue: selectedCountry != null && 
                 LocationData.countries.contains(selectedCountry)
              ? selectedCountry
              : null,
          decoration: const InputDecoration(
            labelText: 'Ülke',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: LocationData.countries.map((country) {
            return DropdownMenuItem(
              value: country,
              child: Text(country),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedCountry = value;
              // Seçimleri sıfırla
              selectedProvince = null;
              selectedDistrict = null;
              selectedCity = null;
            });
          },
        ),
        
        const SizedBox(height: 12),
        
        // Türkiye için il seçimi, diğer ülkeler için şehir seçimi
        if (selectedCountry == 'Türkiye') ...[
          // İl seçimi
          DropdownButtonFormField<String>(
            key: ValueKey('province-$selectedProvince'),
            initialValue: selectedProvince != null && 
                   LocationData.getTurkeyProvinces().contains(selectedProvince)
                ? selectedProvince
                : null,
            decoration: const InputDecoration(
              labelText: 'İl',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: LocationData.getTurkeyProvinces().map((province) {
              return DropdownMenuItem(
                value: province,
                child: Text(province),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedProvince = value;
                selectedDistrict = null; // İlçe seçimini sıfırla
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // İlçe seçimi
          DropdownButtonFormField<String>(
            key: ValueKey('district-$selectedProvince-$selectedDistrict'),
            initialValue: selectedProvince != null && 
                   selectedDistrict != null && 
                   LocationData.getTurkeyDistricts(selectedProvince!).contains(selectedDistrict)
                ? selectedDistrict
                : null,
            decoration: const InputDecoration(
              labelText: 'İlçe',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: selectedProvince == null
                ? []
                : LocationData.getTurkeyDistricts(selectedProvince!).map((district) {
                    return DropdownMenuItem(
                      value: district,
                      child: Text(district),
                    );
                  }).toList(),
            onChanged: selectedProvince == null
                ? null
                : (value) {
                    setState(() {
                      selectedDistrict = value;
                    });
                    if (value != null) {
                      widget.onLocationSelected(
                        LocationData.formatLocation(value, 'Türkiye', province: selectedProvince!)
                      );
                    }
                  },
          ),
        ] else if (selectedCountry != null) ...[
          // Diğer ülkeler için şehir seçimi
          DropdownButtonFormField<String>(
            key: ValueKey('city-$selectedCountry-$selectedCity'),
            initialValue: selectedCity != null && 
                   LocationData.getCities(selectedCountry!).contains(selectedCity)
                ? selectedCity
                : null,
            decoration: const InputDecoration(
              labelText: 'Şehir',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: LocationData.getCities(selectedCountry!).map((city) {
              return DropdownMenuItem(
                value: city,
                child: Text(city),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCity = value;
              });
              if (value != null) {
                widget.onLocationSelected(
                  LocationData.formatLocation(value, selectedCountry!)
                );
              }
            },
          ),
        ],
        
        const SizedBox(height: 12),
        
        // Konum butonları
        Row(
          children: [
            // Mevcut konumu al
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoadingLocation ? null : _getCurrentLocation,
                icon: isLoadingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, size: 18),
                label: Text(
                  isLoadingLocation ? 'Alınıyor...' : 'Mevcut Konum',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            
            if (widget.allowMapSelection) ...[
              const SizedBox(width: 8),
              // Haritadan seç
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectFromMap,
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text(
                    'Haritadan Seç',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
        
        // Seçilen konumu göster
        if ((selectedCountry == 'Türkiye' && selectedProvince != null && selectedDistrict != null) ||
            (selectedCountry != null && selectedCountry != 'Türkiye' && selectedCity != null)) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    selectedCountry == 'Türkiye'
                        ? LocationData.formatLocation(selectedDistrict!, 'Türkiye', province: selectedProvince!)
                        : LocationData.formatLocation(selectedCity!, selectedCountry!),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}