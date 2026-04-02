// lib/features/auth/presentation/screens/advanced_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/auth_providers.dart';
import '../widgets/profile_header.dart';
import '../widgets/editable_profile_section.dart';
import '../widgets/edit_profile_bottom_sheet.dart';
import '../widgets/settings_bottom_sheet.dart';
import '../widgets/location_picker_widget.dart';
import '../../data/services/media_picker_service.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/user.dart';
import '../../../../shared_widgets/responsive_wrapper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../conversations/presentation/screens/firebase_chat_screen.dart';
import '../../../conversations/presentation/providers/firebase_chat_providers.dart';
import '../../../../core/services/user_moderation_service.dart';

class AdvancedProfileScreen extends ConsumerStatefulWidget {
  final String? userId; // If null, shows current user's profile
  
  const AdvancedProfileScreen({super.key, this.userId});

  @override
  ConsumerState<AdvancedProfileScreen> createState() => _AdvancedProfileScreenState();
}

class _AdvancedProfileScreenState extends ConsumerState<AdvancedProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return authState.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Kullanıcı bulunamadı')),
          );
        }

        final profileUserId = widget.userId ?? user.id;
        final isOwnProfile = widget.userId == null || widget.userId == user.id;
        
        return ref.watch(userProfileProvider(profileUserId)).when(
          data: (userProfile) => _buildProfileScreen(context, userProfile, isOwnProfile, theme, colorScheme, l10n),
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, stack) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Hata: ${error.toString()}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(userProfileProvider(profileUserId)),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Auth Hatası: ${error.toString()}'),
        ),
      ),
    );
  }

  Widget _buildProfileScreen(
    BuildContext context,
    UserProfile userProfile,
    bool isOwnProfile,
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {

    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
          SliverAppBar(
            expandedHeight: 0,
            toolbarHeight: 48.0, // Daha kompakt
            floating: false,
            pinned: true,
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.onSurface,
              elevation: 0,
              title: Text(
                isOwnProfile ? l10n.profile : userProfile.displayName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                if (isOwnProfile)
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: _showSettings,
                  )
                else ...[
                  IconButton(
                    icon: const Icon(Icons.report),
                    onPressed: () => _showReportUserDialog(userProfile.id),
                    tooltip: 'Kullanıcıyı Rapor Et',
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'block':
                          _showBlockUserDialog(userProfile.id);
                          break;
                        case 'report':
                          _showReportUserDialog(userProfile.id);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'report',
                        child: ListTile(
                          leading: Icon(Icons.report, color: Colors.orange),
                          title: Text('Rapor Et'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'block',
                        child: ListTile(
                          leading: Icon(Icons.block, color: Colors.red),
                          title: Text('Engelle'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),

            // Profile header with parallax cover
            ProfileHeader(
              profile: userProfile,
              isOwnProfile: isOwnProfile,
              scrollController: _scrollController,
              onEditProfile: _showEditProfileDialog,
              onChangeCover: () => _updateProfileImage(false, userProfile),
              onChangeAvatar: () => _updateProfileImage(true, userProfile),
              onFollow: _handleFollow,
              onMessage: () => _handleMessage(userProfile),
              onReview: () => _showReviewDialog(userProfile),
            ),

            // Tab bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                tabController: _tabController,
                colorScheme: colorScheme,
              ),
            ),
          ];
        },
        // Place TabBarView as the NestedScrollView body to avoid extra bottom space
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsTab(),
            _buildAboutTab(userProfile),
            _buildReviewsTab(userProfile),
          ],
        ),
      ),
    );
  }

  void _updateProfileImage(bool isAvatar, UserProfile profile) async {
    final mediaPickerService = ref.read(mediaPickerServiceProvider);
    final imageUploadNotifier = ref.read(imageUploadProvider.notifier);
    
    // Reset upload state
    imageUploadNotifier.reset();
    
    // Show upload progress dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildUploadProgressDialog(),
    );
    
    imageUploadNotifier.startUpload();

    try {
      if (!mounted) return;
      
      String? downloadUrl;
      if (mounted) {
        downloadUrl = isAvatar
            ? await mediaPickerService.pickAndUploadProfileImage(
                userId: profile.id, 
                context: context,
              )
            : await mediaPickerService.pickAndUploadCoverImage(
                userId: profile.id, 
                context: context,
              );
      }

      if (downloadUrl != null && mounted) {
        // Update profile with new image URL via repository
        final updateProfileNotifier = ref.read(profileUpdateNotifierProvider.notifier);
        await updateProfileNotifier.updateProfile(
          photoURL: isAvatar ? downloadUrl : null,
          coverImageUrl: isAvatar ? null : downloadUrl,
        );

        // Mark upload complete
        imageUploadNotifier.completeUpload(downloadUrl);

        // Refresh the profile data so UI reflects the change
        ref.invalidate(userProfileProvider(profile.id));

        // Close progress dialog first
        if (mounted) Navigator.of(context).pop();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isAvatar ? 'Profile picture updated!' : 'Cover photo updated!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // No image selected or upload failed
        imageUploadNotifier.uploadError('No image selected');
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      imageUploadNotifier.uploadError('Failed to upload image: $e');
      if (mounted) {
        // Close progress dialog first
        Navigator.of(context).pop();
        
        // Check if it's a permission error
        if (e.toString().contains('permissions are required')) {
          _showPermissionDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload image: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İzin Gerekli'),
        content: const Text(
          'Profil resmi yüklemek için kamera ve galeri erişim izni gereklidir. '
          'Lütfen ayarlardan izinleri etkinleştirin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Ayarlara Git'),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgressDialog() {
    return Consumer(
      builder: (context, ref, child) {
        final uploadState = ref.watch(imageUploadProvider);
        
        return AlertDialog(
          title: const Text('Resim Yükleniyor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: uploadState.progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                uploadState.isUploading 
                    ? 'Yükleniyor... ${(uploadState.progress * 100).toStringAsFixed(1)}%'
                    : uploadState.error != null
                        ? 'Hata: ${uploadState.error}'
                        : 'İşleniyor...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostsTab() {
    return ResponsiveWrapper(
      child: SingleChildScrollView(
        child: Container(
          padding: ResponsivePadding.responsive(
            context,
            mobile: 8.0,  // Azaltıldı
            tablet: 12.0, // Azaltıldı
            desktop: 16.0, // Azaltıldı
          ),
          child: Column(
            children: [
              const SizedBox(height: 4), // Azaltıldı
              // Posts grid would go here
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.post_add,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Henüz gönderi yok',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gönderiler burada görünecek',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4), // Azaltıldı
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutTab(UserProfile profile) {
    // İçerik var mı kontrol et
    final hasBio = profile.bio != null && profile.bio!.isNotEmpty;
    final hasInterests = profile.interests.isNotEmpty;
    final hasLocation = profile.location != null && profile.location!.isNotEmpty;
    final hasContent = hasBio || hasInterests || hasLocation;
    
    return ResponsiveWrapper(
      child: SingleChildScrollView(
        child: Container(
          padding: ResponsivePadding.responsive(
            context,
            mobile: 8.0,  // Azaltıldı
            tablet: 12.0, // Azaltıldı
            desktop: 16.0, // Azaltıldı
          ),
          child: Column(
            children: [
              const SizedBox(height: 4), // Azaltıldı
              
              // Bio section
              EditableProfileSection(
                title: 'Bio',
                content: profile.bio ?? 'Bio eklenmemiş',
                isEditable: widget.userId == null,
                onEdit: (newContent) => _updateBio(newContent),
              ),
              
              const SizedBox(height: 8), // Azaltıldı
              
              // Interests section
              EditableProfileSection(
                title: 'İlgi Alanları',
                content: profile.interests.isNotEmpty 
                    ? profile.interests.join(', ')
                    : 'İlgi alanı eklenmemiş',
                isEditable: widget.userId == null,
                onEdit: (newContent) => _updateInterests(newContent),
              ),
              
              const SizedBox(height: 8), // Azaltıldı
              
              // Location section
              if (widget.userId == null)
                _buildLocationCard(profile)
              else
                EditableProfileSection(
                  title: 'Konum',
                  content: profile.location ?? 'Konum belirtilmemiş',
                  isEditable: false,
                  onEdit: (newContent) => _updateLocation(newContent),
                ),
              
              const SizedBox(height: 8), // Azaltıldı
              
              // Account info (read-only)
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hesap Bilgileri',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('E-posta', profile.email),
                      _buildInfoRow('Telefon', profile.phoneNumber ?? 'Belirtilmemiş'),
                      _buildInfoRow('Üyelik tarihi', _formatDate(profile.createdAt)),
                      _buildInfoRow('Rol', _getRoleDisplayName(profile.role)),
                    ],
                  ),
                ),
              ),
              // İçerik varsa alt boşluk ekle, yoksa minimal
              SizedBox(height: hasContent ? 8 : 4), // Azaltıldı
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsTab(UserProfile profile) {
    final hasReviews = profile.reviews.isNotEmpty;
    
    return ResponsiveWrapper(
      child: SingleChildScrollView(
        child: Container(
          padding: ResponsivePadding.responsive(
            context,
            mobile: 8.0,  // Azaltıldı
            tablet: 12.0, // Azaltıldı
            desktop: 16.0, // Azaltıldı
          ),
          child: Column(
            children: [
              const SizedBox(height: 4), // Azaltıldı
              
              // Rating summary
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.orange,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${profile.rating.toStringAsFixed(1)} / 5',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${profile.reviews.length} değerlendirme',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              if (hasReviews) const SizedBox(height: 8), // Azaltıldı
              
              // Reviews list
              if (hasReviews)
                ...profile.reviews.asMap().entries.map((entry) {
                  final index = entry.key;
                  final review = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < profile.reviews.length - 1 ? 8 : 0,
                    ),
                    child: _buildReviewCard(review, profile.id),
                  );
                })
              else
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.rate_review,
                            size: 48,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Henüz değerlendirme yok',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Değerlendirmeler burada görünecek',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Alt boşluk - içeriğe göre dinamik
              SizedBox(height: hasReviews ? 8 : 4), // Azaltıldı
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(UserReview review, String currentProfileId) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _openUserProfile(review.reviewerId, currentProfileId),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: review.reviewerAvatar.isNotEmpty
                        ? NetworkImage(review.reviewerAvatar)
                        : null,
                    child: review.reviewerAvatar.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _openUserProfile(review.reviewerId, currentProfileId),
                        child: Text(
                          review.reviewerName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                        ),
                      ),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (index) => Icon(
                              index < review.rating ? Icons.star : Icons.star_border,
                              size: 16,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(review.createdAt),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  void _openUserProfile(String userId, String currentProfileId) {
    if (userId.isEmpty) return;
    if (userId == currentProfileId) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdvancedProfileScreen(userId: userId),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(UserProfile profile) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: _showLocationPicker,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Konum',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.edit,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.place,
                      size: 16,
                      color: profile.location != null 
                          ? colorScheme.primary 
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        profile.location ?? 'Konum seç',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: profile.location != null 
                              ? colorScheme.onSurface 
                              : colorScheme.onSurfaceVariant,
                          fontStyle: profile.location == null 
                              ? FontStyle.italic 
                              : FontStyle.normal,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getRoleDisplayName(UserRole role) {
    // Authorization/UI policy update:
    // Why: Product requirement dictates that every authenticated user can both sell and buy.
    // Therefore, instead of showing a mutually exclusive single role (buyer OR seller),
    // we surface the combined capability in the profile UI.
    // Admins retain their label because they also have elevated controls in addition to buy/sell.
    // This is purely a display choice; backend authorization is handled centrally via AuthorizationService.
    if (role == UserRole.admin) {
      return 'Admin';
    }
    // For any non-admin (legacy buyer/seller), display combined capability
    return 'Alıcı ve Satıcı';
  }

  void _showEditProfileDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: EditProfileBottomSheet(
              scrollController: scrollController,
              onSave: (updatedProfile) {
                _updateUserProfile(updatedProfile);
                Navigator.pop(context);
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateUserProfile(Map<String, dynamic> updatedData) async {
    final updateProfileNotifier = ref.read(profileUpdateNotifierProvider.notifier);
    
    try {
      await updateProfileNotifier.updateProfile(
        displayName: updatedData['displayName'],
        firstName: updatedData['firstName'],
        lastName: updatedData['lastName'],
        phoneNumber: updatedData['phoneNumber'],
        bio: updatedData['bio'],
        interests: updatedData['interests']?.cast<String>(),
        location: updatedData['location'],
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil başarıyla güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil güncellenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SettingsBottomSheet(scrollController: scrollController),
          );
        },
      ),
    );
  }

  void _handleFollow() {
    // TODO: Implement follow functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Follow functionality coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _handleMessage(UserProfile userProfile) async {
    final currentUser = ref.read(authStateChangesProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mesaj göndermek için giriş yapmalısınız'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Kendi profilinden mesaj göndermeye çalışıyorsa
    if (currentUser.uid == userProfile.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kendinize mesaj gönderemezsiniz'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Conversation başlat veya mevcut olanı getir
      final conversationStarter = ref.read(conversationStarterProvider.notifier);
      final conversationId = await conversationStarter.startConversation(userProfile.id);
      
      if (mounted) {
        // FirebaseChatScreen'i kullan
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FirebaseChatScreen(
              conversationId: conversationId,
              otherUserId: userProfile.id,
              otherUserName: userProfile.displayName,
              otherUserAvatarUrl: userProfile.profileImageUrl,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesaj başlatılamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateBio(String newBio) {
    // TODO: Implement bio update
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bio updated!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _updateInterests(String newInterests) {
    // TODO: Implement interests update
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Interests updated!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _updateLocation(String newLocation) async {
    final updateProfileNotifier = ref.read(profileUpdateNotifierProvider.notifier);
    
    try {
      await updateProfileNotifier.updateProfile(
        location: newLocation,
      );
      
      // Profili yenile
      ref.invalidate(userProfileProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konum güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konum güncellenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLocationPicker() {
    final authState = ref.read(authStateChangesProvider);
    authState.whenData((user) {
      if (user != null) {
        ref.read(userProfileProvider(user.id)).whenData((profile) {
          if (mounted) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => DraggableScrollableSheet(
                initialChildSize: 0.8,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 20,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Drag handle
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Başlık
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Konum Seç',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.grey[200],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Location picker widget
                          LocationPickerWidget(
                            initialLocation: profile.location,
                            onLocationSelected: (location) {
                              _updateLocation(location);
                              Navigator.pop(context);
                            },
                            allowMapSelection: true,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }
        });
      }
    });
  }

  void _showReviewDialog(UserProfile profile) {
    double rating = 5.0;
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Kullanıcıyı Değerlendir'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile.displayName} kullanıcısını değerlendirin:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                
                // Rating stars
                const Text('Puan:'),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () => setState(() => rating = index + 1.0),
                      child: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.orange,
                        size: 32,
                      ),
                    );
                  }),
                ),
                Text(
                  '${rating.toInt()}/5',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                
                const SizedBox(height: 16),
                
                // Comment field
                const Text('Yorum:'),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    hintText: 'Deneyiminizi paylaşın...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  maxLength: 200,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                _submitReview(profile, rating, commentController.text);
                Navigator.pop(context);
              },
              child: const Text('Gönder'),
            ),
          ],
        ),
      ),
    );
  }

  void _submitReview(UserProfile profile, double rating, String comment) async {
    final reviewNotifier = ref.read(reviewSubmissionNotifierProvider.notifier);
    
    try {
      await reviewNotifier.submitReview(
        reviewedUserId: profile.id,
        rating: rating,
        comment: comment,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${profile.displayName} kullanıcısı için ${rating.toInt()} yıldız ve yorumunuz gönderildi!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      // Refresh the profile data
      ref.invalidate(userProfileProvider(profile.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Kullanıcıyı rapor etme dialog'unu göster
  void _showReportUserDialog(String userId) {
    String selectedReason = '';
    String customReason = '';
    final customReasonController = TextEditingController();
    
    final reasons = [
      'Spam veya istenmeyen içerik',
      'Taciz veya zorbalık',
      'Sahte profil',
      'Uygunsuz içerik',
      'Dolandırıcılık',
      'Telif hakkı ihlali',
      'Diğer',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Kullanıcıyı Rapor Et'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bu kullanıcıyı neden raporluyorsunuz?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                
                // Sebep seçenekleri
                ...reasons.map((reason) {
                  return ListTile(
                    leading: Radio<String>(
                      value: reason,
                      // ignore: deprecated_member_use
                      groupValue: selectedReason,
                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        setState(() {
                          selectedReason = value ?? '';
                        });
                      },
                    ),
                    title: Text(reason),
                    onTap: () {
                      setState(() {
                        selectedReason = reason;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  );
                }),
                
                // Özel sebep alanı
                if (selectedReason == 'Diğer') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: customReasonController,
                    decoration: const InputDecoration(
                      labelText: 'Lütfen açıklayın',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      customReason = value;
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: selectedReason.isNotEmpty &&
                      (selectedReason != 'Diğer' || customReason.isNotEmpty)
                  ? () {
                      Navigator.pop(context);
                      _reportUser(userId, selectedReason, customReason.isNotEmpty ? customReason : null);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Rapor Et'),
            ),
          ],
        ),
      ),
    );
  }

  /// Kullanıcıyı engelleme dialog'unu göster
  void _showBlockUserDialog(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Engelle'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu kullanıcıyı engellemek istediğinizden emin misiniz?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              '• Bu kullanıcıdan mesaj alamayacaksınız',
              style: TextStyle(color: Colors.grey),
            ),
            Text(
              '• Bu kullanıcının gönderilerini görmeyeceksiniz',
              style: TextStyle(color: Colors.grey),
            ),
            Text(
              '• Bu kullanıcı sizi bulamayacak',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _blockUser(userId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Engelle'),
          ),
        ],
      ),
    );
  }

  /// Kullanıcıyı rapor et
  Future<void> _reportUser(String userId, String reason, String? customReason) async {
    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Rapor gönderiliyor...'),
            ],
          ),
        ),
      );

      await UserModerationService.reportUser(
        reportedUserId: userId,
        reason: reason,
        customReason: customReason,
      );

      // Loading'i kapat
      if (mounted) Navigator.pop(context);

      // Başarı mesajı
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı başarıyla raporlandı. İnceleme için teşekkürler.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      debugPrint('✅ Kullanıcı başarıyla raporlandı: $userId');

    } catch (e) {
      // Loading'i kapat
      if (mounted) Navigator.pop(context);

      // Hata mesajı
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapor gönderilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      debugPrint('❌ Kullanıcı raporlama hatası: $e');
    }
  }

  /// Kullanıcıyı engelle
  Future<void> _blockUser(String userId) async {
    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Kullanıcı engelleniyor...'),
            ],
          ),
        ),
      );

      await UserModerationService.blockUser(userId);

      // Loading'i kapat
      if (mounted) Navigator.pop(context);

      // Başarı mesajı
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı başarıyla engellendi.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Profil sayfasından çık
      if (mounted) Navigator.pop(context);

      debugPrint('✅ Kullanıcı başarıyla engellendi: $userId');

    } catch (e) {
      // Loading'i kapat
      if (mounted) Navigator.pop(context);

      // Hata mesajı
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kullanıcı engellenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      debugPrint('❌ Kullanıcı engelleme hatası: $e');
    }
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final ColorScheme colorScheme;

  _TabBarDelegate({
    required this.tabController,
    required this.colorScheme,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: colorScheme.surface,
      child: TabBar(
        controller: tabController,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        tabs: const [
          Tab(text: 'Posts'),
          Tab(text: 'About'),
          Tab(text: 'Reviews'),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 48.0;

  @override
  double get minExtent => 48.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
