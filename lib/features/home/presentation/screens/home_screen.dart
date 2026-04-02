// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/theme_provider.dart' as notification_prefs;
import '../../../../core/providers/user_preferences_provider.dart';
import '../../../../core/providers/admin_provider.dart';
import '../../../admin/presentation/screens/admin_notifications_screen.dart';
import '../../../admin/presentation/screens/admin_user_management_screen.dart';
import '../../../../core/services/push_notification_handler.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../tickets/presentation/providers/ticket_providers.dart';
import '../../../tickets/presentation/screens/ticket_detail_screen.dart';
import '../../../tickets/presentation/widgets/ticket_card.dart';
import '../../../events/presentation/providers/platform_providers.dart';
import '../../../events/presentation/widgets/event_card.dart';
import '../../../events/presentation/screens/event_detail_screen.dart';
import '../../../events/domain/entities/event.dart';
import '../widgets/category_chips.dart';
import '../widgets/search_bar_widget.dart';
import '../../../tickets/presentation/screens/add_ticket_screen.dart';
import '../../../tickets/presentation/screens/my_tickets_screen.dart';
import '../../../conversations/presentation/screens/firebase_conversations_list_screen.dart';
import '../../../auth/presentation/screens/advanced_profile_screen.dart';
import '../../../settings/presentation/screens/privacy_settings_screen.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/animated_home_header.dart';
import '../widgets/category_showcase_card.dart';
import '../widgets/animated_stats_card.dart';
import '../widgets/trending_tickets_carousel.dart';
import '../../../../core/navigation/navigation_extensions.dart';
import '../../../../shared_widgets/responsive_wrapper.dart';
import '../../../../shared_widgets/responsive_bottom_navigation.dart';
import '../../../../core/services/app_prefs.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../conversations/presentation/providers/firebase_chat_providers.dart';
import '../../../../core/mixins/scroll_to_top_mixin.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final int? initialTabIndex;
  final bool isGuestMode;
  
  const HomeScreen({
    super.key, 
    this.initialTabIndex,
    this.isGuestMode = false,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with ScrollToTopMixin {
  TicketCategory? selectedCategory;
  String searchQuery = '';
  int _selectedIndex = 0; // initial index Home
  
  // Cache için trending tickets
  List<Ticket>? _cachedTrendingTickets;
  int? _lastTicketsLength;

  @override
  void initState() {
    super.initState();
    // Eğer initialTabIndex verilmişse, o index'i kullan
    if (widget.initialTabIndex != null) {
      _selectedIndex = widget.initialTabIndex!;
    }
  }

  Future<void> _refreshHome() async {
    // Haptic feedback for better mobile UX
    HapticFeedback.mediumImpact();
    // Refresh providers
    // Ana akış
    ref.invalidate(ticketsProvider);
    ref.invalidate(hybridEventsProvider);
    // Arama sonuçları
    try { ref.read(searchResultsProvider.notifier).clearResults(); } catch (_) {}
    // Mesajlar ve rozet
    try { ref.invalidate(totalUnreadMessagesCountProvider); } catch (_) {}
    try { ref.invalidate(userConversationsProvider); } catch (_) {}
    // Kısa gecikme kullanıcı deneyimi için
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Filtre bottom sheet'ini göster
  void _showFilterBottomSheet() {
    HapticFeedback.mediumImpact();
    final l10n = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtrele',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Kategori Seç',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TicketCategory.values.map((category) {
                final isSelected = selectedCategory == category;
                return FilterChip(
                  selected: isSelected,
                  onSelected: (selected) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      selectedCategory = selected ? category : null;
                      _selectedIndex = 1; // Arama sekmesine geç
                    });
                    Navigator.pop(context);
                  },
                  label: Text(_getCategoryName(category, l10n)),
                  avatar: Icon(
                    _getCategoryIcon(category),
                    size: 18,
                    color: isSelected ? Colors.white : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    selectedCategory = null;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Filtreyi Temizle'),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  // Helper functions for categories
  String _getCategoryName(TicketCategory category, AppLocalizations l10n) {
    switch (category) {
      case TicketCategory.concert:
        return l10n.concerts;
      case TicketCategory.sports:
        return l10n.sports;
      case TicketCategory.theater:
        return 'Tiyatro';
      case TicketCategory.festival:
        return 'Festival';
      default:
        return category.name;
    }
  }

  IconData _getCategoryIcon(TicketCategory category) {
    switch (category) {
      case TicketCategory.concert:
        return Icons.music_note;
      case TicketCategory.sports:
        return Icons.sports_soccer;
      case TicketCategory.theater:
        return Icons.theater_comedy;
      case TicketCategory.festival:
        return Icons.festival;
      default:
        return Icons.category;
    }
  }


  // _pages sırası BottomNavigation ile eşleşecek şekilde: [Home (Events), Search (Tickets), Add, MyTickets, Messages]
  List<Widget> get _pages => [
        _buildEventsHomeBody(),
        _buildTicketSearchBody(),
        // Add Ticket tab: doğrudan bilet ekleme ekranı
        const AddTicketScreen(),
        const MyTicketsScreen(),
        const FirebaseConversationsListScreen(),
      ];

  // Eski ana sayfa (bilet listesi) artık arama sekmesine taşındı
  Widget _buildTicketSearchBody() {
    final ticketsAsyncValue = selectedCategory != null
        ? ref.watch(ticketsByCategoryProvider(selectedCategory!))
        : ref.watch(ticketsProvider);
    final searchResults = ref.watch(searchResultsProvider);

    return ResponsiveWrapper(
      mobile: _buildMobileLayout(ticketsAsyncValue, AsyncValue.data(searchResults)),
      tablet: _buildTabletLayout(ticketsAsyncValue, AsyncValue.data(searchResults)),
      desktop: _buildDesktopLayout(ticketsAsyncValue, AsyncValue.data(searchResults)),
    );
  }

  // Yeni ana sayfa: Modern tasarım
  Widget _buildEventsHomeBody() {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authStateChangesProvider).value;
    final ticketsAsyncValue = ref.watch(ticketsProvider);
    
    return ticketsAsyncValue.when(
      data: (tickets) {
        // Trend biletleri belirle (performans optimizasyonu için cache kullan)
        if (_cachedTrendingTickets == null || _lastTicketsLength != tickets.length) {
          final trendingTickets = List<Ticket>.from(tickets)
            ..sort((a, b) => b.saleDate.compareTo(a.saleDate));
          _cachedTrendingTickets = trendingTickets.take(5).toList();
          _lastTicketsLength = tickets.length;
        }
        final topTrending = _cachedTrendingTickets!;
        
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
              // Animated header
              AnimatedHomeHeader(
                userName: user?.displayName ?? l10n.guest,
                onSearchTap: () {
                  // Haptic feedback
                  HapticFeedback.lightImpact();
                  // Index 1'e (arama sekmesine) geç
                  setState(() {
                    _selectedIndex = 1;
                  });
                  // Yeni sekmede en üste kaydır
                  scrollToTop();
                },
                onFilterTap: _showFilterBottomSheet,
              ),
              
              // Stats section - Mobil optimize edilmiş horizontal scroll
              SizedBox(
                height: 140,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    final stats = [
                      (
                        title: l10n.activeTicket,
                        count: tickets.where((t) => t.status == TicketStatus.available).length,
                        icon: Icons.confirmation_number,
                        color: Colors.blue,
                        changePercentage: 12.5,
                      ),
                      (
                        title: l10n.totalSellers,
                        count: tickets.map((t) => t.sellerId).toSet().length,
                        icon: Icons.people,
                        color: Colors.green,
                        changePercentage: -5.2,
                      ),
                      (
                        title: l10n.thisWeek,
                        count: tickets.where((t) {
                          final now = DateTime.now();
                          final weekAgo = now.subtract(const Duration(days: 7));
                          return t.saleDate.isAfter(weekAgo);
                        }).length,
                        icon: Icons.calendar_today,
                        color: Colors.orange,
                        changePercentage: 25.0,
                      ),
                      (
                        title: l10n.categories,
                        count: TicketCategory.values.length,
                        icon: Icons.category,
                        color: Colors.purple,
                        changePercentage: null,
                      ),
                    ];
                    
                    final stat = stats[index];
                    return Container(
                      width: 180,
                      margin: EdgeInsets.only(
                        left: index == 0 ? 8 : 0,
                        right: 16,
                      ),
                      child: AnimatedStatsCard(
                        title: stat.title,
                        count: stat.count,
                        icon: stat.icon,
                        color: stat.color,
                        changePercentage: stat.changePercentage,
                      ),
                    );
                  },
                ),
              ),
              
              // Trending tickets carousel
              if (topTrending.isNotEmpty) ...[
                const SizedBox(height: 32),
                TrendingTicketsCarousel(tickets: topTrending),
              ],
              
              // Category showcase cards
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.categories,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Mobil optimize edilmiş responsive grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = constraints.maxWidth;
                        final crossAxisCount = screenWidth > 600 ? 3 : 2;
                        final childAspectRatio = screenWidth < 400 ? 1.0 : 1.1;
                        
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: screenWidth < 400 ? 8 : 12,
                          mainAxisSpacing: screenWidth < 400 ? 8 : 12,
                          childAspectRatio: childAspectRatio,
                        children: [
                          CategoryShowcaseCard(
                            title: l10n.concerts,
                            subtitle: l10n.concertsDescription,
                            icon: Icons.music_note,
                            gradientColors: [Colors.purple, Colors.deepPurple],
                            itemCount: tickets.where((t) => t.category == TicketCategory.concert).length,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _selectedIndex = 1;
                                selectedCategory = TicketCategory.concert;
                              });
                              scrollToTop();
                            },
                          ),
                          CategoryShowcaseCard(
                            title: l10n.sports,
                            subtitle: 'Heyecan dolu maçlar',
                            icon: Icons.sports_soccer,
                            gradientColors: [Colors.green, Colors.teal],
                            itemCount: tickets.where((t) => t.category == TicketCategory.sports).length,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _selectedIndex = 1;
                                selectedCategory = TicketCategory.sports;
                              });
                              scrollToTop();
                            },
                          ),
                          CategoryShowcaseCard(
                            title: 'Tiyatro',
                            subtitle: 'Kültür ve sanat',
                            icon: Icons.theater_comedy,
                            gradientColors: [Colors.orange, Colors.deepOrange],
                            itemCount: tickets.where((t) => t.category == TicketCategory.theater).length,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _selectedIndex = 1;
                                selectedCategory = TicketCategory.theater;
                              });
                              scrollToTop();
                            },
                          ),
                          CategoryShowcaseCard(
                            title: 'Festival',
                            subtitle: 'Unutulmaz anlar',
                            icon: Icons.festival,
                            gradientColors: [Colors.pink, Colors.red],
                            itemCount: tickets.where((t) => t.category == TicketCategory.festival).length,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _selectedIndex = 1;
                                selectedCategory = TicketCategory.festival;
                              });
                              scrollToTop();
                            },
                          ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Platform istatistikleri bölümü
              const SizedBox(height: 32),
              const _EventsHome(),
              
              const SizedBox(height: 100), // Bottom padding for FAB
            ],
          ),
        ),
        ],
      );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Hata: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(ticketsProvider),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    final l10n = AppLocalizations.of(context)!;
    
    // Okunmamış mesaj sayısını al
    final totalUnreadMessages = ref.watch(totalUnreadMessagesCountProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).scaffoldBackgroundColor,
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshIndicator(
          triggerMode: RefreshIndicatorTriggerMode.onEdge,
          notificationPredicate: (notification) => notification.depth == 0 && (_selectedIndex == 0 || _selectedIndex == 1),
          onRefresh: _refreshHome,
          child: NestedScrollView(
            controller: scrollController,
            floatHeaderSlivers: true,
            physics: const AlwaysScrollableScrollPhysics(),
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              floating: true,
              pinned: false,
              snap: true,
              title: Text(
                l10n.appTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              centerTitle: true,
              actions: [
                // Guest mode indicator
                if (widget.isGuestMode) ...[
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.guest,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Profil butonu
                IconButton(
                  onPressed: () {
                    context.pushSwipeBack(
                      (context) => const AdvancedProfileScreen(),
                    );
                  },
                  icon: const Icon(Icons.person),
                  tooltip: l10n.profile,
                ),
                
                // Gelişmiş ayarlar butonu
                IconButton(
                  onPressed: () {
                    _showAdvancedSettings(context);
                  },
                  icon: const Icon(Icons.settings),
                  tooltip: l10n.settings,
                ),
                
                // Guest mode: Show login button, otherwise show logout
                if (widget.isGuestMode) ...[
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/login');
                    },
                    icon: const Icon(Icons.login, size: 18),
                    label: Text(l10n.login, style: const TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ] else ...[
                  // Logout butonu
                  IconButton(
                    onPressed: () {
                      _showLogoutDialog(context);
                    },
                    icon: const Icon(Icons.logout),
                    tooltip: l10n.signOut,
                  ),
                ],
              ],
            ),
            ],
            body: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ),
      bottomNavigationBar: ResponsiveBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          // 0 - Home
          ResponsiveBottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: l10n.home,
            semanticLabel: 'Home tab',
            tooltip: 'Home',
          ),
          // 1 - Search Tickets
          ResponsiveBottomNavigationBarItem(
            icon: const Icon(Icons.search),
            activeIcon: const Icon(Icons.search),
            label: l10n.searchTickets,
            semanticLabel: 'Search tickets tab',
            tooltip: 'Search tickets',
          ),
          // 2 - Add Ticket
          ResponsiveBottomNavigationBarItem(
            icon: const Icon(Icons.add_circle_outline),
            activeIcon: const Icon(Icons.add_circle),
            label: l10n.addTicket,
            semanticLabel: 'Add ticket tab',
            tooltip: 'Add new ticket for sale',
          ),
          // 3 - My Tickets
          ResponsiveBottomNavigationBarItem(
            icon: const Icon(Icons.confirmation_number_outlined),
            activeIcon: const Icon(Icons.confirmation_number),
            label: l10n.myTickets,
            semanticLabel: 'My tickets tab',
            tooltip: 'View my tickets',
          ),
          // 4 - Messages
          ResponsiveBottomNavigationBarItem(
            icon: const Icon(Icons.message_outlined),
            activeIcon: const Icon(Icons.message),
            label: l10n.messages,
            semanticLabel: 'Messages tab',
            tooltip: 'View messages',
            badgeCount: totalUnreadMessages,
          ),
        ],
      ),
      ), // Close Container
    ); // Close home screen widget
  }

  void _onItemTapped(int index) {
    final user = ref.read(authStateChangesProvider).value;
    
    // Restrict certain tabs for guest users
    if (widget.isGuestMode && user == null) {
      // Tabs 0 (Home) and 1 (Search) are allowed for guests
      // Tabs 2 (Add), 3 (My Tickets), 4 (Messages) require authentication
      if (index >= 2) {
        _showLoginPrompt(index);
        return;
      }
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }
  
  void _showLoginPrompt(int requestedTab) {
    final l10n = AppLocalizations.of(context)!;
    final tabNames = [l10n.home, l10n.searchTickets, l10n.addTicket, l10n.myTickets, l10n.messages];
    final tabName = requestedTab < tabNames.length ? tabNames[requestedTab] : l10n.featureComingSoon;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.loginRequired),
        content: Text('$tabName ${l10n.loginToUseFeature}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/login');
            },
            child: const Text('Giriş Yap'),
          ),
        ],
      ),
    );
  }












  Widget _buildMobileLayout(
    AsyncValue<List<Ticket>> ticketsAsyncValue,
    AsyncValue<List<Ticket>> searchResults,
  ) {
    return Column(
      children: [
        // Arama çubuğu
        SearchBarWidget(
          onSearch: (query) {
            setState(() {
              searchQuery = query;
            });
            if (query.isNotEmpty) {
              ref.read(searchResultsProvider.notifier).search(query);
            } else {
              ref.read(searchResultsProvider.notifier).clearResults();
            }
          },
        ),

        // Kategori filtreleri
        if (searchQuery.isEmpty)
          CategoryChips(
            selectedCategory: selectedCategory,
            onCategorySelected: (category) {
              setState(() {
                selectedCategory = category;
              });
            },
          ),

        // Bilet listesi
        Expanded(child: _buildTicketGrid(ticketsAsyncValue, searchResults, 1)),
      ],
    );
  }

  Widget _buildTabletLayout(
    AsyncValue<List<Ticket>> ticketsAsyncValue,
    AsyncValue<List<Ticket>> searchResults,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Arama çubuğu
          SearchBarWidget(
            onSearch: (query) {
              setState(() {
                searchQuery = query;
              });
              if (query.isNotEmpty) {
                ref.read(searchResultsProvider.notifier).search(query);
              } else {
                ref.read(searchResultsProvider.notifier).clearResults();
              }
            },
          ),

          // Kategori filtreleri
          if (searchQuery.isEmpty)
            CategoryChips(
              selectedCategory: selectedCategory,
              onCategorySelected: (category) {
                setState(() {
                  selectedCategory = category;
                });
              },
            ),

          // Bilet listesi - Grid layout for tablet
          Expanded(
            child: _buildTicketGrid(ticketsAsyncValue, searchResults, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    AsyncValue<List<Ticket>> ticketsAsyncValue,
    AsyncValue<List<Ticket>> searchResults,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar with search and filters
          SizedBox(
            width: 300,
            child: Column(
              children: [
                const SizedBox(height: 16),
                SearchBarWidget(
                  onSearch: (query) {
                    setState(() {
                      searchQuery = query;
                    });
                    if (query.isNotEmpty) {
                      ref.read(searchResultsProvider.notifier).search(query);
                    } else {
                      ref.read(searchResultsProvider.notifier).clearResults();
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (searchQuery.isEmpty)
                  CategoryChips(
                    selectedCategory: selectedCategory,
                    onCategorySelected: (category) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Main content area
          Expanded(
            child: _buildTicketGrid(ticketsAsyncValue, searchResults, 3),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketGrid(
    AsyncValue<List<Ticket>> ticketsAsyncValue,
    AsyncValue<List<Ticket>> searchResults,
    int crossAxisCount,
  ) {
    final user = ref.watch(authStateChangesProvider).value;

    // Auth check for ticket access

    // Guest browsing allowed - auth required only for interactions
    if (widget.isGuestMode && user == null) {
      // Show guest browsing banner at top of ticket list
      return Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                                  Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.8),
                Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.6),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_add_outlined,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Misafir olarak geziniyorsunuz',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Bilet satın alıp satmak için hesap oluşturun',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/login'),
                  icon: const Icon(Icons.login, size: 16),
                  label: const Text('Giriş Yap', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 0),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildTicketListContent(ticketsAsyncValue, searchResults, crossAxisCount)),
        ],
      );
    }
    
    // Authenticated users see full content
    return _buildTicketListContent(ticketsAsyncValue, searchResults, crossAxisCount);
  }

  Widget _buildTicketListContent(
    AsyncValue<List<Ticket>> ticketsAsyncValue,
    AsyncValue<List<Ticket>> searchResults,
    int crossAxisCount,
  ) {
    // Original auth check (keeping commented for reference):
    // if (user == null) {
    //   return Center(
    //     child: Column(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: [
    //         const Icon(Icons.login, size: 64, color: Colors.grey),
    //         const SizedBox(height: 16),
    //         Text(
    //           'Biletleri görüntülemek için giriş yapmalısınız.',
    //           style: TextStyle(
    //             fontSize: 18,
    //             color: Theme.of(context).brightness == Brightness.dark
    //                 ? Colors.white70
    //                 : Colors.grey,
    //           ),
    //           textAlign: TextAlign.center,
    //         ),
    //       ],
    //     ),
    //   );
    // }

    // Eğer arama yapılmışsa arama sonuçlarını göster
    if (searchQuery.isNotEmpty) {
      return searchResults.when(
        data: (tickets) => _buildTicketGridView(tickets, crossAxisCount),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Arama hatası: $error')),
      );
    }

    // Normal bilet listesi
    return ticketsAsyncValue.when(
      data: (tickets) => _buildTicketGridView(tickets, crossAxisCount),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Biletler yüklenirken bir sorun oluştu',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                // Refresh the data
                ref.invalidate(ticketsProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketGridView(List<Ticket> tickets, int crossAxisCount) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Henüz satışta bilet yok.',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (crossAxisCount == 1) {
      // List view for mobile
      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return TicketCard(
            ticket: ticket,
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => TicketDetailScreen(ticketId: ticket.id),
                ),
              );
            },
          );
        },
      );
    } else {
      // Grid view for tablet and desktop
      return GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return TicketCard(
            ticket: ticket,
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => TicketDetailScreen(ticketId: ticket.id),
                ),
              );
            },
          );
        },
      );
    }
  }

  /// Bottom-to-top slide animation için custom route oluşturur
  Route _createSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  /// Gelişmiş ayarlar menüsünü gösterir
  /// Tema seçimi, dil seçimi, bildirimler, gizlilik ve diğer ayarları içerir
  void _showAdvancedSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AdvancedSettingsSheet(
        currentTheme: ref.read(notification_prefs.themeNotifierProvider),
        onThemeChanged: (theme) {
          ref.read(notification_prefs.themeNotifierProvider.notifier).setTheme(theme);
        },
        onNavigateToPage: (page) {
          Navigator.of(context).push(_createSlideRoute(page));
        },
        onResetOnboarding: const bool.fromEnvironment('dart.vm.product') == false
            ? () async {
                await AppPrefs.resetOnboarding();
                if (!mounted) return; // Check mounted after async operation
                // ignore: use_build_context_synchronously
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            : null,
      ),
    );
  }

  /// Çıkış yapmak için onay dialogu gösterir
  /// Kullanıcının yanlışlıkla çıkış yapmasını önler
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Sign out, clear guest mode, and reset onboarding so user sees intro again
              await ref.read(authRepositoryProvider).signOut();
              await AppPrefs.clearGuestMode();
              await AppPrefs.resetOnboarding();
              
              // Navigate to root and clear all routes
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}

class _EventsHome extends ConsumerWidget {
  const _EventsHome();

  /// Etkinlik detay sayfasına yönlendirme fonksiyonu
  /// [event] parametresi gösterilecek etkinlik bilgilerini içerir
  void _navigateToEventDetail(BuildContext context, EventItem event) {
    context.pushSwipeBack(
      (context) => EventDetailScreen(event: event),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hibrit events provider'ını kullan - tüm platformlardan etkinlikler - Enhanced with more events
    final hybridEventsAsync = ref.watch(hybridEventsProvider(limit: 50));
    
                return hybridEventsAsync.when(
              data: (unifiedEvents) {
                // Platform istatistiklerini güncelle (güvenli şekilde)
                final platformStats = ref.read(platformStatsProvider);
                final currentTotal = platformStats['total_events'] as int? ?? 0;
                if (currentTotal != unifiedEvents.length) {
                  // Güncellemeyi geciktir ve sadece bir kez yap
                  Future.microtask(() {
                    if (context.mounted) {
                      ref.read(platformStatsProvider.notifier).updateStats(unifiedEvents);
                    }
                  });
                }
                
                // UnifiedEvent'leri EventItem'a dönüştür (geriye uyumluluk için)
                final events = unifiedEvents
                    .where((ue) => ue.imageUrl != null && ue.imageUrl!.isNotEmpty) // Görseli olmayanları filtrele
                    .map((ue) => ue.toEventItem())
                    .toList();
        
        if (events.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event, size: 56, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'Etkinlik bulunamadı.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }

        // Etkinlikleri kategorilere göre grupla
        final categorizedEvents = <String, List<EventItem>>{};
        for (final event in events) {
          final category = event.genre ?? 'Diğer';
          categorizedEvents[category] = [...(categorizedEvents[category] ?? []), event];
        }

        // Kategorileri sırala (en çok etkinlik olandan başla)
        final sortedCategories = categorizedEvents.entries.toList()
          ..sort((a, b) => b.value.length.compareTo(a.value.length));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedCategories.length,
          itemBuilder: (context, categoryIndex) {
            final category = sortedCategories[categoryIndex];
            final categoryName = category.key;
            final categoryEvents = category.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kategori başlığı
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          categoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '(${categoryEvents.length} etkinlik)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Yatay kaydırmalı etkinlik listesi (tek kart görünür)
                SizedBox(
                  height: 300,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: PageView.builder(
                      controller: PageController(viewportFraction: 1.0),
                      itemCount: categoryEvents.length,
                      physics: const PageScrollPhysics(),
                      itemBuilder: (context, index) {
                        final event = categoryEvents[index];
                        return EventCard(
                          event: event,
                          onTap: () => _navigateToEventDetail(context, event),
                        );
                      },
                    ),
                  ),
                ),
                if (categoryIndex < sortedCategories.length - 1)
                  const Divider(height: 32),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Etkinlikler yüklenemedi: $e'),
        ),
      ),
    );
  }
}

/// Gelişmiş ayarlar menüsü için bottom sheet widget'ı
/// Tema seçimi, uygulama ayarları ve debug özelliklerini içerir
class _AdvancedSettingsSheet extends ConsumerWidget {
  final ThemeMode currentTheme;
  final Function(ThemeMode) onThemeChanged;
  final VoidCallback? onResetOnboarding;
  final Function(Widget) onNavigateToPage;

  const _AdvancedSettingsSheet({
    required this.currentTheme,
    required this.onThemeChanged,
    this.onResetOnboarding,
    required this.onNavigateToPage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final notificationPrefsState = ref.watch(notification_prefs.notificationPreferencesProvider);
    final userPrefsState = ref.watch(userPreferencesProvider);
    // Dil değişikliği olduğunda bu sayfanın güncellenmesi için locale'i dinle
    ref.watch(languageNotifierProvider);

    return SafeArea(
      top: true,
      bottom: false,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
        children: [
          // Başlık ve geri dönme butonu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Geri',
                ),
                const SizedBox(width: 8),
                Text(
                  'Gelişmiş Ayarlar',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // İçerik
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Tema ayarları
                  _buildSettingsSection(
                    context,
                    title: 'Görünüm',
                    icon: Icons.palette,
                    children: [
                      _buildThemeOption(
                        context,
                        title: 'Açık Tema',
                        subtitle: 'Parlak renk teması kullan',
                        icon: Icons.light_mode,
                        isSelected: currentTheme == ThemeMode.light,
                        onTap: () => onThemeChanged(ThemeMode.light),
                      ),
                      _buildThemeOption(
                        context,
                        title: 'Koyu Tema',
                        subtitle: 'Karanlık renk teması kullan',
                        icon: Icons.dark_mode,
                        isSelected: currentTheme == ThemeMode.dark,
                        onTap: () => onThemeChanged(ThemeMode.dark),
                      ),
                      _buildThemeOption(
                        context,
                        title: 'Sistem Teması',
                        subtitle: 'Cihaz ayarını takip et',
                        icon: Icons.phone_iphone,
                        isSelected: currentTheme == ThemeMode.system,
                        onTap: () => onThemeChanged(ThemeMode.system),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Uygulama ayarları
                  _buildSettingsSection(
                    context,
                    title: 'Uygulama',
                    icon: Icons.apps,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.notifications),
                        title: const Text('Bildirimler'),
                        subtitle: const Text('Push bildirimleri ve uyarıları'),
                        trailing: Switch(
                          value: notificationPrefsState.pushNotifications,
                          onChanged: (value) async {
                            final handler = PushNotificationHandler();
                            if (value) {
                              final enabled = await handler.areNotificationsEnabled();
                              if (!enabled) {
                                await handler.requestNotificationPermissions();
                              }
                            } else {
                              await handler.cancelAllNotifications();
                            }
                            if (context.mounted) {
                              ref.read(notification_prefs.notificationPreferencesProvider.notifier).togglePushNotifications();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(value ? 'Bildirimler açıldı' : 'Bildirimler kapatıldı'),
                                  backgroundColor: value ? Colors.green : Colors.orange,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.language),
                        title: const Text('Dil'),
                        subtitle: Text(ref.read(languageNotifierProvider.notifier).currentLanguageDisplayName),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          final currentLanguage = ref.read(languageNotifierProvider.notifier).currentLanguage;
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Dil Seçin'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: AppLanguage.values.map((language) {
                                  final isSelected = language == currentLanguage;
                                  return ListTile(
                                    title: Text(language.displayName),
                                    trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
                                    onTap: () async {
                                      await ref.read(languageNotifierProvider.notifier).setLanguage(language);
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Dil ${language.displayName} olarak değiştirildi'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('İptal'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip),
                        title: Text(AppLocalizations.of(context)!.privacy),
                        subtitle: Text(AppLocalizations.of(context)!.privacyDataUsage),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.of(context).pop();
                          onNavigateToPage(const PrivacySettingsScreen());
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Kullanıcı tercihleri
                  _buildSettingsSection(
                    context,
                    title: 'Kullanıcı Tercihleri',
                    icon: Icons.person_outline,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.visibility),
                        title: const Text('Profil Görünürlüğü'),
                        subtitle: const Text('Profilinizi diğer kullanıcılar görebilir'),
                        trailing: Switch(
                          value: userPrefsState.profileVisibility,
                          onChanged: (value) {
                            ref.read(userPreferencesProvider.notifier).toggleProfileVisibility();
                          },
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.online_prediction),
                        title: const Text('Çevrimiçi Durumu'),
                        subtitle: const Text('Çevrimiçi olduğunuzda gösterilsin'),
                        trailing: Switch(
                          value: userPrefsState.showOnlineStatus,
                          onChanged: (value) {
                            ref.read(userPreferencesProvider.notifier).toggleOnlineStatus();
                          },
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.message),
                        title: const Text('Direkt Mesajlar'),
                        subtitle: const Text('Diğer kullanıcılar size mesaj gönderebilir'),
                        trailing: Switch(
                          value: userPrefsState.allowDirectMessages,
                          onChanged: (value) {
                            ref.read(userPreferencesProvider.notifier).toggleDirectMessages();
                          },
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.play_circle),
                        title: const Text('Otomatik Video Oynatma'),
                        subtitle: const Text('Videolar otomatik olarak oynatılsın'),
                        trailing: Switch(
                          value: userPrefsState.autoPlayVideos,
                          onChanged: (value) {
                            ref.read(userPreferencesProvider.notifier).toggleAutoPlayVideos();
                          },
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.data_usage),
                        title: const Text('Veri Tasarrufu'),
                        subtitle: const Text('Düşük kaliteli görseller kullan'),
                        trailing: Switch(
                          value: userPrefsState.dataUsageOptimization,
                          onChanged: (value) {
                            ref.read(userPreferencesProvider.notifier).toggleDataOptimization();
                          },
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.currency_lira),
                        title: const Text('Varsayılan Para Birimi'),
                        subtitle: Text(userPrefsState.defaultCurrency),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          _showCurrencySelector(context, ref);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Admin Panel (sadece admin kullanıcılar için)
                  Consumer(
                    builder: (context, ref, child) {
                      final isAdmin = ref.watch(isAdminProvider);
                      final isAdminLoading = ref.watch(isAdminLoadingProvider);
                      
                      if (isAdminLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      if (!isAdmin) {
                        return const SizedBox.shrink(); // Admin değilse gizle
                      }
                      
                      return Column(
                        children: [
                          _buildSettingsSection(
                            context,
                            title: '🔧 Admin Panel',
                            icon: Icons.admin_panel_settings,
                            children: [
                              ListTile(
                                leading: const Icon(
                                  Icons.notifications_active,
                                  color: Colors.orange,
                                ),
                                title: const Text('Bildirim Yönetimi'),
                                subtitle: const Text('Kullanıcılara bildirim gönder'),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AdminNotificationsScreen(),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.analytics,
                                  color: Colors.blue,
                                ),
                                title: const Text('Sistem İstatistikleri'),
                                subtitle: const Text('Kullanıcı ve sistem metrikleri'),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('İstatistikler yakında eklenecek'),
                                      backgroundColor: Colors.blue,
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.people,
                                  color: Colors.green,
                                ),
                                title: const Text('Kullanıcı Yönetimi'),
                                subtitle: const Text('Raporlar, banlar ve moderasyon'),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AdminUserManagementScreen(),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.settings_applications,
                                  color: Colors.purple,
                                ),
                                title: const Text('Sistem Ayarları'),
                                subtitle: const Text('Uygulama konfigürasyonu'),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Sistem ayarları yakında eklenecek'),
                                      backgroundColor: Colors.purple,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),

                  // Debug ayarları (sadece development modunda)
                  if (onResetOnboarding != null) ...[
                    _buildSettingsSection(
                      context,
                      title: 'Geliştirici',
                      icon: Icons.developer_mode,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.refresh),
                          title: const Text('Tanıtımı Sıfırla'),
                          subtitle: const Text('Onboarding ekranlarını yeniden göster'),
                          onTap: () {
                            Navigator.of(context).pop();
                            onResetOnboarding!();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Uygulama bilgileri
                  _buildSettingsSection(
                    context,
                    title: 'Hakkında',
                    icon: Icons.info,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: Text(AppLocalizations.of(context)!.version),
                        subtitle: const Text('1.0.0+1'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.feedback),
                        title: Text(AppLocalizations.of(context)!.feedback),
                        subtitle: Text(AppLocalizations.of(context)!.shareYourSuggestions),
                        onTap: () {
                          Navigator.of(context).pop();
                          final subject = Uri.encodeComponent(AppLocalizations.of(context)!.feedbackEmailSubject);
                          final uri = Uri.parse('mailto:info@biletsokagi.com?subject=$subject');
                          launchUrl(uri);
                        },
                      ),
                    ],
                  ),

                  // Alt boşluk
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  /// Ayarlar bölümü için yardımcı widget
  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }

  /// Tema seçim seçeneği için yardımcı widget
  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }

  /// Para birimi seçici dialog
  void _showCurrencySelector(BuildContext context, WidgetRef ref) {
    final currencies = ['TRY', 'USD', 'EUR', 'GBP'];
    final currentCurrency = ref.read(userPreferencesProvider).defaultCurrency;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Para Birimi Seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies.map((currency) {
            final isSelected = currency == currentCurrency;
            return ListTile(
              title: Text(currency),
              trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
              onTap: () async {
                await ref.read(userPreferencesProvider.notifier).setDefaultCurrency(currency);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Para birimi $currency olarak değiştirildi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

}
