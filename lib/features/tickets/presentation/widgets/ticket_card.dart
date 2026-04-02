// lib/features/tickets/presentation/widgets/ticket_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../../core/utils/web_image.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../conversations/presentation/screens/firebase_chat_screen.dart';
import '../screens/edit_ticket_screen.dart';
import '../../domain/entities/ticket.dart';
import '../../../../shared_widgets/responsive_wrapper.dart';
import '../providers/ticket_providers.dart';

class TicketCard extends ConsumerWidget {
  final Ticket ticket;
  final VoidCallback onTap;

  const TicketCard({super.key, required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormatter = DateFormat('dd MMM yyyy', 'tr_TR');
    final timeFormatter = DateFormat('HH:mm', 'tr_TR');

    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;
    final borderRadius = isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0);

    // Enhanced modern design with better colors and spacing
    return Semantics(
      button: true,
      label: 'Bilet: ${ticket.title}, ${ticket.venue}, ${ticket.city}, ${dateFormatter.format(ticket.eventDate)}, Fiyat: ${ticket.sellingPrice.toStringAsFixed(0)} TL',
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: ResponsiveSpacing.getSpacing(
            context,
            mobile: 8.0,
            tablet: 10.0,
            desktop: 12.0,
          ),
          horizontal: ResponsiveSpacing.getSpacing(
            context,
            mobile: 16.0,
            tablet: 12.0,
            desktop: 8.0,
          ),
        ),
        decoration: BoxDecoration(
          // Modern card styling with enhanced shadows and colors
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark 
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.15),
              spreadRadius: 0,
              blurRadius: isDesktop ? 12 : 8,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: isDark 
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.08),
              spreadRadius: 0,
              blurRadius: isDesktop ? 6 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            // Uzun basmada eylem menüsü açarak AppBar'sız kullanımda alternatif sunar
            onLongPress: () => _showCardActions(context, ref, ticket),
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: theme.primaryColor.withValues(alpha: 0.1),
            highlightColor: theme.primaryColor.withValues(alpha: 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced image preview with better aspect ratio
                if (ticket.imageUrls.isNotEmpty) 
                  _buildModernImagePreview(ref, isDark)
                else
                  _buildModernDefaultHeader(ref, isDark),
                
                // Content section with improved spacing and typography
                Padding(
                  padding: EdgeInsets.all(isDesktop ? 20.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Enhanced title and category section
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(ticket.category).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              ticket.category.icon,
                              style: TextStyle(
                                fontSize: 18,
                                color: _getCategoryColor(ticket.category),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ticket.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: context.isDesktop ? 18 : (context.isTablet ? 17 : 16),
                                    color: isDark ? Colors.white : Colors.grey[900],
                                  ),
                                  maxLines: context.isDesktop ? 3 : 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(ticket.category).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    ticket.category.name.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _getCategoryColor(ticket.category),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (ticket.isVerified)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified, 
                                color: Colors.green, 
                                size: 16,
                              ),
                            ),
                          const SizedBox(width: 6),
                          // Overflow menü ikonu: paylaş/favori/raporla gibi eylemler
                          IconButton(
                            tooltip: 'Daha fazla',
                            icon: const Icon(Icons.more_vert, size: 20),
                            splashRadius: 18,
                            onPressed: () => _showCardActions(context, ref, ticket),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Enhanced location info with modern styling
                      _buildModernInfoRow(
                        icon: Icons.location_on_outlined,
                        text: '${ticket.venue}, ${ticket.city}',
                        theme: theme,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),

                      // Enhanced date info
                      _buildModernInfoRow(
                        icon: Icons.calendar_today_outlined,
                        text: '${dateFormatter.format(ticket.eventDate)} • ${timeFormatter.format(ticket.eventDate)}',
                        theme: theme,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),

                      // Seller info - Display seller name (always non-null as per entity definition)
                      _buildModernInfoRow(
                        icon: Icons.person_outline,
                        text: 'Satıcı: ${ticket.sellerName}',
                        theme: theme,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      // Enhanced price section with modern styling
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(ticket.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusColor(ticket.status).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              ticket.status.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(ticket.status),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.primaryColor.withValues(alpha: 0.8),
                                  theme.primaryColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '${ticket.sellingPrice.toStringAsFixed(0)} TL',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

  }

  /// Modern enhanced image preview with better styling
  Widget _buildModernImagePreview(WidgetRef ref, bool isDark) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Stack(
        children: [
          // Enhanced main image with better aspect ratio
          Builder(
            builder: (context) {
              final originalUrl = ticket.imageUrls.first;
              final processedUrl = webSafeImageUrl(originalUrl);
              
              // Debug: Log both URLs to understand the problem
              debugPrint('🔍 DEBUG: Original URL: $originalUrl');
              debugPrint('🔍 DEBUG: Processed URL: $processedUrl');
              
              // Use CachedNetworkImage for better Firebase Storage compatibility
              return CachedNetworkImage(
                imageUrl: originalUrl, // Use original Firebase URL directly
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) {
                  return Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _getCategoryColor(ticket.category),
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorWidget: (context, url, error) {
                  debugPrint('❌ DEBUG: Resim yükleme hatası - URL: ${ticket.imageUrls.first}, Error: $error');
                  // When image fails to load, show a placeholder without the default icon
                  // This ensures no icon is shown when image exists but fails to load
                  return Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 32,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Resim yüklenemedi',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          
          // Subtle gradient overlay for better text readability
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),
          
          // Resim sayısı badge'i (eğer birden fazla resim varsa)
          if (ticket.imageUrls.length > 1)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${ticket.imageUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Beğeni sayısını kalp içinde göster - sadece beğeni varsa
          Positioned(
            bottom: 8,
            right: 8,
            child: ref.watch(ticketLikesCountProvider(ticket.id)).when(
              data: (likeCount) => likeCount > 0 
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          likeCount > 999 ? '999+' : likeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(), // Beğeni yoksa hiçbir şey gösterme
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  /// Modern enhanced default header with better styling when no image
  Widget _buildModernDefaultHeader(WidgetRef ref, bool isDark) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getCategoryColor(ticket.category).withValues(alpha: 0.8),
            _getCategoryColor(ticket.category).withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Stack(
        children: [
          // Background pattern for more visual interest
          Positioned.fill(
            child: CustomPaint(
              painter: _PatternPainter(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          // Category icon with enhanced styling
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    ticket.category.icon,
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ticket.category.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Enhanced modern info row with better visibility and styling
  Widget _buildModernInfoRow({
    required IconData icon,
    required String text,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              size: 14,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // (removed) _buildInfoRow: Deprecated helper replaced by _buildModernInfoRow

  /// Kategori rengi
  Color _getCategoryColor(TicketCategory category) {
    switch (category) {
      case TicketCategory.concert:
        return Colors.purple;
      case TicketCategory.sports:
        return Colors.green;
      case TicketCategory.theater:
        return Colors.red;
      case TicketCategory.festival:
        return Colors.orange;
      case TicketCategory.comedy:
        return Colors.blue;
      case TicketCategory.museum:
        return Colors.indigo;
      case TicketCategory.exhibition:
        return Colors.teal;
      case TicketCategory.workshop:
        return Colors.brown;
      case TicketCategory.cinema:
        return Colors.cyan;
      case TicketCategory.party:
        return Colors.pink;
      case TicketCategory.conference:
        return Colors.deepPurple;
      case TicketCategory.other:
        return Colors.grey;
    }
  }

  /// Durum rengi
  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.available:
        return Colors.green;
      case TicketStatus.sold:
        return Colors.red;
      case TicketStatus.reserved:
        return Colors.orange;
      case TicketStatus.expired:
        return Colors.grey;
    }
  }
}

/// Custom painter for creating subtle background patterns in ticket cards
/// This adds visual interest and depth to cards without images
class _PatternPainter extends CustomPainter {
  final Color color;

  _PatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Create a subtle geometric pattern for visual enhancement
    const spacing = 20.0;
    
    // Draw diagonal lines pattern for texture
    for (double x = 0; x < size.width + spacing; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - size.height, size.height),
        paint,
      );
    }
    
    // Add subtle dots pattern for additional texture
    paint.style = PaintingStyle.fill;
    const dotSize = 1.5;
    const dotSpacing = 15.0;
    
    for (double x = dotSpacing; x < size.width; x += dotSpacing) {
      for (double y = dotSpacing; y < size.height; y += dotSpacing) {
        canvas.drawCircle(
          Offset(x, y),
          dotSize,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Shows a bottom sheet with actions for the ticket card
/// Why: Without an AppBar, we still want a discoverable place for secondary actions.
void _showCardActions(BuildContext context, WidgetRef ref, Ticket ticket) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom),
          child: Consumer(
            builder: (context, ref, _) {
            final currentUser = ref.watch(authStateChangesProvider).value;
            final isLikedAsync = ref.watch(isLikedByUserProvider(ticket.id));
            final likeToggleState = ref.watch(likeToggleProvider);
            final likeCache = ref.watch(likeStateCacheProvider);

            // Use cache if available, otherwise use stream
            final isLiked = likeCache[ticket.id] ?? isLikedAsync.value ?? false;
            
            IconData favIcon = isLiked ? Icons.favorite : Icons.favorite_border;
            String favText = isLiked ? 'Favorilerden Kaldır' : 'Favorilere Ekle';

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Paylaş'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Share.share('Bu bileti inceleyin: ${ticket.title}');
                  },
                ),
                ListTile(
                  leading: Icon(favIcon, color: favIcon == Icons.favorite ? Colors.red : null),
                  title: Text(favText),
                  onTap: likeToggleState.isLoading || currentUser == null
                      ? null
                      : () async {
                          try {
                            await ref.read(likeToggleProvider.notifier).toggleLike(ticket.id, currentUser.uid);
                            if (context.mounted) Navigator.of(ctx).pop();
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                ),
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Raporla'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Raporlama yakında eklenecek'), backgroundColor: Colors.orange),
                      );
                    }
                  },
                ),
                // Satıcıya mesaj gönder eylemi
                ListTile(
                  leading: const Icon(Icons.message_outlined),
                  title: const Text('Satıcıya Mesaj Gönder'),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final user = ref.read(authStateChangesProvider).value;
                    if (user == null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mesaj göndermek için giriş yapmalısınız'), backgroundColor: Colors.orange),
                        );
                      }
                      return;
                    }

                    // Sipariş detayındaki ile aynı conversation ID formatını kullan
                    final conversationId = '${user.uid}_${ticket.sellerId}';
                    final sellerAvatarUrl = ticket.sellerAvatarUrl;
                    
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => FirebaseChatScreen(
                            conversationId: conversationId,
                            otherUserId: ticket.sellerId,
                            otherUserName: ticket.sellerName.isNotEmpty ? ticket.sellerName : 'Satıcı',
                            otherUserAvatarUrl: _guardAvatar(sellerAvatarUrl),
                          ),
                        ),
                      );
                    }
                  },
                ),
                // Takvime ekle (ICS)
                ListTile(
                  leading: const Icon(Icons.event_available_outlined),
                  title: const Text('Takvime Ekle'),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    try {
                      final ics = _buildIcs(ticket);
                      final dir = await getTemporaryDirectory();
                      final file = File('${dir.path}/ticket_${ticket.id}.ics');
                      await file.writeAsString(ics);
                      await Share.shareXFiles([XFile(file.path)], text: 'Etkinliği takvime ekle');
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Takvime eklenemedi: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                ),
                // Konumu haritada aç
                if (ticket.latitude != null && ticket.longitude != null)
                  ListTile(
                    leading: const Icon(Icons.map_outlined),
                    title: const Text('Haritada Aç'),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${ticket.latitude},${ticket.longitude}');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Harita açılamadı'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                  ),
                // Benzer ilanları göster
                ListTile(
                  leading: const Icon(Icons.filter_alt_outlined),
                  title: const Text('Benzer İlanları Göster'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    // Basit yaklaşım: kullanıcıyı arama sayfasına yönlendir ve kategori/şehir ön seçili bilgi SnackBar olarak ver
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Filtre: ${ticket.category.displayName}, ${ticket.city}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                // Bağlantıyı kopyala (derin link)
                ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text('Bağlantıyı Kopyala'),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final link = 'https://stubstreet.com/ticket/${ticket.id}';
                    await Clipboard.setData(ClipboardData(text: link));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bağlantı kopyalandı')), 
                      );
                    }
                  },
                ),
                const Divider(height: 0),
                // Rol/durum bazlı eylemler
                Consumer(
                  builder: (context, ref, _) {
                    final currentUser = ref.watch(authStateChangesProvider).value;
                    final isSeller = currentUser?.uid == ticket.sellerId;
                    if (isSeller) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.edit_outlined),
                            title: const Text('Düzenle'),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => EditTicketScreen(ticket: ticket),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.visibility_off_outlined),
                            title: const Text('İlanı Gizle'),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Gizleme özelliği yakında')), 
                                );
                              }
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete_outline),
                            title: const Text('Sil'),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              // Silme işlemi ekranına yönlendirme veya onay dialogu uygulama genelinde var
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Silme işlemi için bilet detayını kullanın')), 
                                );
                              }
                            },
                          ),
                        ],
                      );
                    } else {
                      // Alıcı tarafı
                      final canBuy = ticket.status == TicketStatus.available;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (canBuy)
                            ListTile(
                              leading: const Icon(Icons.shopping_cart_outlined),
                              title: const Text('Satın Alma Akışına Git'),
                              onTap: () {
                                Navigator.of(ctx).pop();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Satın alma akışı yakında')), 
                                  );
                                }
                              },
                            ),
                          if (!canBuy)
                            ListTile(
                              leading: const Icon(Icons.search),
                              title: const Text('Benzer İlanları Göster'),
                              onTap: () {
                                Navigator.of(ctx).pop();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Benzer ilanlar için arama sekmesine geçin')), 
                                  );
                                }
                              },
                            ),
                        ],
                      );
                    }
                  },
                ),
              ],
            );
          },
          ),
        ),
      );
    },
  );
}

/// ICS içerik üretir (takvime ekleme için)
/// Bu minimal ICS, bir etkinlik başlangıç-bitiş zamanını ve açıklamasını içerir.
String _buildIcs(Ticket ticket) {
  final start = _formatIcsDate(ticket.eventDate);
  final end = _formatIcsDate(ticket.eventDate.add(const Duration(hours: 3)));
  final uid = ticket.id;
  final summary = ticket.title.replaceAll('\n', ' ');
  final desc = (ticket.description).replaceAll('\n', ' ');
  final location = '${ticket.venue}, ${ticket.city}';
  return 'BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:-//StubStreet//Ticket//EN\nBEGIN:VEVENT\nUID:$uid\nDTSTAMP:$start\nDTSTART:$start\nDTEND:$end\nSUMMARY:$summary\nDESCRIPTION:$desc\nLOCATION:$location\nEND:VEVENT\nEND:VCALENDAR';
}

String _formatIcsDate(DateTime dt) {
  // ICS UTC format: YYYYMMDDTHHMMSSZ
  final utc = dt.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${utc.year}${two(utc.month)}${two(utc.day)}T${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
}

  String? _guardAvatar(String? url) => (url == null || url.isEmpty) ? null : url;