// lib/features/tickets/presentation/screens/edit_ticket_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

import '../../domain/entities/ticket.dart';
import '../providers/ticket_providers.dart';
import '../widgets/ticket_form_field.dart';
// Removed unused import: web_image.dart

class EditTicketScreen extends ConsumerStatefulWidget {
  final Ticket ticket;

  const EditTicketScreen({super.key, required this.ticket});

  @override
  ConsumerState<EditTicketScreen> createState() => _EditTicketScreenState();
}

class _EditTicketScreenState extends ConsumerState<EditTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _venueController;
  late final TextEditingController _cityController;
  late final TextEditingController _originalPriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _seatInfoController;

  late TicketCategory _selectedCategory;
  late DateTime _eventDate;
  late TimeOfDay _eventTime;
  bool _isLoading = false;
  
  // Image handling variables for editing existing ticket images
  XFile? _selectedImage;
  Uint8List? _imageBytes; // Web için byte data
  final ImagePicker _imagePicker = ImagePicker();
  bool _imageChanged = false; // Track if user changed the image

  @override
  void initState() {
    super.initState();
    final ticket = widget.ticket;

    _titleController = TextEditingController(text: ticket.title);
    _descriptionController = TextEditingController(text: ticket.description);
    _venueController = TextEditingController(text: ticket.venue);
    _cityController = TextEditingController(text: ticket.city);
    _originalPriceController = TextEditingController(
      text: ticket.originalPrice.toString(),
    );
    _sellingPriceController = TextEditingController(
      text: ticket.sellingPrice.toString(),
    );
    _seatInfoController = TextEditingController(text: ticket.seatInfo);

    _selectedCategory = ticket.category;
    _eventDate = ticket.eventDate;
    _eventTime = TimeOfDay.fromDateTime(ticket.eventDate);
  }

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

  /// Image picker function to change or add ticket image
  /// Shows bottom sheet with gallery and camera options
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeriden Seç'),
                onTap: () {
                  Navigator.of(context).pop();
                  _getImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _getImage(ImageSource.camera);
                },
              ),
              // Option to remove image if ticket has existing image
              if (widget.ticket.imageUrls.isNotEmpty || _selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Resmi Kaldır'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _removeImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  /// Get image from gallery or camera
  Future<void> _getImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
          _imageChanged = true;
        });

        // Web için byte data'yı oku
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _imageBytes = bytes;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resim seçilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Remove image - mark for removal
  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageBytes = null;
      _imageChanged = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bileti Düzenle'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateTicket,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Güncelle'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Kategori seçimi
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kategori',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
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
            const SizedBox(height: 16),

            // Image section for editing/replacing ticket image
            _buildImageSection(theme),
            const SizedBox(height: 16),

            // Diğer form alanları...
            TicketFormField(
              controller: _titleController,
              label: 'Etkinlik Adı',
            ),
            const SizedBox(height: 16),

            TicketFormField(
              controller: _descriptionController,
              label: 'Açıklama',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TicketFormField(
                    controller: _venueController,
                    label: 'Mekan',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TicketFormField(
                    controller: _cityController,
                    label: 'Şehir',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Etkinlik Tarihi ve Saati',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TicketFormField(
                    controller: _originalPriceController,
                    label: 'Orijinal Fiyat (₺)',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TicketFormField(
                    controller: _sellingPriceController,
                    label: 'Satış Fiyatı (₺)',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TicketFormField(
              controller: _seatInfoController,
              label: 'Koltuk Bilgisi (Opsiyonel)',
            ),
          ],
        ),
      ),
    );
  }

  /// Build image section widget for editing ticket image
  Widget _buildImageSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bilet Görseli',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(
                    _hasImage() ? Icons.edit : Icons.add_photo_alternate,
                    size: 20,
                  ),
                  label: Text(_hasImage() ? 'Değiştir' : 'Resim Ekle'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Show current image or new selected image
            if (_hasImage()) ...[
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImageWidget(),
                ),
              ),
              const SizedBox(height: 8),
              if (_imageChanged)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _selectedImage != null 
                        ? 'Yeni resim seçildi - güncelleme sırasında değiştirilecek'
                        : 'Resim kaldırılacak - güncelleme sırasında silinecek',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 12,
                    ),
                  ),
                ),
            ] else ...[
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Resim eklenmemiş',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
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

  /// Check if ticket has image (existing or newly selected)
  bool _hasImage() {
    if (_imageChanged) {
      return _selectedImage != null;
    }
    return widget.ticket.imageUrls.isNotEmpty;
  }

  /// Build appropriate image widget based on state
  Widget _buildImageWidget() {
    if (_selectedImage != null) {
      // Show newly selected image
      if (kIsWeb && _imageBytes != null) {
        return Image.memory(
          _imageBytes!,
          fit: BoxFit.cover,
        );
      } else if (!kIsWeb) {
        return Image.file(
          File(_selectedImage!.path),
          fit: BoxFit.cover,
        );
      }
    }
    
    // Show existing ticket image
    if (widget.ticket.imageUrls.isNotEmpty) {
      return Image.network(
        widget.ticket.imageUrls.first,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Center(
              child: Icon(Icons.broken_image, size: 50),
            ),
          );
        },
      );
    }
    
    // Fallback
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.image, size: 50),
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

  Future<void> _updateTicket() async {
    if (!_formKey.currentState!.validate()) {
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

      final updatedTicket = widget.ticket.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        venue: _venueController.text.trim(),
        city: _cityController.text.trim(),
        eventDate: eventDateTime,
        originalPrice: double.parse(_originalPriceController.text),
        sellingPrice: double.parse(_sellingPriceController.text),
        category: _selectedCategory,
        seatInfo: _seatInfoController.text.trim().isEmpty
            ? null
            : _seatInfoController.text.trim(),
      );

      await ref.read(ticketFormProvider.notifier).updateTicket(updatedTicket);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bilet başarıyla güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Geri dön
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
}
