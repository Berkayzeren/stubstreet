// lib/features/tickets/presentation/screens/my_tickets_screen.dart

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/ticket_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../orders/domain/entities/order.dart';
import '../../domain/entities/ticket.dart';
import 'ticket_detail_screen.dart';
import 'add_ticket_screen.dart';
import '../../../../shared_widgets/animated_fab.dart';
import 'edit_ticket_screen.dart';
import '../../../../core/mixins/scroll_to_top_mixin.dart';

class MyTicketsScreen extends ConsumerStatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  ConsumerState<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends ConsumerState<MyTicketsScreen>
    with SingleTickerProviderStateMixin, ScrollToTopMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateChangesProvider).value;
    final theme = Theme.of(context);

    // Debug: Auth durumunu konsola yazdır
    developer.log('🔐 MyTickets Auth State - User: ${user?.uid ?? 'null'}, Email: ${user?.email ?? 'null'}', name: 'MyTicketsScreen');
    
    // Temporary: Show placeholder content instead of blocking access
    if (user == null) {
      // Giriş yapmamış kullanıcılara giriş yapması gerektiğini söyle
      return Scaffold(
        appBar: AppBar(title: const Text('Biletlerim')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Biletlerinizi görmek için giriş yapın',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      // Top bar kaldırıldı; yalnızca TabBar gösterilecek
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_bag), text: 'Satın Aldığım'),
            Tab(icon: Icon(Icons.sell), text: 'Sattığım'),
            Tab(icon: Icon(Icons.inventory), text: 'Stokta'),
            Tab(icon: Icon(Icons.favorite), text: 'Favorilerim'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPurchasedTickets(user.uid),
          _buildSoldTickets(user.uid),
          _buildStockTickets(user.uid),
          _buildFavoriteTickets(),
        ],
      ),
      // Enhanced animated floating action button for adding tickets
      floatingActionButton: AnimatedFab(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddTicketScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: 'Bilet Ekle',
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        isExtended: true,
        heroTag: 'add_ticket_fab',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildPurchasedTickets(String userId) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userTicketsProvider);
      },
      child: _buildTicketList(
        emptyMessage: 'Henüz bilet satın almamışsınız',
        emptyIcon: Icons.shopping_cart_outlined,
        filterType: TicketFilterType.purchased,
      ),
    );
  }

  Widget _buildSoldTickets(String userId) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userTicketsProvider);
      },
      child: _buildTicketList(
        emptyMessage: 'Henüz bilet satmamışsınız',
        emptyIcon: Icons.sell_outlined,
        filterType: TicketFilterType.selling,
      ),
    );
  }



  Widget _buildTicketList({
    required String emptyMessage,
    required IconData emptyIcon,
    required TicketFilterType filterType,
  }) {
    final user = ref.watch(authStateChangesProvider).value;
    if (user == null) return const SizedBox();

    final ticketsAsync = ref.watch(userTicketsProvider(user.uid));
    final purchasedAsync = ref.watch(userPurchasedOrdersProvider(user.uid));

    return ticketsAsync.when(
      data: (tickets) {
        // Filter tickets based on type
        List<Ticket> filteredTickets;
        switch (filterType) {
          case TicketFilterType.purchased:
            return purchasedAsync.when(
              data: (orders) {
                final dedupedMap = <String, Order>{};
                for (final order in orders) {
                  final key = order.ticketId.isNotEmpty ? order.ticketId : order.id;
                  dedupedMap.putIfAbsent(key, () => order);
                }

                final displayOrders = dedupedMap.values.toList();

                if (displayOrders.isEmpty) {
                  return _buildEmptyState(emptyMessage, emptyIcon, filterType);
                }

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: displayOrders.length,
                  itemBuilder: (context, index) {
                    final order = displayOrders[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildOrderCard(order),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) {
                developer.log('❌ Satın alınan biletler yüklenirken hata: $error', name: 'MyTicketsScreen', error: error, stackTrace: stackTrace);
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Satın alınan biletler yüklenirken hata oluştu'),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(userPurchasedOrdersProvider(user.uid)),
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                );
              },
            );
          case TicketFilterType.selling:
            filteredTickets = tickets
                .where((ticket) => ticket.sellerId == user.uid)
                .toList();
            break;
          case TicketFilterType.favorites:
            // Beğenilen biletleri al
            return ref.watch(userLikedTicketsProvider(user.uid)).when(
              data: (likedTicketIds) {
                developer.log('📋 DEBUG: Beğenilen bilet ID\'leri: $likedTicketIds', name: 'MyTicketsScreen');
                
                // Tüm biletlerden beğenilenleri filtrelemek için ticketsProvider kullan
                return ref.watch(ticketsProvider).when(
                  data: (allTickets) {
                    developer.log('🎫 DEBUG: Toplam ${allTickets.length} bilet var', name: 'MyTicketsScreen');
                    
                    final favoriteTickets = allTickets
                        .where((ticket) => likedTicketIds.contains(ticket.id))
                        .toList();
                    
                    developer.log('❤️ DEBUG: ${favoriteTickets.length} favori bilet bulundu', name: 'MyTicketsScreen');
                
                if (favoriteTickets.isEmpty) {
                  return _buildEmptyState(emptyMessage, emptyIcon, filterType);
                }
                
                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: favoriteTickets.length,
                  itemBuilder: (context, index) {
                    final ticket = favoriteTickets[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildTicketCard(ticket, filterType),
                    );
                  },
                );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) {
                    developer.log('❌ Biletler yüklenirken hata: $error', name: 'MyTicketsScreen', error: error, stackTrace: stack);
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          const Text('Biletler yüklenirken hata oluştu'),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref.invalidate(ticketsProvider);
                              ref.invalidate(userLikedTicketsProvider(user.uid));
                            },
                            child: const Text('Tekrar Dene'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) {
                developer.log('❌ Favoriler yüklenirken hata: $error', name: 'MyTicketsScreen', error: error, stackTrace: stack);
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Favoriler yüklenirken hata oluştu'),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(userLikedTicketsProvider(user.uid)),
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                );
              },
            );
        }

        if (filteredTickets.isEmpty) {
          return _buildEmptyState(emptyMessage, emptyIcon, filterType);
        }

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: filteredTickets.length,
          itemBuilder: (context, index) {
            final ticket = filteredTickets[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTicketCard(ticket, filterType),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Biletler yüklenirken hata oluştu',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(userTicketsProvider),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('dd MMM yyyy', 'tr_TR');
    final timeFormatter = DateFormat('HH:mm', 'tr_TR');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(order.status.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    order.metadata?['ticketTitle'] ?? 'Bilet',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status.displayName,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.event, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.metadata?['eventName'] ?? 'Etkinlik',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${dateFormatter.format(order.createdAt)} • ${timeFormatter.format(order.createdAt)}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.totalAmount.toStringAsFixed(0)} ${order.currency}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    Text(
                      'Ödenen Tutar',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) => TicketDetailScreen(ticketId: order.ticketId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code, size: 16),
                  label: const Text('Bileti Aç'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    String message,
    IconData icon,
    TicketFilterType type,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (type == TicketFilterType.selling)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddTicketScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('İlk Biletini Ekle'),
            ),
          if (type == TicketFilterType.purchased)
            ElevatedButton.icon(
              onPressed: () {
                // Ana sayfaya yönlendir ve bilet ara tab'ına geç (tab index 1 = Search Tickets)
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/home',
                  (route) => false,
                  arguments: {'tabIndex': 1}, // Bilet arama tab'ı
                );
              },
              icon: const Icon(Icons.search),
              label: const Text('Bilet Ara'),
            ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Ticket ticket, TicketFilterType type) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('dd MMM yyyy', 'tr_TR');
    final timeFormatter = DateFormat('HH:mm', 'tr_TR');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => TicketDetailScreen(ticketId: ticket.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  Text(
                    ticket.category.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ticket.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(ticket, type),
                ],
              ),
              const SizedBox(height: 12),

              // Event details
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${ticket.venue}, ${ticket.city}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${dateFormatter.format(ticket.eventDate)} • ${timeFormatter.format(ticket.eventDate)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Price and actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ticket.originalPrice > ticket.sellingPrice) ...[
                        Text(
                          '${ticket.originalPrice.toStringAsFixed(0)} ₺',
                          style: theme.textTheme.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      Text(
                        '${ticket.sellingPrice.toStringAsFixed(0)} ₺',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  _buildActionButton(ticket, type),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(Ticket ticket, TicketFilterType type) {
    Color color;
    String text;
    IconData icon;

    switch (ticket.status) {
      case TicketStatus.available:
        color = Colors.green;
        text = 'Aktif';
        icon = Icons.check_circle;
        break;
      case TicketStatus.sold:
        color = Colors.blue;
        text = 'Satıldı';
        icon = Icons.done_all;
        break;
      case TicketStatus.reserved:
        color = Colors.orange;
        text = 'Rezerve';
        icon = Icons.schedule;
        break;
      case TicketStatus.expired:
        color = Colors.red;
        text = 'Süresi Doldu';
        icon = Icons.timer_off;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Ticket ticket, TicketFilterType type) {
    switch (type) {
      case TicketFilterType.selling:
        if (ticket.status == TicketStatus.available) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  // Bilet düzenleme ekranına yönlendir
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditTicketScreen(ticket: ticket),
                    ),
                  );
                },
                icon: const Icon(Icons.edit, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  foregroundColor: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  _showDeleteDialog(ticket);
                },
                icon: const Icon(Icons.delete, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          );
        } else {
          return const SizedBox();
        }
      case TicketFilterType.purchased:
        return ElevatedButton.icon(
          onPressed: () {
            // Show QR code or download ticket
          },
          icon: const Icon(Icons.qr_code, size: 16),
          label: const Text('QR Kod'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );
      case TicketFilterType.favorites:
        return IconButton(
          onPressed: () async {
            // Remove from favorites
            final user = ref.read(authStateChangesProvider).value;
            if (user != null) {
              final scaffoldMessengerContext = ScaffoldMessenger.of(context);
              
              try {
                await ref
                    .read(likeToggleProvider.notifier)
                    .toggleLike(ticket.id, user.uid);
                
                if (mounted) {
                  // Favoriler listesini yenile
                  ref.invalidate(userLikedTicketsProvider(user.uid));
                  
                  scaffoldMessengerContext.showSnackBar(
                    const SnackBar(
                      content: Text('Favorilerden kaldırıldı'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessengerContext.showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
          icon: const Icon(Icons.favorite, color: Colors.red),
        );
    }
  }

  void _showDeleteDialog(Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bileti Sil'),
        content: Text(
          '${ticket.title} biletini silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigatorContext = Navigator.of(context);
              final scaffoldMessengerContext = ScaffoldMessenger.of(context);
              
              navigatorContext.pop();
              try {
                await ref
                    .read(ticketFormProvider.notifier)
                    .deleteTicket(ticket.id);
                
                // Invalidate all ticket-related providers to refresh all lists
                ref.invalidate(ticketsProvider);
                ref.invalidate(userTicketsProvider(ticket.sellerId));
                ref.invalidate(ticketDetailProvider(ticket.id));
                
                if (mounted) {
                  scaffoldMessengerContext.showSnackBar(
                    const SnackBar(
                      content: Text('Bilet başarıyla silindi! Tüm listelerden kaldırıldı.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessengerContext.showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  /// Stokta olan biletler
  Widget _buildStockTickets(String userId) {
    final ticketsAsyncValue = ref.watch(userTicketsProvider(userId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userTicketsProvider(userId));
      },
      child: ticketsAsyncValue.when(
        data: (tickets) {
          final availableTickets = tickets
              .where((ticket) => ticket.status == TicketStatus.available)
              .toList();
          
          if (availableTickets.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Stokta biletiniz yok',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            controller: scrollController,
            itemCount: availableTickets.length,
            itemBuilder: (context, index) {
              final ticket = availableTickets[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(ticket.title),
                  subtitle: Text('${ticket.venue}, ${ticket.city}'),
                  trailing: Text('${ticket.sellingPrice.toStringAsFixed(0)} ₺'),
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) => TicketDetailScreen(ticketId: ticket.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Hata: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(userTicketsProvider(userId)),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Favori biletler
  Widget _buildFavoriteTickets() {
    return _buildTicketList(
      emptyMessage: 'Henüz favori biletiniz yok',
      emptyIcon: Icons.favorite_border,
      filterType: TicketFilterType.favorites,
    );
  }
}

enum TicketFilterType { purchased, selling, favorites }
