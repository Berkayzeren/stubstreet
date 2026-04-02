// lib/features/tickets/presentation/screens/ticket_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../shared_widgets/enhanced_map_widget.dart';
import '../../../../shared_widgets/full_screen_map_widget.dart';
import '../../../../core/mixins/scroll_to_top_mixin.dart';

import '../providers/ticket_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/ticket.dart';
import 'edit_ticket_screen.dart';
import '../../../conversations/presentation/screens/firebase_chat_screen.dart';
import '../../../checkout/presentation/screens/checkout_screen.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> with ScrollToTopMixin {

  @override
  Widget build(BuildContext context) {
    final ticketAsyncValue = ref.watch(ticketDetailProvider(widget.ticketId));
    final user = ref.watch(authStateChangesProvider).value;
    final theme = Theme.of(context);

    return Scaffold(
      // Tüm üst barlar kaldırıldı: AppBar kullanılmıyor
      appBar: null,
      body: ticketAsyncValue.when(
        data: (ticket) {

          final dateFormatter = DateFormat('dd MMMM yyyy, EEEE', 'tr_TR');
          final timeFormatter = DateFormat('HH:mm', 'tr_TR');

          return SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                // Üst görsel alanı: Eğer bilet için resim varsa resmi göster, yoksa önceki degrade başlık
                if (ticket.imageUrls.isNotEmpty)
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        PageView.builder(
                          itemCount: ticket.imageUrls.length,
                          itemBuilder: (context, index) {
                            return Image.network(
                              ticket.imageUrls[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) {
                                return Container(
                                  height: 220,
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                );
                              },
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  height: 220,
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator(strokeWidth: 2),
                                );
                              },
                            );
                          },
                        ),
                        // Resim sayısı göstergesi
                        if (ticket.imageUrls.length > 1)
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.photo_library, size: 16, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${ticket.imageUrls.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ticket.category.icon,
                            style: const TextStyle(fontSize: 48),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ticket.category.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Başlık ve eylemler (paylaş/favori) - yan yana hizalama
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              ticket.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Consumer(
                            builder: (context, ref, _) {
                              final currentUser = ref.watch(authStateChangesProvider).value;
                              final isLikedAsync = ref.watch(isLikedByUserProvider(widget.ticketId));
                              final likeCountAsync = ref.watch(likeCountProvider(widget.ticketId));
                              final likeToggleState = ref.watch(likeToggleProvider);
                              final likeCache = ref.watch(likeStateCacheProvider);
                              
                              // Use cache if available, otherwise use stream
                              final isLiked = likeCache[widget.ticketId] ?? isLikedAsync.value ?? false;

                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Paylaş butonu
                                  IconButton(
                                    tooltip: 'Paylaş',
                                    onPressed: () => _shareTicket(context, widget.ticketId),
                                    icon: const Icon(Icons.share),
                                  ),
                                  // Beğeni sayısı
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: likeCountAsync.when(
                                      data: (likeCount) => Text(
                                        likeCount.toString(),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      loading: () => const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      error: (_, __) => const Text('0'),
                                    ),
                                  ),
                                  // Favori butonu
                                  IconButton(
                                    tooltip: 'Favori',
                                    onPressed: likeToggleState.isLoading || currentUser == null
                                        ? null
                                        : () async {
                                            try {
                                              await ref.read(likeToggleProvider.notifier).toggleLike(widget.ticketId, currentUser.uid);
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
                                                );
                                              }
                                            }
                                          },
                                    icon: Icon(
                                      isLiked ? Icons.favorite : Icons.favorite_border,
                                      color: isLiked ? Colors.red : null,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Açıklama
                      Text(
                        'Açıklama',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ticket.description,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),

                      // Detaylar kartı
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildDetailRow(
                                icon: Icons.location_on,
                                title: 'Mekan',
                                value: '${ticket.venue}, ${ticket.city}',
                                theme: theme,
                              ),
                              const Divider(),
                              _buildDetailRow(
                                icon: Icons.calendar_today,
                                title: 'Tarih',
                                value: dateFormatter.format(ticket.eventDate),
                                theme: theme,
                              ),
                              const Divider(),
                              _buildDetailRow(
                                icon: Icons.access_time,
                                title: 'Saat',
                                value: timeFormatter.format(ticket.eventDate),
                                theme: theme,
                              ),
                              if (ticket.seatInfo != null) ...[
                                const Divider(),
                                _buildDetailRow(
                                  icon: Icons.event_seat,
                                  title: 'Koltuk',
                                  value: ticket.seatInfo!,
                                  theme: theme,
                                ),
                              ],
                              // Konum bilgisi ve harita
                              if (ticket.latitude != null && ticket.longitude != null) ...[
                                const Divider(),
                                // Konum bilgisi widget'ı inline
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Konum başlığı
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: theme.primaryColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Etkinlik Konumu',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    if (ticket.locationName != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        ticket.locationName!,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ],
                                    
                                    const SizedBox(height: 12),
                                    
                                    // Enhanced Google Maps widget with better UX
                                    EnhancedMapWidget(
                                      height: 200,
                                      width: double.infinity,
                                      borderRadius: 12,
                                      initialCameraPosition: CameraPosition(
                                        target: LatLng(ticket.latitude!, ticket.longitude!),
                                        zoom: 15,
                                      ),
                                      markers: {
                                        Marker(
                                          markerId: const MarkerId('event_location'),
                                          position: LatLng(ticket.latitude!, ticket.longitude!),
                                          infoWindow: InfoWindow(
                                            title: ticket.title,
                                            snippet: ticket.locationName ?? ticket.venue,
                                          ),
                                          icon: BitmapDescriptor.defaultMarkerWithHue(
                                            BitmapDescriptor.hueBlue,
                                          ),
                                        ),
                                      },
                                      onMapTap: (LatLng position) {
                                        // Harita tıklandığında tam ekran harita açmak için
                                        _showFullScreenMap(context, ticket);
                                      },
                                      showMyLocation: true,
                                      showLocationButton: true,
                                      showZoomControls: false,
                                      showMapToolbar: false,
                                    ),
                                    
                                    const SizedBox(height: 8),
                                    
                                    // Tam ekran harita butonu
                                    Center(
                                      child: TextButton.icon(
                                        onPressed: () => _showFullScreenMap(context, ticket),
                                        icon: const Icon(Icons.map),
                                        label: const Text('Haritada Göster'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: theme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const Divider(),
                              _buildDetailRow(
                                icon: Icons.person,
                                title: 'Satıcı',
                                value: ticket.sellerName,
                                theme: theme,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Fiyat kartı
                      Card(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (ticket.originalPrice >
                                      ticket.sellingPrice) ...[
                                    Text(
                                      'Orijinal Fiyat',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      '${ticket.originalPrice.toStringAsFixed(0)} ₺',
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  Text(
                                    'Satış Fiyatı',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    '${ticket.sellingPrice.toStringAsFixed(0)} ₺',
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.primaryColor,
                                        ),
                                  ),
                                ],
                              ),
                              if (ticket.originalPrice > ticket.sellingPrice)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '%${(((ticket.originalPrice - ticket.sellingPrice) / ticket.originalPrice) * 100).round()} indirim',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Hata: $error', style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ticketAsyncValue.when(
        data: (ticket) {

          final isOwnTicket = user?.uid == ticket.sellerId;
          final isSoldTicket = ticket.status == TicketStatus.sold || ticket.buyerId != null;

          return Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: isOwnTicket
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditTicketScreen(ticket: ticket),
                                ),
                              );
                            },
                            child: const Text('Düzenle'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSoldTicket
                                ? null
                                : () =>
                                    _showDeleteDialog(context, ticket, ref),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              disabledBackgroundColor:
                                  Colors.red.withValues(alpha: 0.4),
                            ),
                            child: Text(isSoldTicket ? 'Satıldı' : 'Sil'),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: user == null
                                  ? null
                                  : () {
                                      _startConversation(context, ticket, ref);
                                    },
                              child: const Text('Mesaj Gönder'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: (user == null || isSoldTicket)
                                  ? null
                                  : () {
                                      _navigateToCheckout(context, ticket, ref);
                                    },
                              child: Text(isSoldTicket ? 'Satıldı' : 'Satın Al'),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.primaryColor),
          const SizedBox(width: 12),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  void _startConversation(BuildContext context, ticket, WidgetRef ref) async {
    final user = ref.read(authStateChangesProvider).value;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mesaj göndermek için giriş yapmanız gerekiyor'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Sipariş detayındaki ile aynı conversation ID formatını kullan
    final conversationId = '${user.uid}_${ticket.sellerId}';
    
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FirebaseChatScreen(
            conversationId: conversationId,
            otherUserId: ticket.sellerId,
            otherUserName: ticket.sellerName,
            otherUserAvatarUrl: _guardAvatar(ticket.sellerAvatarUrl),
          ),
        ),
      );
    }
  }

  String? _guardAvatar(String? url) => (url == null || url.isEmpty) ? null : url;


  // Deprecated methods - keeping stubs for compatibility
  void _shareTicket(BuildContext context, String ticketId) {
    // Implementation removed - use share_plus package directly
  }

  void _showFullScreenMap(BuildContext context, Ticket ticket) {
    if (ticket.latitude == null || ticket.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu bilet için konum bilgisi bulunmuyor'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenMapWidget(ticket: ticket),
        fullscreenDialog: true,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, dynamic ticket, WidgetRef ref) {
    // Implementation removed - add delete functionality if needed
  }

  void _navigateToCheckout(BuildContext context, dynamic ticket, WidgetRef ref) {
    final user = ref.read(authStateChangesProvider).value;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Satın almak için giriş yapmanız gerekiyor'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CheckoutScreen(
            ticket: ticket,
            buyer: user,
          ),
        ),
      );
    }
  }

}
