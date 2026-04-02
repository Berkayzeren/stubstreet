// lib/features/auth/presentation/widgets/profile_header.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/web_image.dart';
import '../../../../shared_widgets/responsive_wrapper.dart';
import '../../../../shared_widgets/responsive_form_field.dart';
import '../../domain/entities/user_profile.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final bool isOwnProfile;
  final VoidCallback? onEditProfile;
  final VoidCallback? onChangeCover;
  final VoidCallback? onChangeAvatar;
  final VoidCallback? onFollow;
  final VoidCallback? onMessage;
  final VoidCallback? onReview;
  final ScrollController? scrollController;

  const ProfileHeader({
    super.key,
    required this.profile,
    this.isOwnProfile = false,
    this.onEditProfile,
    this.onChangeCover,
    this.onChangeAvatar,
    this.onFollow,
    this.onMessage,
    this.onReview,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;

    // Responsive dimensions - daha kompakt
    final coverHeight = isDesktop ? 200.0 : (isTablet ? 160.0 : 120.0);
    final avatarRadius = isDesktop ? 60.0 : (isTablet ? 55.0 : 50.0);
    final padding = ResponsivePadding.responsive(
      context,
      mobile: 12.0,
      tablet: 16.0,
      desktop: 20.0,
    );

    return SliverToBoxAdapter(
      child: Column(
        children: [
            // Cover image with parallax effect
            _buildCoverSection(
              context,
              coverHeight,
              avatarRadius,
              colorScheme,
            ),
            
            // Profile info section
            Container(
              width: double.infinity,
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: avatarRadius / 5), // Daha da azaltıldı
              
              // Name and verification
              _buildNameSection(context, theme),
              
              const SizedBox(height: 8), // Azaltıldı
              
              // Stats row
              _buildStatsRow(context, theme),
              
              const SizedBox(height: 8), // Azaltıldı
              
              // Action buttons
              _buildActionButtons(context, theme),
              
              // Alt boşluk - içeriğe göre dinamik
              SizedBox(height: isOwnProfile ? 4 : 8), // Azaltıldı
            ],
              ),
            ),
          ],
      ),
    );
  }

  Widget _buildCoverSection(
    BuildContext context,
    double coverHeight,
    double avatarRadius,
    ColorScheme colorScheme,
  ) {
    return SizedBox(
      height: coverHeight + avatarRadius,
      child: Stack(
        children: [
          // Cover image with parallax effect
          _buildParallaxCover(context, coverHeight, colorScheme),
          
          // Avatar positioned at bottom
          Positioned(
            bottom: 0,
            left: ResponsiveSpacing.getSpacing(
              context,
              mobile: 16.0,
              tablet: 24.0,
              desktop: 32.0,
            ),
            child: _buildAvatar(context, avatarRadius, colorScheme),
          ),
          
          // Edit cover button
          if (isOwnProfile)
            Positioned(
              top: 16,
              right: 16,
              child: _buildEditCoverButton(context, colorScheme),
            ),
        ],
      ),
    );
  }

  Widget _buildParallaxCover(
    BuildContext context,
    double coverHeight,
    ColorScheme colorScheme,
  ) {
    return Container(
      height: coverHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary.withValues(alpha: 0.8),
            colorScheme.primaryContainer.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: profile.coverImageUrl != null
          ? Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: webSafeImageUrl(profile.coverImageUrl!),
                  height: coverHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => _buildDefaultCover(
                    context,
                    coverHeight,
                    colorScheme,
                  ),
                ),
                // Gradient overlay
                Container(
                  height: coverHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : _buildDefaultCover(context, coverHeight, colorScheme),
    );
  }

  Widget _buildDefaultCover(
    BuildContext context,
    double coverHeight,
    ColorScheme colorScheme,
  ) {
    return Container(
      height: coverHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primaryContainer,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image,
          size: 64,
          color: colorScheme.onPrimary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    double avatarRadius,
    ColorScheme colorScheme,
  ) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.surface,
              width: 4,
            ),
          ),
          child: CircleAvatar(
            radius: avatarRadius,
            backgroundColor: colorScheme.primaryContainer,
            child: profile.profileImageUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: webSafeImageUrl(profile.profileImageUrl!),
                      width: avatarRadius * 2,
                      height: avatarRadius * 2,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Icon(
                        Icons.person,
                        size: avatarRadius * 0.8,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: avatarRadius * 0.8,
                    color: colorScheme.onPrimaryContainer,
                  ),
          ),
        ),
        
        // Camera button for own profile
        if (isOwnProfile)
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.surface,
                  width: 1.5,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.camera_alt,
                  size: 12,
                  color: colorScheme.onPrimary,
                ),
                onPressed: onChangeAvatar,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEditCoverButton(BuildContext context, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: IconButton(
        icon: Icon(
          Icons.edit,
          size: 20,
          color: colorScheme.onSurface,
        ),
        onPressed: onChangeCover,
        constraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildNameSection(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '@${profile.username}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      profile.displayName,
                      style: context.isDesktop
                          ? theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            )
                          : theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                    ),
                  ),
                  if (profile.isVerified) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.verified,
                      color: Colors.blue,
                      size: context.isDesktop ? 24 : 20,
                    ),
                  ],
                ],
              ),
              if (profile.location != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      profile.location!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        
        // Edit profile button for own profile
        if (isOwnProfile)
          OutlinedButton.icon(
            onPressed: onEditProfile,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, ThemeData theme) {
    // Dört istatistiği tek satıra sığdırmak için eşit sütunlar
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            context,
            theme,
            'Posts',
            '${profile.totalSales + profile.totalPurchases}',
            Icons.confirmation_number,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            context,
            theme,
            'Followers',
            '${profile.followersCount}',
            Icons.people,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            context,
            theme,
            'Following',
            '${profile.followingCount}',
            Icons.person_add,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            context,
            theme,
            'Rating',
            profile.rating.toStringAsFixed(1),
            Icons.star,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    if (isOwnProfile) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ResponsiveButton(
                text: profile.isFollowing ? 'Takipten Çık' : 'Takip Et',
                type: profile.isFollowing ? ButtonType.outlined : ButtonType.elevated,
                onPressed: onFollow,
                icon: Icon(
                  profile.isFollowing ? Icons.person_remove : Icons.person_add,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ResponsiveButton(
                text: 'Mesaj',
                type: ButtonType.outlined,
                onPressed: onMessage,
                icon: const Icon(Icons.message, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ResponsiveButton(
            text: 'Yorum Yap ve Puanla',
            type: ButtonType.outlined,
            onPressed: onReview,
            icon: const Icon(Icons.rate_review, size: 16),
          ),
        ),
      ],
    );
  }
}
