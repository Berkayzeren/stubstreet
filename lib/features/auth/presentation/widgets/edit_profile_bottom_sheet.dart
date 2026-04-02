// lib/features/auth/presentation/widgets/edit_profile_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../../../../shared_widgets/responsive_form_field.dart';
import 'location_picker_widget.dart';

class EditProfileBottomSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final Function(Map<String, dynamic>) onSave;

  const EditProfileBottomSheet({
    super.key,
    required this.scrollController,
    required this.onSave,
  });

  @override
  ConsumerState<EditProfileBottomSheet> createState() => _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends ConsumerState<EditProfileBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for form fields - UI state management for user input
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _interestsController = TextEditingController();
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current user data when the widget is first created
    _initializeFields();
  }

  void _initializeFields() {
    // Get current user state from auth provider to pre-populate form fields
    final authState = ref.read(authStateChangesProvider);
    authState.whenData((user) {
      if (user != null) {
        // Pre-fill form fields with existing user data for better UX
        _firstNameController.text = user.firstName;  // firstName is non-nullable in User entity
        _lastNameController.text = user.lastName;  // lastName is non-nullable in User entity
        _phoneController.text = user.phoneNumber ?? '';  // phoneNumber is nullable, so null-aware operator needed
        
        // Also get UserProfile for bio, interests, and location
        ref.read(userProfileProvider(user.id)).whenData((profile) {
          _bioController.text = profile.bio ?? '';
          _interestsController.text = profile.interests.join(', ');
          _selectedLocation = profile.location;
        });
      }
    });
  }

  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authStateChangesProvider);
    
    return authState.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Kullanıcı bulunamadı'));
        }
        return _buildForm(context, isDark, user);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Hata: $error')),
    );
  }
  
  Widget _buildForm(BuildContext context, bool isDark, dynamic user) {
    
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        // Add keyboard padding to prevent form being hidden when keyboard appears
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          controller: widget.scrollController,
          children: [
            // Drag handle indicator for better UX - shows the sheet can be dragged
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white54 : Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Header with title and close button
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Profil Düzenle',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Form fields with educational comments about validation and user experience

            // Username field - read-only since usernames cannot be changed after creation
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.alternate_email,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kullanıcı Adı',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Değiştirilemez',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // First and last name fields in a row for better space utilization
            Row(
              children: [
                Expanded(
                  child: ResponsiveTextFormField(
                    controller: _firstNameController,
                    labelText: 'Ad',
                    prefixIcon: const Icon(Icons.person),
                    validator: (value) {
                      // First name validation - not strictly required but good to have
                      if (value != null && value.trim().isNotEmpty && value.trim().length < 2) {
                        return 'Ad en az 2 karakter olmalıdır';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ResponsiveTextFormField(
                    controller: _lastNameController,
                    labelText: 'Soyad',
                    prefixIcon: const Icon(Icons.person),
                    validator: (value) {
                      // Last name validation - similar to first name
                      if (value != null && value.trim().isNotEmpty && value.trim().length < 2) {
                        return 'Soyad en az 2 karakter olmalıdır';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Phone number field with proper keyboard type and validation
            ResponsiveTextFormField(
              controller: _phoneController,
              labelText: 'Telefon Numarası',
              prefixIcon: const Icon(Icons.phone_outlined),
              keyboardType: TextInputType.phone,
              validator: (value) {
                // Phone validation - check format if provided
                if (value != null && value.trim().isNotEmpty) {
                  // Basic phone number validation - can be enhanced with regex
                  final cleanNumber = value.replaceAll(RegExp(r'[^\d]'), '');
                  if (cleanNumber.length < 10) {
                    return 'Geçerli bir telefon numarası giriniz';
                  }
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Bio field - longer text area for user description
            ResponsiveTextFormField(
              controller: _bioController,
              labelText: 'Hakkımda',
              prefixIcon: const Icon(Icons.info_outline),
              maxLines: 3,
              validator: (value) {
                // Bio validation - optional but limit length for database efficiency
                if (value != null && value.trim().length > 500) {
                  return 'Biyografi en fazla 500 karakter olabilir';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Interests field - comma-separated values that will be parsed into a list
            ResponsiveTextFormField(
              controller: _interestsController,
              labelText: 'İlgi Alanları (virgülle ayırınız)',
              prefixIcon: const Icon(Icons.interests_outlined),
              hintText: 'Müzik, Spor, Teknoloji...',
              validator: (value) {
                // Interests validation - check individual interest length
                if (value != null && value.trim().isNotEmpty) {
                  final interests = value.split(',').map((e) => e.trim()).toList();
                  if (interests.length > 10) {
                    return 'En fazla 10 ilgi alanı girebilirsiniz';
                  }
                  // Check if any individual interest is too long
                  for (final interest in interests) {
                    if (interest.length > 30) {
                      return 'Her ilgi alanı en fazla 30 karakter olabilir';
                    }
                  }
                }
                return null;
              },
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Location picker widget with map support
            LocationPickerWidget(
              initialLocation: _selectedLocation,
              onLocationSelected: (location) {
                setState(() {
                  _selectedLocation = location;
                });
              },
              allowMapSelection: true,
            ),
            const SizedBox(height: 32),

            // Save button with loading state handling
            Consumer(
              builder: (context, ref, child) {
                final updateState = ref.watch(profileUpdateNotifierProvider);
                
                return ElevatedButton(
                  onPressed: updateState.isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    // Disable button during loading to prevent multiple submissions
                    disabledBackgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                  ),
                  child: updateState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Kaydet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _saveProfile() {
    // Validate form before saving to ensure data integrity
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Parse interests from comma-separated string to list
    // This allows users to enter multiple interests in a user-friendly way
    final interestsText = _interestsController.text.trim();
    final interests = interestsText.isEmpty 
        ? <String>[]
        : interestsText
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    // Prepare updated profile data as a map for flexible data handling
    final updatedData = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'bio': _bioController.text.trim(),
      'interests': interests,
      'location': _selectedLocation ?? '',
    };

    // Call the save callback to handle the actual profile update
    widget.onSave(updatedData);
  }
}
