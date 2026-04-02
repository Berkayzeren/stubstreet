// lib/features/conversations/presentation/widgets/conversation_list.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/firebase_chat_providers.dart' as fb_providers;
import '../screens/firebase_chat_screen.dart';
import '../../domain/entities/conversation.dart';
import 'conversation_list_item.dart';

class ConversationList extends ConsumerStatefulWidget {
  final String currentUserId;
  final Function(String conversationId)? onConversationTap;

  const ConversationList({
    super.key,
    required this.currentUserId,
    this.onConversationTap,
  });

  @override
  ConsumerState<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends ConsumerState<ConversationList>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _setupScrollPagination();
  }

  void _setupScrollPagination() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // Load more conversations when near bottom
        _loadMoreConversations();
      }
    });
  }

  void _loadMoreConversations() {
    // TODO: Implement pagination logic
    // This would typically involve updating the provider to fetch more data
    debugPrint('Loading more conversations...');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onConversationTap(Conversation conversation) {
    if (widget.onConversationTap != null) {
      widget.onConversationTap!(conversation.id);
    } else {
      // Default navigation
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FirebaseChatScreen(
            conversationId: conversation.id,
            otherUserId: conversation.getOtherParticipantId(
              widget.currentUserId,
            ),
            otherUserName: conversation.getOtherParticipantName(
              widget.currentUserId,
            ),
            otherUserAvatarUrl: conversation.getOtherParticipantAvatarUrl(
              widget.currentUserId,
            ),
          ),
        ),
      );
    }
  }

  List<Conversation> _filterConversations(List<Conversation> conversations) {
    if (_searchQuery.isEmpty) return conversations;

    return conversations.where((conversation) {
      final otherUserName = conversation
          .getOtherParticipantName(widget.currentUserId)
          .toLowerCase();
      final lastMessage = conversation.lastMessage?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      return otherUserName.contains(query) || lastMessage.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final conversationsAsync = ref.watch(
      fb_providers.userConversationsProvider,
    );

    return Scaffold(
      body: Column(
        children: [
          // Inline search bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Sohbetlerde ara...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade800
                      : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                },
              ),
            ),
          ),
          // Conversations list
          Expanded(
            child: conversationsAsync.when(
              data: (conversations) {
                final filteredConversations = _filterConversations(
                  conversations,
                );

                if (filteredConversations.isEmpty) {
                  return _buildEmptyState(l10n);
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filteredConversations.length,
                  itemBuilder: (context, index) {
                    final conversation = filteredConversations[index];
                    return ConversationListItem(
                      conversation: conversation,
                      currentUserId: widget.currentUserId,
                      onTap: () => _onConversationTap(conversation),
                      onLongPress: () => _showConversationOptions(conversation),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(l10n, error),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement start new conversation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.featureComingSoon),
              backgroundColor: Colors.orange,
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add_comment, color: Colors.white),
      ),
    );
  }

  // Removed unused _buildRegularAppBar and _buildSearchAppBar methods
  // These methods were not being called anywhere in the codebase

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty
                ? l10n.noSearchResults
                : l10n.noConversations,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? l10n.tryDifferentSearch
                : l10n.startNewConversation,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to new conversation screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.featureComingSoon),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.startConversation),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(
            l10n.errorLoadingConversations,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(fb_providers.userConversationsProvider);
            },
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showConversationOptions(Conversation conversation) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ConversationOptionsSheet(
        conversation: conversation,
        currentUserId: widget.currentUserId,
      ),
    );
  }
}

class _ConversationOptionsSheet extends StatelessWidget {
  final Conversation conversation;
  final String currentUserId;

  const _ConversationOptionsSheet({
    required this.conversation,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            conversation.getOtherParticipantName(currentUserId),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          _buildOptionTile(
            icon: Icons.volume_off,
            title: l10n.muteNotifications,
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement mute functionality
            },
          ),
          _buildOptionTile(
            icon: Icons.archive,
            title: l10n.archiveConversation,
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement archive functionality
            },
          ),
          _buildOptionTile(
            icon: Icons.block,
            title: l10n.blockUser,
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement block functionality
            },
            isDestructive: true,
          ),
          _buildOptionTile(
            icon: Icons.delete,
            title: l10n.deleteConversation,
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context);
            },
            isDestructive: true,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : null),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : null),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteConversation),
        content: Text(l10n.deleteConversationConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete functionality
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
