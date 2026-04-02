// lib/features/conversations/presentation/widgets/chat_search_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/message.dart';

/// Widget for searching messages within a chat conversation
/// Provides text search, date filtering, and sender filtering
class ChatSearchWidget extends ConsumerStatefulWidget {
  final String conversationId;
  final Function(Message message)? onMessageSelect;
  final VoidCallback? onClose;

  const ChatSearchWidget({
    super.key,
    required this.conversationId,
    this.onMessageSelect,
    this.onClose,
  });

  @override
  ConsumerState<ChatSearchWidget> createState() => _ChatSearchWidgetState();
}

class _ChatSearchWidgetState extends ConsumerState<ChatSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  String _searchQuery = '';
  List<Message> _searchResults = [];
  bool _isSearching = false;
  int _currentResultIndex = -1;
  
  // Filter options
  bool _showDateFilter = false;
  DateTimeRange? _dateRange;
  String? _selectedSender;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Mesaj Ara',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Search input
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Mesajlarda ara...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: _onSearchChanged,
                    onSubmitted: _performSearch,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _toggleFilters,
                  icon: Icon(
                    Icons.tune,
                    color: _showDateFilter || _dateRange != null || _selectedSender != null
                        ? Theme.of(context).primaryColor
                        : null,
                  ),
                ),
              ],
            ),
          ),

          // Filters panel
          if (_showDateFilter) _buildFiltersPanel(),

          // Search results count and navigation
          if (_searchResults.isNotEmpty) _buildResultsNavigation(),

          // Search results list
          Flexible(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtreler',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Date filter
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _dateRange != null
                        ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                        : 'Tarih Aralığı',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _dateRange != null
                        ? Theme.of(context).primaryColor
                        : null,
                  ),
                ),
              ),
              if (_dateRange != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => setState(() => _dateRange = null),
                  icon: const Icon(Icons.clear),
                  tooltip: 'Tarih filtresini temizle',
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Clear all filters
          if (_dateRange != null || _selectedSender != null)
            TextButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Tüm Filtreleri Temizle'),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Text(
            '${_searchResults.length} sonuç bulundu',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          if (_searchResults.length > 1) ...[
            IconButton(
              onPressed: _currentResultIndex > 0 ? _navigateToPrevious : null,
              icon: const Icon(Icons.keyboard_arrow_up),
              tooltip: 'Önceki',
            ),
            Text('${_currentResultIndex + 1}/${_searchResults.length}'),
            IconButton(
              onPressed: _currentResultIndex < _searchResults.length - 1
                  ? _navigateToNext
                  : null,
              icon: const Icon(Icons.keyboard_arrow_down),
              tooltip: 'Sonraki',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_searchQuery.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.search,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Mesaj aramak için yazın',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Sonuç bulunamadı',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final message = _searchResults[index];
        final isSelected = index == _currentResultIndex;

        return Container(
          color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: Text(
                message.senderId[0].toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            title: _buildHighlightedText(message.content, _searchQuery),
            subtitle: Text(
              _formatDateTime(message.createdAt),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: isSelected
                ? Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  )
                : null,
            onTap: () => _selectMessage(index),
          ),
        );
      },
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) return Text(text);

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matches = <TextSpan>[];
    int lastMatchEnd = 0;

    while (lastMatchEnd < text.length) {
      final index = lowerText.indexOf(lowerQuery, lastMatchEnd);
      if (index == -1) {
        if (lastMatchEnd < text.length) {
          matches.add(TextSpan(text: text.substring(lastMatchEnd)));
        }
        break;
      }

      if (index > lastMatchEnd) {
        if (lastMatchEnd < index) {
          matches.add(TextSpan(text: text.substring(lastMatchEnd, index)));
        }
      }

      matches.add(TextSpan(
        text: text.substring(index, (index + query.length).clamp(0, text.length)),
        style: TextStyle(
          backgroundColor: Colors.yellow.shade200,
          fontWeight: FontWeight.bold,
        ),
      ));

      lastMatchEnd = index + query.length;
    }

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: matches,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });

    if (value.isNotEmpty) {
      _performSearch(value);
    } else {
      setState(() {
        _searchResults.clear();
        _currentResultIndex = -1;
      });
    }
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    // Simulate search delay
    await Future.delayed(const Duration(milliseconds: 300));

    // In a real implementation, this would search through the conversation messages
    // For now, we'll simulate some results
    final results = _simulateSearch(query);

    setState(() {
      _searchResults = results;
      _currentResultIndex = results.isNotEmpty ? 0 : -1;
      _isSearching = false;
    });
  }

  List<Message> _simulateSearch(String query) {
    // Simulate search results
    final now = DateTime.now();
    return [
      Message(
        id: 'search_result_1',
        senderId: 'user_1',
        receiverId: 'current_user',
        conversationId: widget.conversationId,
        content: 'Bu bir örnek mesaj: $query bulundu',
        createdAt: now.subtract(const Duration(days: 1)),
        senderName: 'User 1',
        receiverName: 'Current User',
        type: MessageType.text,
        status: MessageStatus.sent,
        attachments: const [],
      ),
      Message(
        id: 'search_result_2',
        senderId: 'user_2',
        receiverId: 'current_user',
        conversationId: widget.conversationId,
        content: 'Başka bir mesajda da $query var',
        createdAt: now.subtract(const Duration(days: 2)),
        senderName: 'User 2',
        receiverName: 'Current User',
        type: MessageType.text,
        status: MessageStatus.sent,
        attachments: const [],
      ),
    ].where((message) {
      final matchesQuery = message.content.toLowerCase().contains(query.toLowerCase());
      final matchesDate = _dateRange == null ||
          (message.createdAt.isAfter(_dateRange!.start) &&
              message.createdAt.isBefore(_dateRange!.end.add(const Duration(days: 1))));
      final matchesSender = _selectedSender == null || message.senderId == _selectedSender;

      return matchesQuery && matchesDate && matchesSender;
    }).toList();
  }

  void _selectMessage(int index) {
    setState(() {
      _currentResultIndex = index;
    });

    if (index >= 0 && index < _searchResults.length) {
      widget.onMessageSelect?.call(_searchResults[index]);
    }
  }

  void _navigateToPrevious() {
    if (_currentResultIndex > 0) {
      _selectMessage(_currentResultIndex - 1);
    }
  }

  void _navigateToNext() {
    if (_currentResultIndex < _searchResults.length - 1) {
      _selectMessage(_currentResultIndex + 1);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _searchResults.clear();
      _currentResultIndex = -1;
    });
  }

  void _toggleFilters() {
    setState(() {
      _showDateFilter = !_showDateFilter;
    });
  }

  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      if (_searchQuery.isNotEmpty) {
        _performSearch(_searchQuery);
      }
    }
  }

  void _clearAllFilters() {
    setState(() {
      _dateRange = null;
      _selectedSender = null;
    });
    if (_searchQuery.isNotEmpty) {
      _performSearch(_searchQuery);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
