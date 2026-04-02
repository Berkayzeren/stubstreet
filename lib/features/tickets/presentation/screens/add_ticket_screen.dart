
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../domain/entities/ticket.dart';
import '../providers/ticket_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/ticket_form_field.dart';

class AddTicketScreen extends ConsumerStatefulWidget {
  const AddTicketScreen({super.key});

  @override
  ConsumerState<AddTicketScreen> createState() => _AddTicketScreenState();
}

class _AddTicketScreenState extends ConsumerState<AddTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  final _cityController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _seatInfoController = TextEditingController();
  final _locationNameController =
      TextEditingController(); // Konum açıklaması için

  TicketCategory _selectedCategory = TicketCategory.concert;
  DateTime _eventDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _eventTime = TimeOfDay.now();
  bool _isLoading = false;

  // Konum bilgileri
  double? _selectedLatitude;
  double? _selectedLongitude;

  // Resim için değişkenler
  XFile? _selectedImage;
  Uint8List? _imageBytes; // Web için byte data
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _refreshTicketProviders({String? userId}) async {
    final effectiveUserId =
        userId ?? ref.read(authStateChangesProvider).value?.uid;

    ref.invalidate(ticketsProvider);
    ref.invalidate(ticketsByCategoryProvider);
    ref.read(searchResultsProvider.notifier).clearResults();

    if (effectiveUserId != null) {
      ref.invalidate(userTicketsProvider(effectiveUserId));
    }

    try {
      final _ = await ref.refresh(ticketsProvider.future);
    } catch (_) {
      ref.invalidate(ticketsProvider);
    }
  }

  Future<void> _handleManualRefresh() => _refreshTicketProviders();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _cityController.dispose();
    _originalPriceController.dispose();
    _sellingPriceController.dispose();
    _seatInfoController.dispose();
    super.dispose();
  }

  /// Resim seçme fonksiyonu
  /// Kullanıcıya galeri veya kamera seçenekleri sunar
  Future<void> _pickImage() async {
    debugPrint('🔍 DEBUG: _pickImage çağrıldı');
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeriden Seç'),
              onTap: () async {
                debugPrint('🔍 DEBUG: Galeri seçeneği tıklandı');
                Navigator.pop(context);
                try {
                  final XFile? image = await _imagePicker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1080,
                    maxHeight: 1080,
                    imageQuality: 80,
                  );
                  debugPrint('🔍 DEBUG: Image picker sonucu: $image');
                  if (image != null) {
                    // Web için byte data'yı al
                    debugPrint(
                      '🔍 DEBUG: Resim seçildi, byte data okunuyor...',
                    );
                    final bytes = await image.readAsBytes();
                    debugPrint(
                      '🔍 DEBUG: Byte data okundu, boyut: ${bytes.length}',
                    );
                    setState(() {
                      _selectedImage = image;
                      _imageBytes = bytes;
                    });
                    debugPrint('✅ DEBUG: Resim state\'e kaydedildi');
                  } else {
                    debugPrint('⚠️ DEBUG: Resim seçilmedi (null)');
                  }
                } catch (e) {
                  debugPrint('❌ DEBUG: Resim seçerken hata: $e');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera ile Çek'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _imagePicker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 1080,
                  maxHeight: 1080,
                  imageQuality: 80,
                );
                if (image != null) {
                  // Web için byte data'yı al
                  final bytes = await image.readAsBytes();
                  setState(() {
                    _selectedImage = image;
                    _imageBytes = bytes;
                  });
                }
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Resmi Kaldır'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _imageBytes = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateChangesProvider);

    // Authentication kontrolü - login olmayan kullanıcıları engelle
    return authState.when(
      data: (user) {
        if (user == null) {
          // User not authenticated - show login prompt
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 80,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Bilet Eklemek İçin\nGiriş Yapmanız Gerekli',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bilet ekleyebilmek için lütfen önce hesabınıza giriş yapın.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Geri Dön'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // User authenticated - show normal add ticket screen
        return _buildAddTicketForm(theme);
      },
      loading: () =>
          Scaffold(body: const Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              Text('Bir hata oluştu', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddTicketForm(ThemeData theme) {
    return Scaffold(
      // Üst bar tamamen kaldırıldı (istek üzerine)
      appBar: null,
      body: RefreshIndicator(
        onRefresh: _handleManualRefresh,
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            // Üste gereksiz boşluğu azaltmak için top padding'i düşürdük
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            children: [
              // Üst başlık/geri çubuğu kaldırıldı
              // Kategori seçimi
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kategori',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: TicketCategory.values.map((category) {
                          return ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(category.icon),
                                const SizedBox(width: 4),
                                Text(category.displayName),
                              ],
                            ),
                            selected: _selectedCategory == category,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Resim seçimi - Opsiyonel
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.photo_camera, color: theme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Etkinlik Resmi (Opsiyonel)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Önizleme görünürlüğünü, platformdan bağımsız şekilde güvenilir hale getirmek için
                      // _imageBytes varlığını birincil kriter olarak kullanıyoruz.
                      // Neden: Web'de dosya sistemi erişimi yoktur ve en güvenilir kaynak RAM'e okunan byte'lardır.
                      // Mobilde ise hem byte verisi hem de geçici dosya yolu mevcuttur; mümkün olduğunda yine byte'ı kullanırız.
                      if (_imageBytes != null || (!kIsWeb && _selectedImage != null)) ...[
                        // Seçilen resmi göster
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _imageBytes != null
                                ? Image.memory(
                                    _imageBytes!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade300,
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 50,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : (!kIsWeb && _selectedImage != null)
                                    ? Image.file(
                                        File(_selectedImage!.path),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey.shade300,
                                            child: const Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                size: 50,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: Colors.grey.shade300,
                                        child: const Center(
                                          child: Icon(Icons.image, size: 50),
                                        ),
                                      ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.edit),
                              label: const Text('Resmi Değiştir'),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedImage = null;
                                  _imageBytes = null;
                                });
                              },
                              icon: const Icon(Icons.delete),
                              label: const Text('Kaldır'),
                            ),
                          ],
                        ),
                      ] else ...[
                        Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade300,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: InkWell(
                            onTap: _pickImage,
                            borderRadius: BorderRadius.circular(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 40,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Etkinlik resmi ekle',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'İlanınızın daha çekici görünmesi için',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Temel bilgiler
              TicketFormField(
                controller: _titleController,
                label: 'Etkinlik Adı',
                hint: 'Örnek: Manga Konseri',
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Etkinlik adı gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TicketFormField(
                controller: _descriptionController,
                label: 'Açıklama',
                hint: 'Etkinlik hakkında detaylar...',
                maxLines: 3,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Açıklama gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Mekan bilgileri
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TicketFormField(
                      controller: _venueController,
                      label: 'Mekan',
                      hint: 'Örnek: Volkswagen Arena',
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Mekan gerekli';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TicketFormField(
                      controller: _cityController,
                      label: 'Şehir',
                      hint: 'Örnek: İstanbul',
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Şehir gerekli';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tarih ve saat
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Etkinlik Tarihi ve Saati',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              leading: const Icon(Icons.calendar_today),
                              title: Text(
                                DateFormat(
                                  'dd MMMM yyyy',
                                  'tr_TR',
                                ).format(_eventDate),
                              ),
                              subtitle: const Text('Tarih'),
                              onTap: _selectDate,
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              leading: const Icon(Icons.access_time),
                              title: Text(_eventTime.format(context)),
                              subtitle: const Text('Saat'),
                              onTap: _selectTime,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Fiyat bilgileri
              Row(
                children: [
                  Expanded(
                    child: TicketFormField(
                      controller: _originalPriceController,
                      label: 'Orijinal Fiyat (₺)',
                      hint: '0',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Fiyat gerekli';
                        }
                        if (double.tryParse(value!) == null) {
                          return 'Geçerli fiyat girin';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TicketFormField(
                      controller: _sellingPriceController,
                      label: 'Satış Fiyatı (₺)',
                      hint: '0',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Satış fiyatı gerekli';
                        }
                        if (double.tryParse(value!) == null) {
                          return 'Geçerli fiyat girin';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Koltuk bilgisi (opsiyonel)
              TicketFormField(
                controller: _seatInfoController,
                label: 'Koltuk Bilgisi (Opsiyonel)',
                hint: 'Örnek: Tribün A, Sıra 15, No: 23',
              ),
              const SizedBox(height: 24),

              // Konum bilgisi
              _buildLocationSection(),
              const SizedBox(height: 32),

              // Enhanced save button moved to bottom for better UX
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 16),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTicket,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _isLoading ? 0 : 4,
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Kaydediliyor...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Bileti Yayınla',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _eventDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _eventTime,
    );
    if (time != null) {
      setState(() {
        _eventTime = time;
      });
    }
  }

  Future<void> _saveTicket() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = ref.read(authStateChangesProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bilet eklemek için giriş yapmalısınız'),
          action: SnackBarAction(
            label: 'Giriş Yap',
            onPressed: () => Navigator.of(context).pushNamed('/login'),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final eventDateTime = DateTime(
        _eventDate.year,
        _eventDate.month,
        _eventDate.day,
        _eventTime.hour,
        _eventTime.minute,
      );

      // Resim upload işlemini yap ve sonucu logla
      final imageUrls = await _uploadSelectedImage(user.uid);
      debugPrint('🔍 DEBUG: Bilet oluşturuluyor - Resim URL\'leri: $imageUrls');

      final ticket = Ticket(
        id: '', // Firestore tarafından atanacak
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        venue: _venueController.text.trim(),
        city: _cityController.text.trim(),
        eventDate: eventDateTime,
        saleDate: DateTime.now(),
        originalPrice: double.parse(_originalPriceController.text),
        sellingPrice: double.parse(_sellingPriceController.text),
        category: _selectedCategory,
        status: TicketStatus.available,
        sellerId: user.uid,
        sellerName: user.displayName,
        imageUrls: imageUrls, // Seçilen resmi upload et
        isVerified: false,
        seatInfo: _seatInfoController.text.trim().isEmpty
            ? null
            : _seatInfoController.text.trim(),
        // Konum bilgileri
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
        locationName: _locationNameController.text.trim().isEmpty
            ? null
            : _locationNameController.text.trim(),
      );

      final userId = user.uid;
      await ref.read(ticketFormProvider.notifier).addTicket(ticket);
      await _refreshTicketProviders(userId: userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Başarıyla! İlanınız eklendi ve diğer kullanıcılar tarafından görülebilir.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            action: SnackBarAction(
              label: 'GÖRÜNTÜLE',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                  arguments: {'tabIndex': 1},
                );
              },
            ),
          ),
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/',
              (route) => false,
              arguments: {'tabIndex': 1},
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Seçilen resmi Firebase Storage'a upload eder
  Future<List<String>> _uploadSelectedImage(String userId) async {
    if (_selectedImage == null || _imageBytes == null) {
      debugPrint(
        '🔍 DEBUG: Resim seçilmemiş - _selectedImage: $_selectedImage, _imageBytes: ${_imageBytes != null}',
      );
      return [];
    }

    try {
      // Firebase Storage'a resmi upload et
      const String fileName = 'ticket_image';
      final String uploadPath =
          'tickets/$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      debugPrint('🔍 DEBUG: Resim upload başlıyor - Path: $uploadPath');

      // Upload işlemi için provider kullan
      final uploadedUrl = await ref
          .read(ticketFormProvider.notifier)
          .uploadImage(_imageBytes!, uploadPath);

      debugPrint('🔍 DEBUG: Upload sonucu - URL: $uploadedUrl');

      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        debugPrint('✅ DEBUG: Resim başarıyla yüklendi: $uploadedUrl');
        return [uploadedUrl];
      } else {
        debugPrint('❌ DEBUG: Upload URL boş veya null');
      }
    } catch (e) {
      debugPrint('❌ DEBUG: Resim yüklenirken hata: $e');
      // Hata durumunda kullanıcıyı bilgilendir
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Resim yüklenemedi, bilet resim olmadan kaydedilecek',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    debugPrint('🔍 DEBUG: Resim upload başarısız, boş liste döndürülüyor');
    return [];
  }

  /// Konum seçimi bölümü
  Widget _buildLocationSection() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Etkinlik Konumu (Opsiyonel)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Konum açıklaması
            TicketFormField(
              controller: _locationNameController,
              label: 'Konum Açıklaması',
              hint: 'Örnek: Vodafone Park, Beşiktaş',
              required: false,
            ),
            const SizedBox(height: 12),

            // Konum seçme butonları
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Mevcut Konum'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectLocationOnMap,
                    icon: const Icon(Icons.map),
                    label: const Text('Haritadan Seç'),
                  ),
                ),
              ],
            ),

            // Seçilen konum bilgisi
            if (_selectedLatitude != null && _selectedLongitude != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: theme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Konum Seçildi',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                          Text(
                            'Lat: ${_selectedLatitude!.toStringAsFixed(6)}, Lng: ${_selectedLongitude!.toStringAsFixed(6)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _clearLocation,
                      child: const Text('Kaldır'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Mevcut konumu al
  Future<void> _getCurrentLocation() async {
    try {
      // Konum izni kontrolü
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konum servisleri kapalı')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Konum izni reddedildi')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konum izni kalıcı olarak reddedildi'),
            ),
          );
        }
        return;
      }

      // Konumu al
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Mevcut konum alındı')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Konum alınamadı: $e')));
      }
    }
  }

  /// Haritadan konum seç
  Future<void> _selectLocationOnMap() async {
    final LatLng? selectedLocation = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (context) => _LocationPickerScreen(
          initialLocation:
              _selectedLatitude != null && _selectedLongitude != null
              ? LatLng(_selectedLatitude!, _selectedLongitude!)
              : null,
        ),
      ),
    );

    if (selectedLocation != null) {
      setState(() {
        _selectedLatitude = selectedLocation.latitude;
        _selectedLongitude = selectedLocation.longitude;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum haritadan seçildi')),
        );
      }
    }
  }

  /// Seçilen konumu temizle
  void _clearLocation() {
    setState(() {
      _selectedLatitude = null;
      _selectedLongitude = null;
    });
  }
}

/// Konum seçici ekranı
class _LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const _LocationPickerScreen({this.initialLocation});

  @override
  State<_LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<_LocationPickerScreen> {
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konum Seç'),
        actions: [
          TextButton(
            onPressed: _selectedLocation != null
                ? () => Navigator.of(context).pop(_selectedLocation)
                : null,
            child: const Text('Tamam'),
          ),
        ],
      ),
      body: GoogleMap(
        gestureRecognizers: {
          Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
        },
        initialCameraPosition: CameraPosition(
          target:
              widget.initialLocation ??
              const LatLng(41.0082, 28.9784), // İstanbul
          zoom: 15,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
        },
        onTap: (LatLng location) {
          setState(() {
            _selectedLocation = location;
          });
        },
        markers: _selectedLocation != null
            ? {
                Marker(
                  markerId: const MarkerId('selected_location'),
                  position: _selectedLocation!,
                  infoWindow: const InfoWindow(title: 'Seçilen Konum'),
                ),
              }
            : {},
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        mapToolbarEnabled: false,
      ),
      floatingActionButton: _selectedLocation != null
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).pop(_selectedLocation),
              icon: const Icon(Icons.check),
              label: const Text('Konumu Seç'),
            )
          : null,
    );
  }
}
