// lib/features/tickets/presentation/screens/ticket_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ticket_providers.dart';
import 'ticket_detail_screen.dart';
import '../widgets/ticket_card.dart';
import '../../../../core/mixins/scroll_to_top_mixin.dart';

class TicketListScreen extends ConsumerStatefulWidget {
  const TicketListScreen({super.key});

  @override
  ConsumerState<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends ConsumerState<TicketListScreen> with ScrollToTopMixin {
  @override
  Widget build(BuildContext context) {
    final ticketsAsyncValue = ref.watch(ticketsProvider);
    final searchResults = ref.watch(searchResultsProvider);
    final controller = TextEditingController();

    return Scaffold(
      appBar: null,
      body: Column(
        children: [
          // Gövde-içi arama çubuğu
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Bilet ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (q) {
                if (q.trim().isNotEmpty) {
                  ref.read(searchResultsProvider.notifier).search(q);
                } else {
                  ref.read(searchResultsProvider.notifier).clearResults();
                }
              },
              onChanged: (q) {
                if (q.isEmpty) {
                  ref.read(searchResultsProvider.notifier).clearResults();
                }
              },
            ),
          ),
          // İsteğe bağlı filtre çipleri (dummy)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: const [
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Chip(label: Text('Konser')),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Chip(label: Text('Spor')),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Chip(label: Text('Tiyatro')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Liste içeriği
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Tüm bilet verilerini yenile
                ref.invalidate(ticketsProvider);
                ref.invalidate(searchResultsProvider);
              },
              child: Builder(
                builder: (_) {
                  final hasQuery = controller.text.trim().isNotEmpty;
                  if (hasQuery) {
                    return searchResults.isEmpty
                        ? const Center(child: Text('Sonuç bulunamadı'))
                        : ListView.builder(
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              final ticket = searchResults[index];
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
                  return ticketsAsyncValue.when(
                    data: (tickets) {
                      if (tickets.isEmpty) {
                        return const Center(child: Text('Henüz satışta bilet yok.'));
                      }
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: tickets.length,
                        itemBuilder: (context, index) {
                          final ticket = tickets[index];
                          return TicketCard(
                            ticket: ticket,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TicketDetailScreen(ticketId: ticket.id),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(child: Text('Hata: $error')),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
